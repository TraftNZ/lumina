package localstore

import (
	"fmt"
	"os"
	"path/filepath"
	"time"
)

func (s *LocalStore) GetThumb(path string) ([]byte, error) {
	s.mu.Lock()
	if !s.initialized {
		s.mu.Unlock()
		return nil, fmt.Errorf("store not initialized")
	}

	var cacheFile string
	err := s.db.QueryRow(`SELECT cache_file FROM thumbs WHERE path=?`, path).Scan(&cacheFile)
	s.mu.Unlock()
	if err != nil {
		return nil, fmt.Errorf("cache miss")
	}

	data, err := os.ReadFile(cacheFile)
	if err != nil {
		s.mu.Lock()
		s.db.Exec(`DELETE FROM thumbs WHERE path=?`, path)
		s.mu.Unlock()
		return nil, fmt.Errorf("cache file read error: %w", err)
	}

	// Update last_access
	s.mu.Lock()
	s.db.Exec(`UPDATE thumbs SET last_access=? WHERE path=?`, time.Now().Unix(), path)
	s.mu.Unlock()
	return data, nil
}

func (s *LocalStore) PutThumb(path string, data []byte) error {
	s.mu.Lock()
	if !s.initialized {
		s.mu.Unlock()
		return fmt.Errorf("store not initialized")
	}
	thumbDir := s.thumbDir
	s.mu.Unlock()

	cacheFile := filepath.Join(thumbDir, path)
	if err := os.MkdirAll(filepath.Dir(cacheFile), 0755); err != nil {
		return fmt.Errorf("create thumb subdir: %w", err)
	}

	if err := os.WriteFile(cacheFile, data, 0644); err != nil {
		return fmt.Errorf("write thumb file: %w", err)
	}

	now := time.Now().Unix()
	s.mu.Lock()
	s.db.Exec(
		`INSERT OR REPLACE INTO thumbs(path,cache_file,size,cached_at,last_access) VALUES(?,?,?,?,?)`,
		path, cacheFile, int64(len(data)), now, now)
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
	var cacheFile string
	if s.db.QueryRow(`SELECT cache_file FROM thumbs WHERE path=?`, path).Scan(&cacheFile) == nil {
		os.Remove(cacheFile)
	}
	s.db.Exec(`DELETE FROM thumbs WHERE path=?`, path)
}

func (s *LocalStore) CacheSizeBytes() int64 {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return 0
	}
	var total int64
	s.db.QueryRow(`SELECT COALESCE(SUM(size),0) FROM thumbs`).Scan(&total)
	return total
}

func (s *LocalStore) ClearAllThumbs() int64 {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return 0
	}

	rows, err := s.db.Query(`SELECT cache_file, size FROM thumbs`)
	if err != nil {
		return 0
	}

	var freed int64
	for rows.Next() {
		var cacheFile string
		var size int64
		if rows.Scan(&cacheFile, &size) == nil {
			os.Remove(cacheFile)
			freed += size
		}
	}
	rows.Close()

	s.db.Exec(`DELETE FROM thumbs`)
	return freed
}

func (s *LocalStore) evictIfNeeded() {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}

	var totalSize int64
	s.db.QueryRow(`SELECT COALESCE(SUM(size),0) FROM thumbs`).Scan(&totalSize)
	if totalSize <= s.maxCacheBytes {
		return
	}

	targetSize := s.maxCacheBytes * 80 / 100

	rows, err := s.db.Query(`SELECT path, cache_file, size FROM thumbs ORDER BY last_access ASC`)
	if err != nil {
		return
	}
	defer rows.Close()

	var toDelete []string
	for rows.Next() && totalSize > targetSize {
		var path, cacheFile string
		var size int64
		if rows.Scan(&path, &cacheFile, &size) != nil {
			continue
		}
		os.Remove(cacheFile)
		toDelete = append(toDelete, path)
		totalSize -= size
	}

	for _, path := range toDelete {
		s.db.Exec(`DELETE FROM thumbs WHERE path=?`, path)
	}

	s.logger.Printf("Cache eviction complete, current size: %d bytes", totalSize)
}
