package localstore

import (
	"crypto/sha256"
	"encoding/gob"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
)

const defaultMaxCache = 500 * 1024 * 1024 // 500MB

type photoEntry struct {
	Path      string
	Filename  string
	Size      int64
	IndexedAt int64
}

type thumbEntry struct {
	Path       string
	CacheFile  string
	Size       int64
	CachedAt   int64
	LastAccess int64
}

type indexData struct {
	Photos         map[string]photoEntry // key: path
	FilenameIndex  map[string][]string   // filename -> []path (for fast lookup)
	Thumbs         map[string]thumbEntry // key: path
	LastFullIndex  int64
	LastSeenMarker string // remote .sync_marker value at last rebuild
}

type LocalStore struct {
	mu            sync.RWMutex
	data          indexData
	baseDataDir   string
	baseCacheDir  string
	dataFile      string
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

	// Save current data before switching
	if s.initialized {
		s.saveLocked()
	}

	hash := fmt.Sprintf("%x", sha256.Sum256([]byte(configHash)))[:16]
	dataDir := filepath.Join(s.baseDataDir, "pho", hash)
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return fmt.Errorf("create data dir: %w", err)
	}
	s.dataFile = filepath.Join(dataDir, "index.gob")
	s.thumbDir = filepath.Join(s.baseCacheDir, "pho", hash, "thumbs")
	if err := os.MkdirAll(s.thumbDir, 0755); err != nil {
		return fmt.Errorf("create thumb dir: %w", err)
	}

	// Load existing data or create empty
	s.data = indexData{
		Photos:        make(map[string]photoEntry),
		FilenameIndex: make(map[string][]string),
		Thumbs:        make(map[string]thumbEntry),
	}
	if f, err := os.Open(s.dataFile); err == nil {
		dec := gob.NewDecoder(f)
		if err := dec.Decode(&s.data); err != nil {
			s.logger.Printf("Failed to load index (starting fresh): %v", err)
			s.data = indexData{
				Photos:        make(map[string]photoEntry),
				FilenameIndex: make(map[string][]string),
				Thumbs:        make(map[string]thumbEntry),
			}
		}
		f.Close()
	}
	s.initialized = true
	s.logger.Printf("Switched to drive store: %s (%d photos indexed)", s.dataFile, len(s.data.Photos))
	return nil
}

func (s *LocalStore) saveLocked() {
	if s.dataFile == "" {
		return
	}
	tmp := s.dataFile + ".tmp"
	f, err := os.Create(tmp)
	if err != nil {
		s.logger.Printf("Failed to save index: %v", err)
		return
	}
	enc := gob.NewEncoder(f)
	if err := enc.Encode(&s.data); err != nil {
		f.Close()
		os.Remove(tmp)
		s.logger.Printf("Failed to encode index: %v", err)
		return
	}
	f.Close()
	os.Rename(tmp, s.dataFile)
}

func (s *LocalStore) Save() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.saveLocked()
}

func (s *LocalStore) Close() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.initialized {
		s.saveLocked()
	}
	return nil
}

func (s *LocalStore) ThumbDir() string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.thumbDir
}

func (s *LocalStore) GetLastSeenMarker() string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if !s.initialized {
		return ""
	}
	return s.data.LastSeenMarker
}

func (s *LocalStore) SetLastSeenMarker(marker string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	s.data.LastSeenMarker = marker
	s.saveLocked()
}
