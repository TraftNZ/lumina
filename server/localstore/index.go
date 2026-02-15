package localstore

import (
	"fmt"
	"strings"
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

// UpdateLabels sets ML labels for a photo that's already indexed.
func (s *LocalStore) UpdateLabels(path string, labels []string, faceIDs []string, text string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return fmt.Errorf("store not initialized")
	}
	entry, exists := s.data.Photos[path]
	if !exists {
		return fmt.Errorf("photo not found: %s", path)
	}
	entry.Labels = labels
	entry.FaceIDs = faceIDs
	entry.Text = text
	s.data.Photos[path] = entry
	s.saveLocked()
	return nil
}

// LabelSummary holds the count and a sample path for a label.
type LabelSummary struct {
	Label      string
	Count      int
	SamplePath string
}

// LabelSummaryResult holds aggregated label stats and face stats.
type LabelSummaryResult struct {
	Labels     []LabelSummary
	FaceCount  int
	FaceSample string
}

// GetLabelSummary scans all photos and returns per-label counts with a sample path, plus face stats.
func (s *LocalStore) GetLabelSummary() LabelSummaryResult {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var result LabelSummaryResult
	if !s.initialized {
		return result
	}
	labelCounts := make(map[string]int)
	labelSample := make(map[string]string)
	for path, entry := range s.data.Photos {
		for _, label := range entry.Labels {
			if strings.HasPrefix(label, "_") {
				continue
			}
			labelCounts[label]++
			if _, ok := labelSample[label]; !ok {
				labelSample[label] = path
			}
		}
		if len(entry.FaceIDs) > 0 {
			result.FaceCount++
			if result.FaceSample == "" {
				result.FaceSample = path
			}
		}
	}
	result.Labels = make([]LabelSummary, 0, len(labelCounts))
	for label, count := range labelCounts {
		result.Labels = append(result.Labels, LabelSummary{
			Label:      label,
			Count:      count,
			SamplePath: labelSample[label],
		})
	}
	return result
}

// SearchLabels returns paths whose labels or text contain any of the query terms (case-insensitive substring match).
// Special query "_faces" returns all photos with detected faces.
func (s *LocalStore) SearchLabels(query string) []string {
	if query == "" {
		return nil
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	if !s.initialized {
		return nil
	}
	if query == "_faces" {
		var results []string
		for path, entry := range s.data.Photos {
			if len(entry.FaceIDs) > 0 {
				results = append(results, path)
			}
		}
		return results
	}
	query = strings.ToLower(query)
	queryTerms := strings.Fields(query)
	var results []string
	for path, entry := range s.data.Photos {
		// Search in labels (skip internal sentinel labels starting with _)
		for _, label := range entry.Labels {
			if strings.HasPrefix(label, "_") {
				continue
			}
			labelLower := strings.ToLower(label)
			for _, term := range queryTerms {
				if strings.Contains(labelLower, term) {
					results = append(results, path)
					goto nextPhoto
				}
			}
		}
		// Search in text (OCR)
		if entry.Text != "" {
			textLower := strings.ToLower(entry.Text)
			for _, term := range queryTerms {
				if strings.Contains(textLower, term) {
					results = append(results, path)
					goto nextPhoto
				}
			}
		}
	nextPhoto:
	}
	return results
}

// GetUnlabeledPaths returns paths that have no ML labels yet (for batch indexing).
func (s *LocalStore) GetUnlabeledPaths(limit int) []string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if !s.initialized {
		return nil
	}
	var results []string
	for path, entry := range s.data.Photos {
		if len(entry.Labels) == 0 && entry.Text == "" {
			results = append(results, path)
			if limit > 0 && len(results) >= limit {
				break
			}
		}
	}
	return results
}
