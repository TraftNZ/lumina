package localstore

import (
	"crypto/sha256"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/google/uuid"
	_ "modernc.org/sqlite"
)

const schemaSQL = `
CREATE TABLE IF NOT EXISTS meta (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ml_results (
    path     TEXT PRIMARY KEY,
    labels   TEXT NOT NULL DEFAULT '[]',
    face_ids TEXT NOT NULL DEFAULT '[]',
    text     TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS remote_files (
    path      TEXT PRIMARY KEY,
    size      INTEGER NOT NULL DEFAULT 0,
    mod_time  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS thumb_failures (
    path      TEXT PRIMARY KEY,
    failed_at INTEGER NOT NULL DEFAULT 0
);
`

type LocalStore struct {
	mu          sync.Mutex
	db          *sql.DB
	baseDataDir string
	dbPath      string
	logger      *log.Logger
	initialized bool
}

func New(dataDir string) (*LocalStore, error) {
	s := &LocalStore{
		baseDataDir: dataDir,
		logger:      log.New(os.Stdout, "[LocalStore] ", log.LstdFlags),
	}
	return s, nil
}

func (s *LocalStore) SwitchDrive(configHash string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.initialized && s.db != nil {
		s.db.Close()
		s.db = nil
		s.initialized = false
	}

	hash := fmt.Sprintf("%x", sha256.Sum256([]byte(configHash)))[:16]
	dataDir := filepath.Join(s.baseDataDir, "lumina", hash)
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return fmt.Errorf("create data dir: %w", err)
	}

	s.dbPath = filepath.Join(dataDir, "ml.db")

	db, err := sql.Open("sqlite", s.dbPath+"?_journal_mode=wal&_busy_timeout=5000")
	if err != nil {
		return fmt.Errorf("open sqlite: %w", err)
	}
	db.SetMaxOpenConns(1)

	if _, err := db.Exec(schemaSQL); err != nil {
		db.Close()
		return fmt.Errorf("create schema: %w", err)
	}

	s.db = db

	clientID := s.getMeta("client_id")
	if clientID == "" {
		clientID = uuid.New().String()
		s.setMeta("client_id", clientID)
	}

	s.initialized = true
	s.logger.Printf("Switched to ML store: %s (clientID=%s)", s.dbPath, clientID)
	return nil
}

func (s *LocalStore) Close() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.db != nil {
		err := s.db.Close()
		s.db = nil
		s.initialized = false
		return err
	}
	return nil
}

func (s *LocalStore) GetClientID() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return ""
	}
	return s.getMeta("client_id")
}

func (s *LocalStore) getMeta(key string) string {
	var value string
	err := s.db.QueryRow(`SELECT value FROM meta WHERE key=?`, key).Scan(&value)
	if err != nil {
		return ""
	}
	return value
}

func (s *LocalStore) setMeta(key, value string) {
	s.db.Exec(`INSERT OR REPLACE INTO meta(key,value) VALUES(?,?)`, key, value)
}

func encodeStringSlice(sl []string) string {
	if len(sl) == 0 {
		return "[]"
	}
	data, _ := json.Marshal(sl)
	return string(data)
}

func decodeStringSlice(s string) []string {
	if s == "" || s == "[]" {
		return nil
	}
	var result []string
	json.Unmarshal([]byte(s), &result)
	return result
}

func (s *LocalStore) BaseDataDir() string {
	return s.baseDataDir
}

func DriveDataDir(baseDataDir, configHash string) string {
	hash := fmt.Sprintf("%x", sha256.Sum256([]byte(configHash)))[:16]
	return filepath.Join(baseDataDir, "lumina", hash)
}

type SavedToken struct {
	RefreshToken string    `json:"refresh_token"`
	RefreshExp   time.Time `json:"refresh_exp"`
}

func SaveTokenFile(dir string, token SavedToken) error {
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("create token dir: %w", err)
	}
	data, err := json.Marshal(token)
	if err != nil {
		return fmt.Errorf("marshal token: %w", err)
	}
	return os.WriteFile(filepath.Join(dir, "token.json"), data, 0600)
}

func LoadTokenFile(dir string) (SavedToken, error) {
	var token SavedToken
	data, err := os.ReadFile(filepath.Join(dir, "token.json"))
	if err != nil {
		return token, err
	}
	err = json.Unmarshal(data, &token)
	return token, err
}

