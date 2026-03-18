package localstore

import (
	"bytes"
	"crypto/sha256"
	"database/sql"
	"encoding/gob"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"time"

	"github.com/google/uuid"
	_ "modernc.org/sqlite"
)

const defaultMaxCache = 500 * 1024 * 1024 // 500MB

const schemaSQL = `
CREATE TABLE IF NOT EXISTS meta (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS photos (
    path       TEXT PRIMARY KEY,
    filename   TEXT NOT NULL,
    size       INTEGER NOT NULL DEFAULT 0,
    indexed_at INTEGER NOT NULL DEFAULT 0,
    labels     TEXT NOT NULL DEFAULT '[]',
    face_ids   TEXT NOT NULL DEFAULT '[]',
    text       TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS idx_photos_filename ON photos(filename);

CREATE TABLE IF NOT EXISTS thumbs (
    path        TEXT PRIMARY KEY,
    cache_file  TEXT NOT NULL,
    size        INTEGER NOT NULL DEFAULT 0,
    cached_at   INTEGER NOT NULL DEFAULT 0,
    last_access INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_thumbs_last_access ON thumbs(last_access);
`

type LocalStore struct {
	mu            sync.Mutex
	db            *sql.DB
	baseDataDir   string
	baseCacheDir  string
	dbPath        string
	thumbDir      string
	maxCacheBytes int64
	logger        *log.Logger
	initialized   bool
}

func New(dataDir, cacheDir string) (*LocalStore, error) {
	s := &LocalStore{
		baseDataDir:   dataDir,
		baseCacheDir:  cacheDir,
		maxCacheBytes: defaultMaxCache,
		logger:        log.New(os.Stdout, "[LocalStore] ", log.LstdFlags),
	}
	return s, nil
}

func (s *LocalStore) SwitchDrive(configHash string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Close old DB if initialized
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
	s.thumbDir = filepath.Join(s.baseCacheDir, "lumina", hash, "thumbs")
	if err := os.MkdirAll(s.thumbDir, 0755); err != nil {
		return fmt.Errorf("create thumb dir: %w", err)
	}

	s.dbPath = filepath.Join(dataDir, "index.db")

	// Check for gob migration before opening DB
	gobPath := filepath.Join(dataDir, "index.gob")
	needsMigration := false
	if _, err := os.Stat(gobPath); err == nil {
		needsMigration = true
	}

	// Open SQLite
	db, err := sql.Open("sqlite", s.dbPath+"?_journal_mode=wal&_busy_timeout=5000")
	if err != nil {
		return fmt.Errorf("open sqlite: %w", err)
	}
	db.SetMaxOpenConns(1)

	// Create schema
	if _, err := db.Exec(schemaSQL); err != nil {
		db.Close()
		return fmt.Errorf("create schema: %w", err)
	}

	s.db = db

	// Migrate from gob if needed
	if needsMigration {
		if err := migrateFromGob(gobPath, db, s.logger); err != nil {
			s.logger.Printf("Gob migration failed (starting fresh): %v", err)
		}
	}

	// Ensure client_id exists
	clientID := s.getMeta("client_id")
	if clientID == "" {
		clientID = uuid.New().String()
		s.setMeta("client_id", clientID)
	}

	// Ensure schema_version
	if s.getMeta("schema_version") == "" {
		s.setMeta("schema_version", "1")
	}

	s.initialized = true

	count := s.photoCountLocked()
	s.logger.Printf("Switched to drive store: %s (%d photos indexed, clientID=%s)", s.dbPath, count, clientID)
	return nil
}

func (s *LocalStore) Save() {
	// No-op: SQLite auto-persists
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

func (s *LocalStore) ThumbDir() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.thumbDir
}

func (s *LocalStore) GetLastSeenMarker() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return ""
	}
	return s.getMeta("last_seen_marker")
}

func (s *LocalStore) SetLastSeenMarker(marker string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	s.setMeta("last_seen_marker", marker)
}

// syncIndexEntry is the format used for remote index exchange between devices.
type syncIndexEntry struct {
	Path     string
	Filename string
	Size     int64
	Labels   []string
	FaceIDs  []string
	Text     string
}

// ExportIndex serializes the photo index for uploading to remote storage.
func (s *LocalStore) ExportIndex() ([]byte, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return nil, fmt.Errorf("store not initialized")
	}

	rows, err := s.db.Query(`SELECT path, filename, size, labels, face_ids, text FROM photos`)
	if err != nil {
		return nil, fmt.Errorf("query photos: %w", err)
	}
	defer rows.Close()

	var entries []syncIndexEntry
	for rows.Next() {
		var e syncIndexEntry
		var labelsJSON, faceIDsJSON string
		if err := rows.Scan(&e.Path, &e.Filename, &e.Size, &labelsJSON, &faceIDsJSON, &e.Text); err != nil {
			return nil, fmt.Errorf("scan photo: %w", err)
		}
		e.Labels = decodeStringSlice(labelsJSON)
		e.FaceIDs = decodeStringSlice(faceIDsJSON)
		entries = append(entries, e)
	}

	var buf bytes.Buffer
	if err := gob.NewEncoder(&buf).Encode(entries); err != nil {
		return nil, fmt.Errorf("encode index: %w", err)
	}
	return buf.Bytes(), nil
}

// MergeIndex adds entries from remote index data into the local index
// without removing existing entries.
func (s *LocalStore) MergeIndex(data []byte) {
	var entries []syncIndexEntry
	if err := gob.NewDecoder(bytes.NewReader(data)).Decode(&entries); err != nil {
		s.logger.Printf("MergeIndex decode error: %v", err)
		return
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}

	now := time.Now().Unix()
	tx, err := s.db.Begin()
	if err != nil {
		s.logger.Printf("MergeIndex begin tx: %v", err)
		return
	}
	defer tx.Rollback()

	stmt, err := tx.Prepare(`INSERT OR IGNORE INTO photos(path,filename,size,indexed_at,labels,face_ids,text) VALUES(?,?,?,?,?,?,?)`)
	if err != nil {
		s.logger.Printf("MergeIndex prepare: %v", err)
		return
	}
	defer stmt.Close()

	added := 0
	for _, e := range entries {
		result, err := stmt.Exec(e.Path, e.Filename, e.Size, now,
			encodeStringSlice(e.Labels), encodeStringSlice(e.FaceIDs), e.Text)
		if err != nil {
			s.logger.Printf("MergeIndex insert %s: %v", e.Path, err)
			continue
		}
		if n, _ := result.RowsAffected(); n > 0 {
			added++
		}
	}

	if err := tx.Commit(); err != nil {
		s.logger.Printf("MergeIndex commit: %v", err)
		return
	}

	if added > 0 {
		s.logger.Printf("MergeIndex: added %d entries from remote", added)
	}
}

// ImportIndex replaces the local photo index with data downloaded from remote.
func (s *LocalStore) ImportIndex(data []byte) error {
	var entries []syncIndexEntry
	if err := gob.NewDecoder(bytes.NewReader(data)).Decode(&entries); err != nil {
		return fmt.Errorf("decode index: %w", err)
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return fmt.Errorf("store not initialized")
	}

	now := time.Now().Unix()
	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback()

	if _, err := tx.Exec(`DELETE FROM photos`); err != nil {
		return fmt.Errorf("clear photos: %w", err)
	}

	stmt, err := tx.Prepare(`INSERT INTO photos(path,filename,size,indexed_at,labels,face_ids,text) VALUES(?,?,?,?,?,?,?)`)
	if err != nil {
		return fmt.Errorf("prepare insert: %w", err)
	}
	defer stmt.Close()

	for _, e := range entries {
		if _, err := stmt.Exec(e.Path, e.Filename, e.Size, now,
			encodeStringSlice(e.Labels), encodeStringSlice(e.FaceIDs), e.Text); err != nil {
			return fmt.Errorf("insert photo %s: %w", e.Path, err)
		}
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit: %w", err)
	}

	s.setMeta("last_full_index", fmt.Sprintf("%d", now))
	s.logger.Printf("ImportIndex complete: %d photos", len(entries))
	return nil
}

// Internal helpers

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

func (s *LocalStore) photoCountLocked() int64 {
	var count int64
	s.db.QueryRow(`SELECT COUNT(*) FROM photos`).Scan(&count)
	return count
}

func (s *LocalStore) getMetaInt64(key string) int64 {
	v := s.getMeta(key)
	if v == "" {
		return 0
	}
	n, _ := strconv.ParseInt(v, 10, 64)
	return n
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
