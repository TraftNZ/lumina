package localstore

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"time"
)

func (s *LocalStore) GetThumb(path string) ([]byte, error) {
	s.mu.RLock()
	if !s.initialized {
		s.mu.RUnlock()
		return nil, fmt.Errorf("store not initialized")
	}
	entry, ok := s.data.Thumbs[path]
	s.mu.RUnlock()
	if !ok {
		return nil, fmt.Errorf("cache miss")
	}

	data, err := os.ReadFile(entry.CacheFile)
	if err != nil {
		s.mu.Lock()
		delete(s.data.Thumbs, path)
		s.mu.Unlock()
		return nil, fmt.Errorf("cache file read error: %w", err)
	}

	// Update last_access
	s.mu.Lock()
	entry.LastAccess = time.Now().Unix()
	s.data.Thumbs[path] = entry
	s.mu.Unlock()
	return data, nil
}

func (s *LocalStore) PutThumb(path string, data []byte) error {
	s.mu.RLock()
	if !s.initialized {
		s.mu.RUnlock()
		return fmt.Errorf("store not initialized")
	}
	thumbDir := s.thumbDir
	s.mu.RUnlock()

	cacheFile := filepath.Join(thumbDir, path)
	if err := os.MkdirAll(filepath.Dir(cacheFile), 0755); err != nil {
		return fmt.Errorf("create thumb subdir: %w", err)
	}

	if err := os.WriteFile(cacheFile, data, 0644); err != nil {
		return fmt.Errorf("write thumb file: %w", err)
	}

	now := time.Now().Unix()
	s.mu.Lock()
	s.data.Thumbs[path] = thumbEntry{
		Path:       path,
		CacheFile:  cacheFile,
		Size:       int64(len(data)),
		CachedAt:   now,
		LastAccess: now,
	}
	s.mu.Unlock()

	go s.evictIfNeeded()
	return nil
}

func (s *LocalStore) RemoveThumb(path string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	entry, ok := s.data.Thumbs[path]
	if ok {
		os.Remove(entry.CacheFile)
		delete(s.data.Thumbs, path)
	}
}

func (s *LocalStore) CacheSizeBytes() int64 {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if !s.initialized {
		return 0
	}
	var total int64
	for _, e := range s.data.Thumbs {
		total += e.Size
	}
	return total
}

func (s *LocalStore) ClearAllThumbs() int64 {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return 0
	}
	var freed int64
	for _, e := range s.data.Thumbs {
		freed += e.Size
		os.Remove(e.CacheFile)
	}
	s.data.Thumbs = make(map[string]thumbEntry)
	s.saveLocked()
	return freed
}

func (s *LocalStore) evictIfNeeded() {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}

	var totalSize int64
	for _, e := range s.data.Thumbs {
		totalSize += e.Size
	}
	if totalSize <= s.maxCacheBytes {
		return
	}

	targetSize := s.maxCacheBytes * 80 / 100

	// Sort by last access (oldest first)
	type sortEntry struct {
		path       string
		lastAccess int64
		size       int64
		cacheFile  string
	}
	entries := make([]sortEntry, 0, len(s.data.Thumbs))
	for _, e := range s.data.Thumbs {
		entries = append(entries, sortEntry{e.Path, e.LastAccess, e.Size, e.CacheFile})
	}
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].lastAccess < entries[j].lastAccess
	})

	for _, e := range entries {
		if totalSize <= targetSize {
			break
		}
		os.Remove(e.cacheFile)
		delete(s.data.Thumbs, e.path)
		totalSize -= e.size
	}

	s.logger.Printf("Cache eviction complete, current size: %d bytes", totalSize)
}
