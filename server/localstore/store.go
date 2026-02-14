package localstore

import (
	"bytes"
	"crypto/sha256"
	"encoding/gob"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
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
	dataDir := filepath.Join(s.baseDataDir, "lumina", hash)
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return fmt.Errorf("create data dir: %w", err)
	}
	s.dataFile = filepath.Join(dataDir, "index.gob")
	s.thumbDir = filepath.Join(s.baseCacheDir, "lumina", hash, "thumbs")
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

// syncIndexEntry is the format used for remote index exchange between devices.
type syncIndexEntry struct {
	Path     string
	Filename string
	Size     int64
}

// ExportIndex serializes the photo index for uploading to remote storage.
func (s *LocalStore) ExportIndex() ([]byte, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if !s.initialized {
		return nil, fmt.Errorf("store not initialized")
	}
	entries := make([]syncIndexEntry, 0, len(s.data.Photos))
	for _, p := range s.data.Photos {
		entries = append(entries, syncIndexEntry{
			Path:     p.Path,
			Filename: p.Filename,
			Size:     p.Size,
		})
	}
	var buf bytes.Buffer
	if err := gob.NewEncoder(&buf).Encode(entries); err != nil {
		return nil, fmt.Errorf("encode index: %w", err)
	}
	return buf.Bytes(), nil
}

// MergeIndex adds entries from remote index data into the local index
// without removing existing entries. This prevents concurrent uploads
// from different devices overwriting each other's entries.
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
	added := 0
	for _, e := range entries {
		if _, exists := s.data.Photos[e.Path]; exists {
			continue
		}
		s.data.Photos[e.Path] = photoEntry{
			Path:      e.Path,
			Filename:  e.Filename,
			Size:      e.Size,
			IndexedAt: now,
		}
		s.data.FilenameIndex[e.Filename] = append(s.data.FilenameIndex[e.Filename], e.Path)
		added++
	}
	if added > 0 {
		s.saveLocked()
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
	s.data.Photos = make(map[string]photoEntry, len(entries))
	s.data.FilenameIndex = make(map[string][]string, len(entries))
	for _, e := range entries {
		s.data.Photos[e.Path] = photoEntry{
			Path:      e.Path,
			Filename:  e.Filename,
			Size:      e.Size,
			IndexedAt: now,
		}
		s.data.FilenameIndex[e.Filename] = append(s.data.FilenameIndex[e.Filename], e.Path)
	}
	s.data.LastFullIndex = now
	s.saveLocked()
	s.logger.Printf("ImportIndex complete: %d photos", len(entries))
	return nil
}
