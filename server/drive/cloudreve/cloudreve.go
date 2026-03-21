package cloudreve

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/traftai/lumina/server/localstore"
	"github.com/traftai/lumina/server/resolver"
)

var errObjectExisted = errors.New("object already exists")

// Cloudreve implements StorageDrive and SmartBackend for Cloudreve v4.
type Cloudreve struct {
	server        string
	email         string
	password      string
	rootPath      string
	accessToken   string
	refreshToken  string
	accessExp     time.Time
	refreshExp    time.Time
	mu            sync.Mutex
	client        *http.Client
	logger        *log.Logger
	onTokenUpdate func(refreshToken string, refreshExp time.Time)
	authErr       error     // cached auth error to avoid repeated 2FA login attempts
	authErrTime   time.Time // when authErr was set; cleared after 5 minutes
}

var sharedLogger *log.Logger

func SetLogDir(dir string) {
	logPath := filepath.Join(dir, "lumina_go_debug.log")
	f, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err == nil {
		sharedLogger = log.New(f, "[Cloudreve] ", log.LstdFlags)
	}
}

func newLogger() *log.Logger {
	if sharedLogger != nil {
		return sharedLogger
	}
	return log.New(os.Stdout, "[Cloudreve] ", log.LstdFlags)
}

func NewCloudreveDrive(server, email, password string) *Cloudreve {
	server = strings.TrimRight(server, "/")
	if !strings.HasPrefix(server, "http://") && !strings.HasPrefix(server, "https://") {
		server = "https://" + server
	}
	return &Cloudreve{
		server:   server,
		email:    email,
		password: password,
		client: &http.Client{
			Timeout: 30 * time.Second,
			Transport: &http.Transport{
				TLSClientConfig:     &tls.Config{InsecureSkipVerify: true},
				MaxIdleConns:        10,
				MaxIdleConnsPerHost: 4,
				IdleConnTimeout:     30 * time.Second,
				DialContext: resolver.NewDoHDialContext(&net.Dialer{
					Timeout:   15 * time.Second,
					KeepAlive: 30 * time.Second,
				}),
				TLSHandshakeTimeout:   10 * time.Second,
				ResponseHeaderTimeout: 5 * time.Minute,
			},
		},
		logger: newLogger(),
	}
}

// --- API response types ---

type apiResponse struct {
	Code int             `json:"code"`
	Msg  string          `json:"msg"`
	Data json.RawMessage `json:"data"`
}

type loginTokenData struct {
	AccessToken    string `json:"access_token"`
	RefreshToken   string `json:"refresh_token"`
	AccessExpires  string `json:"access_expires"`
	RefreshExpires string `json:"refresh_expires"`
}

type loginResponse struct {
	User  json.RawMessage `json:"user"`
	Token loginTokenData  `json:"token"`
}

// ErrRequire2FA is returned when the server requires a 2FA code.
type ErrRequire2FA struct {
	SessionID string
}

func (e *ErrRequire2FA) Error() string {
	return "2FA required"
}

type fileObject struct {
	Name      string            `json:"name"`
	Path      string            `json:"path"`
	Size      int64             `json:"size"`
	Type      int               `json:"type"` // 0=file, 1=folder
	UpdatedAt time.Time         `json:"updated_at"`
	CreatedAt time.Time         `json:"created_at"`
	Metadata  map[string]string `json:"metadata"`
}

type fileListData struct {
	Files      []fileObject `json:"files"`
	Pagination *pagination  `json:"pagination"`
}

type pagination struct {
	Page     int `json:"page"`
	PageSize int `json:"page_size"`
	Total    int `json:"total"`
}

type uploadSessionResponse struct {
	SessionID      string              `json:"session_id"`
	ChunkSize      int64               `json:"chunk_size"`
	UploadURLs     []string            `json:"upload_urls"`
	CallbackSecret string              `json:"callback_secret"`
	StoragePolicy  *uploadPolicyInfo   `json:"storage_policy"`
}

type uploadPolicyInfo struct {
	Type string `json:"type"`
}

type fileURLResponse struct {
	Urls []struct {
		URL string `json:"url"`
	} `json:"urls"`
}

type lockConflictError struct {
	msg     string
	rawData json.RawMessage
}

func (e *lockConflictError) Error() string {
	return "Lock conflict: " + e.msg
}

func (e *lockConflictError) tokens() []string {
	var details []struct {
		Token string `json:"token"`
	}
	if err := json.Unmarshal(e.rawData, &details); err != nil {
		return nil
	}
	var tokens []string
	for _, d := range details {
		if d.Token != "" {
			tokens = append(tokens, d.Token)
		}
	}
	return tokens
}

// --- Auth ---

func (c *Cloudreve) Login() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.login()
}

func (c *Cloudreve) login() error {
	body, _ := json.Marshal(map[string]string{
		"email":    c.email,
		"password": c.password,
	})
	req, err := http.NewRequest("POST", c.server+"/api/v4/session/token", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("login request failed: %w", err)
	}
	defer resp.Body.Close()

	var apiResp apiResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return fmt.Errorf("login decode failed: %w", err)
	}
	if apiResp.Code == 203 {
		var sessionID string
		if err := json.Unmarshal(apiResp.Data, &sessionID); err != nil {
			return fmt.Errorf("login 2FA session decode failed: %w", err)
		}
		return &ErrRequire2FA{SessionID: sessionID}
	}
	if apiResp.Code != 0 {
		return fmt.Errorf("login failed: %s", apiResp.Msg)
	}

	var loginData loginResponse
	if err := json.Unmarshal(apiResp.Data, &loginData); err != nil {
		return fmt.Errorf("login data decode failed: %w", err)
	}

	return c.applyTokens(&loginData)
}

func (c *Cloudreve) applyTokens(loginData *loginResponse) error {
	c.authErr = nil
	c.accessToken = loginData.Token.AccessToken
	c.refreshToken = loginData.Token.RefreshToken

	c.logger.Printf("applyTokens: accessToken=%q (len=%d), accessExpires=%q, refreshExpires=%q",
		c.accessToken[:min(10, len(c.accessToken))], len(c.accessToken),
		loginData.Token.AccessExpires, loginData.Token.RefreshExpires)

	if loginData.Token.AccessExpires != "" {
		if t, err := time.Parse(time.RFC3339, loginData.Token.AccessExpires); err == nil {
			// Guard against server clock skew / wrong timezone: if the parsed
			// expiry is already in the past, the timestamp is unreliable.
			// Fall back to a 2-hour window from local time.
			if t.Before(time.Now()) {
				c.logger.Printf("applyTokens: accessExpires %v is in the past (now=%v), using 2h fallback", t, time.Now())
				c.accessExp = time.Now().Add(2 * time.Hour)
			} else {
				c.accessExp = t
			}
		} else {
			c.logger.Printf("applyTokens: failed to parse accessExpires %q: %v", loginData.Token.AccessExpires, err)
			c.accessExp = time.Now().Add(2 * time.Hour)
		}
	} else {
		c.accessExp = time.Now().Add(2 * time.Hour)
	}

	if loginData.Token.RefreshExpires != "" {
		if t, err := time.Parse(time.RFC3339, loginData.Token.RefreshExpires); err == nil {
			if t.Before(time.Now()) {
				c.logger.Printf("applyTokens: refreshExpires %v is in the past (now=%v), using 7d fallback", t, time.Now())
				c.refreshExp = time.Now().Add(7 * 24 * time.Hour)
			} else {
				c.refreshExp = t
			}
		} else {
			c.refreshExp = time.Now().Add(7 * 24 * time.Hour)
		}
	} else {
		c.refreshExp = time.Now().Add(7 * 24 * time.Hour)
	}

	if c.onTokenUpdate != nil {
		c.onTokenUpdate(c.refreshToken, c.refreshExp)
	}
	return nil
}

func (c *Cloudreve) SetOnTokenUpdate(fn func(refreshToken string, refreshExp time.Time)) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.onTokenUpdate = fn
}

func (c *Cloudreve) SetTokens(refreshToken string, refreshExp time.Time) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.refreshToken = refreshToken
	c.refreshExp = refreshExp
}

// RefreshAuth attempts to refresh authentication using the stored refresh token.
// Returns an error if no valid refresh token is available or if refresh fails.
func (c *Cloudreve) RefreshAuth() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.refreshToken == "" || time.Now().After(c.refreshExp) {
		return fmt.Errorf("no valid refresh token")
	}
	return c.refreshOnly()
}

// Login2FA completes the second step of 2FA login.
func (c *Cloudreve) Login2FA(sessionID, otp string) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	body, _ := json.Marshal(map[string]string{
		"session_id": sessionID,
		"otp":        otp,
	})
	req, err := http.NewRequest("POST", c.server+"/api/v4/session/token/2fa", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("2FA request failed: %w", err)
	}
	defer resp.Body.Close()

	var apiResp apiResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return fmt.Errorf("2FA decode failed: %w", err)
	}
	if apiResp.Code == 40022 {
		return fmt.Errorf("2FA code error")
	}
	if apiResp.Code == 40023 {
		return fmt.Errorf("login session expired")
	}
	if apiResp.Code != 0 {
		return fmt.Errorf("2FA failed: %s", apiResp.Msg)
	}

	var loginData loginResponse
	if err := json.Unmarshal(apiResp.Data, &loginData); err != nil {
		return fmt.Errorf("2FA data decode failed: %w", err)
	}

	return c.applyTokens(&loginData)
}

func (c *Cloudreve) refreshOnly() error {
	body, _ := json.Marshal(map[string]string{
		"refresh_token": c.refreshToken,
	})
	req, err := http.NewRequest("POST", c.server+"/api/v4/session/token/refresh", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("refresh request failed: %w", err)
	}
	defer resp.Body.Close()

	var apiResp apiResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return fmt.Errorf("refresh decode failed: %w", err)
	}
	if apiResp.Code != 0 {
		return fmt.Errorf("refresh failed: %s", apiResp.Msg)
	}

	c.logger.Printf("refreshOnly: raw data=%s", string(apiResp.Data))

	// Refresh response returns tokens flat (data.access_token), not nested
	// like login response (data.token.access_token).
	var tokenData loginTokenData
	if err := json.Unmarshal(apiResp.Data, &tokenData); err != nil {
		return fmt.Errorf("refresh data decode failed: %w", err)
	}
	if tokenData.AccessToken == "" {
		return fmt.Errorf("refresh returned empty access token")
	}

	return c.applyTokens(&loginResponse{Token: tokenData})
}

func (c *Cloudreve) refresh() error {
	if err := c.refreshOnly(); err != nil {
		loginErr := c.login()
		// If login requires 2FA, don't propagate it as a normal auth failure
		// during background operations — return a clearer error instead.
		var err2fa *ErrRequire2FA
		if errors.As(loginErr, &err2fa) {
			return fmt.Errorf("session expired, please re-authenticate in settings")
		}
		return loginErr
	}
	return nil
}

func (c *Cloudreve) ensureAuth() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.authErr != nil {
		if time.Since(c.authErrTime) > 5*time.Minute {
			c.logger.Printf("ensureAuth: clearing stale authErr after 5 minutes: %v", c.authErr)
			c.authErr = nil
		} else {
			return c.authErr
		}
	}
	if c.accessToken == "" {
		c.logger.Printf("ensureAuth: no access token, trying refresh then login")
		if err := c.reauth(); err != nil {
			c.authErr = err
			c.authErrTime = time.Now()
			return err
		}
		return nil
	}
	if time.Now().Add(5 * time.Minute).After(c.accessExp) {
		c.logger.Printf("ensureAuth: token expiring (exp=%v, now=%v), refreshExp=%v",
			c.accessExp, time.Now(), c.refreshExp)
		if err := c.reauth(); err != nil {
			c.authErr = err
			c.authErrTime = time.Now()
			return err
		}
		return nil
	}
	return nil
}

// reauth tries refresh first, then login. If login requires 2FA,
// it returns a user-friendly error instead of the raw ErrRequire2FA.
func (c *Cloudreve) reauth() error {
	// Try refresh if we have a valid refresh token
	if c.refreshToken != "" && time.Now().Before(c.refreshExp) {
		savedRefresh := c.refreshToken
		savedRefreshExp := c.refreshExp
		if err := c.refreshOnly(); err == nil {
			return nil
		} else {
			c.logger.Printf("reauth: refresh failed: %v, restoring saved refresh token", err)
			// Restore refresh token in case refreshOnly() wiped it
			if c.refreshToken == "" {
				c.refreshToken = savedRefresh
				c.refreshExp = savedRefreshExp
			}
		}
	}
	// Fall back to login
	err := c.login()
	if err != nil {
		var err2fa *ErrRequire2FA
		if errors.As(err, &err2fa) {
			return fmt.Errorf("session expired, please re-authenticate in settings")
		}
	}
	return err
}

func (c *Cloudreve) authRequest(method, urlStr string, body io.Reader) (*http.Request, error) {
	if err := c.ensureAuth(); err != nil {
		return nil, fmt.Errorf("auth failed: %w", err)
	}
	req, err := http.NewRequest(method, urlStr, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+c.accessToken)
	req.Header.Set("Content-Type", "application/json")
	return req, nil
}

// --- URI helpers ---

func (c *Cloudreve) uri(p string) string {
	return "cloudreve://my" + path.Join("/", c.rootPath, p)
}

func (c *Cloudreve) SetRootPath(rootPath string) error {
	if rootPath == "" {
		return fmt.Errorf("root path is empty")
	}
	rootPath = filepath.ToSlash(rootPath)
	if !strings.HasPrefix(rootPath, "/") {
		rootPath = "/" + rootPath
	}
	rootPath = strings.TrimRight(rootPath, "/")
	c.rootPath = rootPath
	return nil
}

// --- API helpers ---

func (c *Cloudreve) doJSON(method, urlStr string, reqBody interface{}, result interface{}) error {
	var bodyReader io.Reader
	if reqBody != nil {
		data, err := json.Marshal(reqBody)
		if err != nil {
			return err
		}
		bodyReader = bytes.NewReader(data)
	}

	req, err := c.authRequest(method, urlStr, bodyReader)
	if err != nil {
		return err
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var apiResp apiResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return fmt.Errorf("decode response failed: %w", err)
	}
	if apiResp.Code != 0 {
		if apiResp.Code == 40004 {
			return errObjectExisted
		}
		if apiResp.Code == 40073 {
			return &lockConflictError{msg: apiResp.Msg, rawData: apiResp.Data}
		}
		return fmt.Errorf("API error (code %d): %s", apiResp.Code, apiResp.Msg)
	}
	if result != nil && len(apiResp.Data) > 0 {
		return json.Unmarshal(apiResp.Data, result)
	}
	return nil
}

func (c *Cloudreve) listFiles(uri string, page, pageSize int, category string) (*fileListData, error) {
	u, _ := url.Parse(c.server + "/api/v4/file")
	q := u.Query()
	q.Set("uri", uri)
	if page > 0 {
		q.Set("page", strconv.Itoa(page))
	}
	if pageSize > 0 {
		q.Set("page_size", strconv.Itoa(pageSize))
	}
	if category != "" {
		q.Set("category", category)
	}
	q.Set("order_by", "updated_at")
	q.Set("order_direction", "desc")
	u.RawQuery = q.Encode()

	var data fileListData
	if err := c.doJSON("GET", u.String(), nil, &data); err != nil {
		return nil, err
	}
	return &data, nil
}

func (c *Cloudreve) createDir(dirURI string) error {
	return c.doJSON("POST", c.server+"/api/v4/file/create", map[string]string{
		"uri":  dirURI,
		"type": "folder",
	}, nil)
}

// forceUnlock calls DELETE /api/v4/file/lock to force-clear stuck upload locks.
func (c *Cloudreve) forceUnlock(tokens []string) error {
	return c.doJSON("DELETE", c.server+"/api/v4/file/lock", map[string]interface{}{
		"tokens": tokens,
	}, nil)
}

func (c *Cloudreve) ensureParentDirs(filePath string) error {
	dir := path.Dir(filePath)
	if dir == "." || dir == "/" {
		return nil
	}
	dirURI := "cloudreve://my" + path.Join("/", c.rootPath, dir)
	// Try listing to check existence; create if needed
	_, err := c.listFiles(dirURI, 1, 1, "")
	if err != nil {
		// Recursively ensure parent
		if err2 := c.ensureParentDirs(dir); err2 != nil {
			return err2
		}
		return c.createDir(dirURI)
	}
	return nil
}

// --- StorageDrive interface ---

func (c *Cloudreve) Upload(filePath string, reader io.ReadCloser, size int64, modTime time.Time) error {
	if reader == nil {
		return fmt.Errorf("reader is nil")
	}
	defer reader.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		return fmt.Errorf("read upload data: %w", err)
	}

	if err := c.ensureParentDirs(filePath); err != nil {
		c.logger.Printf("Warning: ensureParentDirs for %s: %v", filePath, err)
	}

	fileURI := c.uri(filePath)
	modMs := modTime.UnixMilli()
	if modMs <= 0 {
		modMs = time.Now().UnixMilli()
	}

	// Create upload session (matching Cloudreve desktop client fields)
	c.logger.Printf("Upload: creating session for %s (uri=%s, size=%d)", filePath, fileURI, size)
	session, err := c.createUploadSession(fileURI, size, modMs, "")
	if errors.Is(err, errObjectExisted) {
		// File already exists on remote — skip rather than creating a duplicate version.
		// This prevents the sync→index→re-sync loop where FilterNotUploaded keeps
		// reporting the same files because versioned uploads change the file metadata.
		c.logger.Printf("Upload: %s already exists, skipping", filePath)
		return nil
	}
	// Handle lock conflict: extract tokens from error, force-unlock, then retry
	var lockErr *lockConflictError
	if errors.As(err, &lockErr) {
		tokens := lockErr.tokens()
		c.logger.Printf("Upload: lock conflict for %s, unlocking %d tokens", filePath, len(tokens))
		if len(tokens) > 0 {
			if unlockErr := c.forceUnlock(tokens); unlockErr != nil {
				c.logger.Printf("Upload: force unlock failed for %s: %v", filePath, unlockErr)
			} else {
				// Retry after unlock
				session, err = c.createUploadSession(fileURI, size, modMs, "version")
			}
		}
	}
	if err != nil {
		c.logger.Printf("Upload: create session failed for %s: %v", filePath, err)
		return fmt.Errorf("create upload session: %w", err)
	}
	c.logger.Printf("Upload: session created for %s: sessionID=%s, chunkSize=%d, uploadURLs=%v", filePath, session.SessionID, session.ChunkSize, session.UploadURLs)

	// Upload chunks according to session.ChunkSize
	chunkSize := session.ChunkSize
	if chunkSize <= 0 {
		chunkSize = int64(len(data))
	}

	totalChunks := (int64(len(data)) + chunkSize - 1) / chunkSize
	if totalChunks == 0 {
		totalChunks = 1
	}

	// If server provides upload_urls, use those (non-local storage policy).
	// Otherwise use the standard Cloudreve chunk upload endpoint (local storage).
	useUploadURLs := len(session.UploadURLs) > 0

	for i := int64(0); i < totalChunks; i++ {
		start := i * chunkSize
		end := start + chunkSize
		if end > int64(len(data)) {
			end = int64(len(data))
		}
		chunk := data[start:end]

		c.logger.Printf("Upload: chunk %d/%d for %s (size=%d, useUploadURLs=%v)", i+1, totalChunks, filePath, len(chunk), useUploadURLs)

		if useUploadURLs && int(i) < len(session.UploadURLs) {
			// Upload directly to the external storage URL provided by server
			if err := c.uploadChunkToURL(session.UploadURLs[i], chunk, start, size); err != nil {
				return fmt.Errorf("upload chunk %d for %s: %w", i, filePath, err)
			}
		} else {
			// Upload to Cloudreve server (local storage policy)
			if err := c.uploadChunk(session.SessionID, i, chunk); err != nil {
				return fmt.Errorf("upload chunk %d for %s: %w", i, filePath, err)
			}
		}
	}

	// For non-local storage (OneDrive, S3, etc.), we must call the Cloudreve callback
	// to finalize the upload. Local storage auto-completes on last chunk.
	if useUploadURLs && session.CallbackSecret != "" {
		policyType := "onedrive" // default
		if session.StoragePolicy != nil && session.StoragePolicy.Type != "" {
			policyType = session.StoragePolicy.Type
		}
		c.logger.Printf("Upload: completing %s callback for %s (sessionID=%s)", policyType, filePath, session.SessionID)
		if err := c.completeUploadCallback(policyType, session.SessionID, session.CallbackSecret); err != nil {
			return fmt.Errorf("complete upload callback: %w", err)
		}
	}

	c.logger.Printf("Upload: success for %s (%d chunks)", filePath, totalChunks)
	return nil
}

func (c *Cloudreve) createUploadSession(fileURI string, size, modMs int64, entityType string) (*uploadSessionResponse, error) {
	reqBody := map[string]interface{}{
		"uri":           fileURI,
		"size":          size,
		"last_modified": modMs,
		"policy_id":     "",
	}
	if entityType != "" {
		reqBody["entity_type"] = entityType
	}
	var session uploadSessionResponse
	err := c.doJSON("PUT", c.server+"/api/v4/file/upload", reqBody, &session)
	if err != nil {
		return nil, err
	}
	return &session, nil
}

func (c *Cloudreve) uploadChunk(sessionID string, index int64, chunk []byte) error {
	if err := c.ensureAuth(); err != nil {
		return fmt.Errorf("auth failed: %w", err)
	}

	// Cloudreve uses POST for chunk uploads: POST /api/v4/file/upload/:sessionId/:index
	uploadURL := fmt.Sprintf("%s/api/v4/file/upload/%s/%d", c.server, sessionID, index)
	req, err := http.NewRequest("POST", uploadURL, bytes.NewReader(chunk))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+c.accessToken)
	req.Header.Set("Content-Type", "application/octet-stream")
	req.ContentLength = int64(len(chunk))

	const maxRetries = 3
	var lastErr error
	for attempt := 0; attempt < maxRetries; attempt++ {
		if attempt > 0 {
			c.logger.Printf("Upload: chunk retry %d/%d (lastErr=%v)", attempt+1, maxRetries, lastErr)
			time.Sleep(time.Duration(attempt*2) * time.Second)
			// Reset body for retry
			req.Body = io.NopCloser(bytes.NewReader(chunk))
		}
		resp, err := c.client.Do(req)
		if err != nil {
			lastErr = fmt.Errorf("request failed: %w", err)
			continue
		}

		respBody, _ := io.ReadAll(resp.Body)
		resp.Body.Close()
		c.logger.Printf("Upload: chunk response HTTP %d, body=%s", resp.StatusCode, string(respBody))

		if resp.StatusCode >= 400 {
			lastErr = fmt.Errorf("HTTP %d: %s", resp.StatusCode, string(respBody))
			continue
		}

		// Try to parse as JSON API response
		var apiResp apiResponse
		if json.Unmarshal(respBody, &apiResp) == nil && apiResp.Code != 0 {
			return fmt.Errorf("API error (code %d): %s", apiResp.Code, apiResp.Msg)
		}
		return nil
	}
	return lastErr
}

// uploadChunkToURL uploads a chunk directly to an external storage URL (OneDrive, S3, etc.)
// totalSize is the full file size, chunkStart is the byte offset of this chunk.
func (c *Cloudreve) uploadChunkToURL(uploadURL string, chunk []byte, chunkStart, totalSize int64) error {
	req, err := http.NewRequest("PUT", uploadURL, bytes.NewReader(chunk))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/octet-stream")
	req.ContentLength = int64(len(chunk))
	// OneDrive requires Content-Range header for upload sessions
	chunkEnd := chunkStart + int64(len(chunk)) - 1
	req.Header.Set("Content-Range", fmt.Sprintf("bytes %d-%d/%d", chunkStart, chunkEnd, totalSize))

	const maxRetries = 3
	var lastErr error
	for attempt := 0; attempt < maxRetries; attempt++ {
		if attempt > 0 {
			c.logger.Printf("Upload: external chunk retry %d/%d (lastErr=%v)", attempt+1, maxRetries, lastErr)
			time.Sleep(time.Duration(attempt*2) * time.Second)
			req.Body = io.NopCloser(bytes.NewReader(chunk))
		}
		resp, err := c.client.Do(req)
		if err != nil {
			lastErr = fmt.Errorf("request failed: %w", err)
			continue
		}
		respBody, _ := io.ReadAll(resp.Body)
		resp.Body.Close()
		c.logger.Printf("Upload: external chunk response HTTP %d, body=%s", resp.StatusCode, string(respBody))

		if resp.StatusCode >= 400 {
			lastErr = fmt.Errorf("HTTP %d: %s", resp.StatusCode, string(respBody))
			continue
		}
		return nil
	}
	return lastErr
}

// completeUploadCallback tells Cloudreve that all chunks have been uploaded to external storage.
// For OneDrive: POST /api/v4/callback/onedrive/{sessionID}/{callbackSecret}
// For S3-like: GET /api/v4/callback/{policyType}/{sessionID}/{callbackSecret}
func (c *Cloudreve) completeUploadCallback(policyType, sessionID, callbackSecret string) error {
	callbackURL := fmt.Sprintf("%s/api/v4/callback/%s/%s/%s", c.server, policyType, sessionID, callbackSecret)

	method := "POST"
	if policyType != "onedrive" && policyType != "remote" && policyType != "oss" && policyType != "qiniu" && policyType != "obs" {
		method = "GET"
	}

	if err := c.ensureAuth(); err != nil {
		return fmt.Errorf("auth failed: %w", err)
	}

	req, err := http.NewRequest(method, callbackURL, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+c.accessToken)

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("callback request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	c.logger.Printf("Upload: callback response HTTP %d, body=%s", resp.StatusCode, string(respBody))

	if resp.StatusCode >= 400 {
		return fmt.Errorf("callback HTTP %d: %s", resp.StatusCode, string(respBody))
	}

	var apiResp apiResponse
	if json.Unmarshal(respBody, &apiResp) == nil && apiResp.Code != 0 {
		return fmt.Errorf("callback API error (code %d): %s", apiResp.Code, apiResp.Msg)
	}

	return nil
}

func (c *Cloudreve) Download(filePath string) (io.ReadCloser, int64, error) {
	return c.downloadWithRange(filePath, -1)
}

func (c *Cloudreve) DownloadWithOffset(filePath string, offset int64) (io.ReadCloser, int64, error) {
	return c.downloadWithRange(filePath, offset)
}

func (c *Cloudreve) downloadWithRange(filePath string, offset int64) (io.ReadCloser, int64, error) {
	fileURI := c.uri(filePath)

	// Get download URL via /api/v4/file/url (POST)
	// Response: {"urls": [{"url": "..."}], "expires": "..."}
	var urlResp fileURLResponse
	err := c.doJSON("POST", c.server+"/api/v4/file/url", map[string]interface{}{
		"uris":     []string{fileURI},
		"download": true,
	}, &urlResp)
	if err != nil {
		c.logger.Printf("Download: get URL failed for %s (uri=%s): %v", filePath, fileURI, err)
		return nil, 0, fmt.Errorf("get download URL: %w", err)
	}
	if len(urlResp.Urls) == 0 || urlResp.Urls[0].URL == "" {
		c.logger.Printf("Download: empty URL for %s (uri=%s), resp=%+v", filePath, fileURI, urlResp)
		return nil, 0, fmt.Errorf("no download URL returned")
	}

	downloadURL := urlResp.Urls[0].URL
	if !strings.HasPrefix(downloadURL, "http") {
		downloadURL = c.server + downloadURL
	}

	req, err := http.NewRequest("GET", downloadURL, nil)
	if err != nil {
		return nil, 0, err
	}
	if offset > 0 {
		req.Header.Set("Range", fmt.Sprintf("bytes=%d-", offset))
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, 0, err
	}
	if resp.StatusCode >= 400 {
		resp.Body.Close()
		return nil, 0, fmt.Errorf("download HTTP %d", resp.StatusCode)
	}

	// For Range requests, parse Content-Range to get total file size.
	// Format: "bytes start-end/total"
	totalSize := resp.ContentLength
	if cr := resp.Header.Get("Content-Range"); cr != "" {
		if idx := strings.LastIndex(cr, "/"); idx >= 0 {
			if total, err := strconv.ParseInt(cr[idx+1:], 10, 64); err == nil {
				totalSize = total
			}
		}
	}

	return resp.Body, totalSize, nil
}

func (c *Cloudreve) Delete(filePath string) error {
	fileURI := c.uri(filePath)

	reqBody, _ := json.Marshal(map[string]interface{}{
		"uris":             []string{fileURI},
		"skip_soft_delete": true,
	})

	req, err := c.authRequest("DELETE", c.server+"/api/v4/file", bytes.NewReader(reqBody))
	if err != nil {
		return err
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var apiResp apiResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return fmt.Errorf("delete decode: %w", err)
	}
	if apiResp.Code != 0 {
		return fmt.Errorf("delete failed: %s", apiResp.Msg)
	}
	return nil
}

func (c *Cloudreve) Rename(oldPath, newPath string) error {
	oldURI := c.uri(oldPath)
	newDir := path.Dir(newPath)
	newName := path.Base(newPath)
	oldDir := path.Dir(oldPath)

	if oldDir == newDir {
		// Same directory: simple rename
		return c.doJSON("POST", c.server+"/api/v4/file/rename", map[string]interface{}{
			"uri":      oldURI,
			"new_name": newName,
		}, nil)
	}

	// Cross-directory: move
	if err := c.ensureParentDirs(newPath); err != nil {
		return err
	}
	dstURI := "cloudreve://my" + path.Join("/", c.rootPath, newDir)
	return c.doJSON("POST", c.server+"/api/v4/file/move", map[string]interface{}{
		"uris": []string{oldURI},
		"dst":  dstURI,
	}, nil)
}

func (c *Cloudreve) Range(dir string, deal func(fs.FileInfo) bool) error {
	dirURI := c.uri(dir)
	page := 1
	pageSize := 100
	for {
		data, err := c.listFiles(dirURI, page, pageSize, "")
		if err != nil {
			return err
		}
		for _, obj := range data.Files {
			fi := &cloudreveFileInfo{
				name:    obj.Name,
				size:    obj.Size,
				modTime: obj.UpdatedAt,
				isDir:   obj.Type == 1,
			}
			if !deal(fi) {
				return nil
			}
		}
		if data.Pagination == nil || page*pageSize >= data.Pagination.Total {
			break
		}
		page++
	}
	return nil
}

// --- SmartBackend interface ---

func (c *Cloudreve) ListPhotos() ([]localstore.RemoteFile, error) {
	var result []localstore.RemoteFile
	rootURI := c.uri("")

	// List year directories
	yearData, err := c.listFiles(rootURI, 1, 100, "")
	if err != nil {
		return nil, fmt.Errorf("list root: %w", err)
	}

	for _, yObj := range yearData.Files {
		if yObj.Type != 1 {
			continue
		}
		if _, err := strconv.Atoi(yObj.Name); err != nil {
			continue
		}
		// List month directories
		yearURI := c.uri(yObj.Name)
		monthData, err := c.listFiles(yearURI, 1, 100, "")
		if err != nil {
			continue
		}
		for _, mObj := range monthData.Files {
			if mObj.Type != 1 {
				continue
			}
			if _, err := strconv.Atoi(mObj.Name); err != nil {
				continue
			}
			// List day directories
			monthURI := c.uri(path.Join(yObj.Name, mObj.Name))
			dayData, err := c.listFiles(monthURI, 1, 100, "")
			if err != nil {
				continue
			}
			for _, dObj := range dayData.Files {
				if dObj.Type != 1 {
					continue
				}
				if _, err := strconv.Atoi(dObj.Name); err != nil {
					continue
				}
				// List files in day directory
				dayURI := c.uri(path.Join(yObj.Name, mObj.Name, dObj.Name))
				page := 1
				for {
					fileData, err := c.listFiles(dayURI, page, 100, "image")
					if err != nil {
						break
					}
					for _, fObj := range fileData.Files {
						if fObj.Type == 1 {
							continue
						}
						rf := localstore.RemoteFile{
							Path:    path.Join(yObj.Name, mObj.Name, dObj.Name, fObj.Name),
							Size:    fObj.Size,
							ModTime: fObj.UpdatedAt,
						}
						if takenStr, ok := fObj.Metadata["image:taken_at"]; ok {
							if t, err := time.Parse(time.RFC3339, takenStr); err == nil {
								rf.TakenAt = t
							}
						}
						if latStr, ok := fObj.Metadata["image:latitude"]; ok {
							if lat, err := strconv.ParseFloat(latStr, 64); err == nil {
								rf.Latitude = lat
							}
						}
						if lngStr, ok := fObj.Metadata["image:longitude"]; ok {
							if lng, err := strconv.ParseFloat(lngStr, 64); err == nil {
								rf.Longitude = lng
							}
						}
						result = append(result, rf)
					}
					if fileData.Pagination == nil || page*100 >= fileData.Pagination.Total {
						break
					}
					page++
				}
			}
		}
	}

	return result, nil
}

func (c *Cloudreve) GetThumbnail(filePath string) ([]byte, error) {
	fileURI := c.uri(filePath)
	u, _ := url.Parse(c.server + "/api/v4/file/thumb")
	q := u.Query()
	q.Set("uri", fileURI)
	u.RawQuery = q.Encode()

	req, err := c.authRequest("GET", u.String(), nil)
	if err != nil {
		return nil, err
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("thumbnail not available (HTTP %d)", resp.StatusCode)
	}

	// Cloudreve v4 returns JSON: {"code":0,"data":{"url":"...","expires":"..."}}
	var apiResp apiResponse
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(body, &apiResp); err != nil {
		// Not JSON — might be raw image data from older API
		return body, nil
	}
	if apiResp.Code != 0 {
		return nil, fmt.Errorf("thumb API error: code %d, msg %s", apiResp.Code, apiResp.Msg)
	}

	var thumbResp struct {
		Url string `json:"url"`
	}
	if err := json.Unmarshal(apiResp.Data, &thumbResp); err != nil {
		return nil, fmt.Errorf("failed to parse thumb response: %w", err)
	}
	if thumbResp.Url == "" {
		return nil, fmt.Errorf("thumb API returned empty URL")
	}

	// Resolve relative URL against server base
	thumbURL := thumbResp.Url
	if !strings.HasPrefix(thumbURL, "http") {
		thumbURL = strings.TrimRight(c.server, "/") + "/" + strings.TrimLeft(thumbURL, "/")
	}

	// Fetch the actual thumbnail image
	imgReq, err := http.NewRequest("GET", thumbURL, nil)
	if err != nil {
		return nil, err
	}
	imgResp, err := c.client.Do(imgReq)
	if err != nil {
		return nil, err
	}
	defer imgResp.Body.Close()

	if imgResp.StatusCode >= 400 {
		return nil, fmt.Errorf("failed to fetch thumb image (HTTP %d)", imgResp.StatusCode)
	}

	return io.ReadAll(imgResp.Body)
}

// --- Exported helpers for API handler ---

func (c *Cloudreve) ListDir(dir string) ([]string, error) {
	dirURI := "cloudreve://my" + path.Join("/", c.rootPath, dir)
	data, err := c.listFiles(dirURI, 1, 200, "")
	if err != nil {
		return nil, err
	}
	var dirs []string
	for _, obj := range data.Files {
		if obj.Type == 1 {
			dirs = append(dirs, obj.Name)
		}
	}
	return dirs, nil
}

// --- fs.FileInfo implementation ---

type cloudreveFileInfo struct {
	name    string
	size    int64
	modTime time.Time
	isDir   bool
}

func (f *cloudreveFileInfo) Name() string      { return f.name }
func (f *cloudreveFileInfo) Size() int64        { return f.size }
func (f *cloudreveFileInfo) Mode() fs.FileMode  { return 0644 }
func (f *cloudreveFileInfo) ModTime() time.Time { return f.modTime }
func (f *cloudreveFileInfo) IsDir() bool        { return f.isDir }
func (f *cloudreveFileInfo) Sys() interface{}   { return nil }
