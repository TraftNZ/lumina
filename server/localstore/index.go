package localstore

import (
	"fmt"
	"time"
)

func (s *LocalStore) IndexPhoto(path string, filename string, size int64) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return fmt.Errorf("store not initialized")
	}
	s.data.Photos[path] = photoEntry{
		Path:      path,
		Filename:  filename,
		Size:      size,
		IndexedAt: time.Now().Unix(),
	}
	// Update filename index
	paths := s.data.FilenameIndex[filename]
	for _, p := range paths {
		if p == path {
			return nil // already indexed
		}
	}
	s.data.FilenameIndex[filename] = append(paths, path)
	return nil
}

func (s *LocalStore) RemovePhoto(path string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return fmt.Errorf("store not initialized")
	}
	entry, ok := s.data.Photos[path]
	if !ok {
		return nil
	}
	delete(s.data.Photos, path)
	// Update filename index
	paths := s.data.FilenameIndex[entry.Filename]
	for i, p := range paths {
		if p == path {
			s.data.FilenameIndex[entry.Filename] = append(paths[:i], paths[i+1:]...)
			break
		}
	}
	if len(s.data.FilenameIndex[entry.Filename]) == 0 {
		delete(s.data.FilenameIndex, entry.Filename)
	}
	return nil
}

func (s *LocalStore) PhotoExistsByFilename(filename string) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if !s.initialized {
		return false
	}
	paths := s.data.FilenameIndex[filename]
	return len(paths) > 0
}

func (s *LocalStore) BatchExistsByFilename(filenames []string) map[string]bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make(map[string]bool, len(filenames))
	if !s.initialized {
		return result
	}
	for _, f := range filenames {
		if len(s.data.FilenameIndex[f]) > 0 {
			result[f] = true
		}
	}
	return result
}

func (s *LocalStore) IsEmpty() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if !s.initialized {
		return true
	}
	return len(s.data.Photos) == 0
}

func (s *LocalStore) PhotoCount() int64 {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if !s.initialized {
		return 0
	}
	return int64(len(s.data.Photos))
}

func (s *LocalStore) RebuildFromRemote(
	walkFn func(cb func(path string, filename string, size int64) bool) error,
	progressCb func(found int),
) error {
	s.mu.Lock()
	if !s.initialized {
		s.mu.Unlock()
		return fmt.Errorf("store not initialized")
	}
	// Clear existing data
	s.data.Photos = make(map[string]photoEntry)
	s.data.FilenameIndex = make(map[string][]string)
	s.mu.Unlock()

	now := time.Now().Unix()
	count := 0

	err := walkFn(func(path string, filename string, size int64) bool {
		s.mu.Lock()
		s.data.Photos[path] = photoEntry{
			Path:      path,
			Filename:  filename,
			Size:      size,
			IndexedAt: now,
		}
		s.data.FilenameIndex[filename] = append(s.data.FilenameIndex[filename], path)
		s.mu.Unlock()
		count++
		if count%500 == 0 && progressCb != nil {
			progressCb(count)
		}
		return true
	})
	if err != nil {
		return err
	}

	if progressCb != nil {
		progressCb(count)
	}

	s.mu.Lock()
	s.data.LastFullIndex = time.Now().Unix()
	s.saveLocked()
	s.mu.Unlock()

	s.logger.Printf("RebuildFromRemote complete: %d photos indexed", count)
	return nil
}

func (s *LocalStore) LastIndexTimestamp() int64 {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if !s.initialized {
		return 0
	}
	return s.data.LastFullIndex
}
