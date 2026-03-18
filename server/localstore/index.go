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
	_, err := s.db.Exec(
		`INSERT OR REPLACE INTO photos(path,filename,size,indexed_at) VALUES(?,?,?,?)`,
		path, filename, size, time.Now().Unix())
	return err
}

func (s *LocalStore) RemovePhoto(path string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return fmt.Errorf("store not initialized")
	}
	_, err := s.db.Exec(`DELETE FROM photos WHERE path=?`, path)
	return err
}

func (s *LocalStore) PhotoExistsByFilename(filename string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return false
	}
	var n int
	err := s.db.QueryRow(`SELECT 1 FROM photos WHERE filename=? LIMIT 1`, filename).Scan(&n)
	return err == nil
}

func (s *LocalStore) BatchExistsByFilename(filenames []string) map[string]bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	result := make(map[string]bool, len(filenames))
	if !s.initialized {
		return result
	}
	stmt, err := s.db.Prepare(`SELECT 1 FROM photos WHERE filename=? LIMIT 1`)
	if err != nil {
		return result
	}
	defer stmt.Close()
	for _, f := range filenames {
		var n int
		if stmt.QueryRow(f).Scan(&n) == nil {
			result[f] = true
		}
	}
	return result
}

// ListPhotos returns photo paths sorted by date descending (newest first),
// filtered to paths with date <= beforeDate, with offset/limit pagination.
func (s *LocalStore) ListPhotos(beforeDate time.Time, offset, limit int) []string {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return nil
	}
	cutoff := beforeDate.Format("2006/01/02")
	rows, err := s.db.Query(
		`SELECT path FROM photos WHERE substr(path,1,10) <= ? ORDER BY path DESC LIMIT ? OFFSET ?`,
		cutoff, limit, offset)
	if err != nil {
		return nil
	}
	defer rows.Close()
	var paths []string
	for rows.Next() {
		var p string
		if rows.Scan(&p) == nil {
			paths = append(paths, p)
		}
	}
	return paths
}

func (s *LocalStore) IsEmpty() bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return true
	}
	var n int
	err := s.db.QueryRow(`SELECT 1 FROM photos LIMIT 1`).Scan(&n)
	return err != nil
}

func (s *LocalStore) PhotoCount() int64 {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return 0
	}
	return s.photoCountLocked()
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

	// Clear existing photos
	if _, err := s.db.Exec(`DELETE FROM photos`); err != nil {
		s.mu.Unlock()
		return fmt.Errorf("clear photos: %w", err)
	}
	s.mu.Unlock()

	now := time.Now().Unix()
	count := 0
	const batchSize = 1000

	// Collect entries in batches
	type entry struct {
		path, filename string
		size           int64
	}
	batch := make([]entry, 0, batchSize)

	flushBatch := func() error {
		if len(batch) == 0 {
			return nil
		}
		s.mu.Lock()
		defer s.mu.Unlock()
		tx, err := s.db.Begin()
		if err != nil {
			return err
		}
		defer tx.Rollback()
		stmt, err := tx.Prepare(`INSERT INTO photos(path,filename,size,indexed_at) VALUES(?,?,?,?)`)
		if err != nil {
			return err
		}
		defer stmt.Close()
		for _, e := range batch {
			if _, err := stmt.Exec(e.path, e.filename, e.size, now); err != nil {
				return err
			}
		}
		return tx.Commit()
	}

	err := walkFn(func(path string, filename string, size int64) bool {
		batch = append(batch, entry{path, filename, size})
		count++
		if len(batch) >= batchSize {
			if err := flushBatch(); err != nil {
				return false
			}
			batch = batch[:0]
			if progressCb != nil {
				progressCb(count)
			}
		}
		return true
	})
	if err != nil {
		return err
	}

	// Flush remaining
	if err := flushBatch(); err != nil {
		return err
	}

	if progressCb != nil {
		progressCb(count)
	}

	s.mu.Lock()
	s.setMeta("last_full_index", fmt.Sprintf("%d", time.Now().Unix()))
	s.mu.Unlock()

	s.logger.Printf("RebuildFromRemote complete: %d photos indexed", count)
	return nil
}

func (s *LocalStore) LastIndexTimestamp() int64 {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return 0
	}
	return s.getMetaInt64("last_full_index")
}

// UpdateLabels sets ML labels for a photo that's already indexed.
func (s *LocalStore) UpdateLabels(path string, labels []string, faceIDs []string, text string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return fmt.Errorf("store not initialized")
	}
	result, err := s.db.Exec(
		`UPDATE photos SET labels=?, face_ids=?, text=? WHERE path=?`,
		encodeStringSlice(labels), encodeStringSlice(faceIDs), text, path)
	if err != nil {
		return err
	}
	n, _ := result.RowsAffected()
	if n == 0 {
		return fmt.Errorf("photo not found: %s", path)
	}
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
	s.mu.Lock()
	defer s.mu.Unlock()
	var result LabelSummaryResult
	if !s.initialized {
		return result
	}

	rows, err := s.db.Query(`SELECT path, labels, face_ids FROM photos WHERE labels != '[]' OR face_ids != '[]'`)
	if err != nil {
		return result
	}
	defer rows.Close()

	labelCounts := make(map[string]int)
	labelSample := make(map[string]string)

	for rows.Next() {
		var path, labelsJSON, faceIDsJSON string
		if rows.Scan(&path, &labelsJSON, &faceIDsJSON) != nil {
			continue
		}
		labels := decodeStringSlice(labelsJSON)
		faceIDs := decodeStringSlice(faceIDsJSON)

		for _, label := range labels {
			if strings.HasPrefix(label, "_") {
				continue
			}
			labelCounts[label]++
			if _, ok := labelSample[label]; !ok {
				labelSample[label] = path
			}
		}
		if len(faceIDs) > 0 {
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
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return nil
	}

	if query == "_faces" {
		rows, err := s.db.Query(`SELECT path FROM photos WHERE face_ids != '[]'`)
		if err != nil {
			return nil
		}
		defer rows.Close()
		var results []string
		for rows.Next() {
			var p string
			if rows.Scan(&p) == nil {
				results = append(results, p)
			}
		}
		return results
	}

	queryLower := strings.ToLower(query)
	queryTerms := strings.Fields(queryLower)

	// Use SQL LIKE for initial filtering, then Go-side post-filter for exact match
	rows, err := s.db.Query(`SELECT path, labels, text FROM photos WHERE labels LIKE '%' || ? || '%' OR text LIKE '%' || ? || '%'`,
		queryTerms[0], queryTerms[0])
	if err != nil {
		return nil
	}
	defer rows.Close()

	var results []string
	for rows.Next() {
		var path, labelsJSON, text string
		if rows.Scan(&path, &labelsJSON, &text) != nil {
			continue
		}

		labels := decodeStringSlice(labelsJSON)
		matched := false

		for _, label := range labels {
			if strings.HasPrefix(label, "_") {
				continue
			}
			labelLower := strings.ToLower(label)
			for _, term := range queryTerms {
				if strings.Contains(labelLower, term) {
					matched = true
					break
				}
			}
			if matched {
				break
			}
		}

		if !matched && text != "" {
			textLower := strings.ToLower(text)
			for _, term := range queryTerms {
				if strings.Contains(textLower, term) {
					matched = true
					break
				}
			}
		}

		if matched {
			results = append(results, path)
		}
	}
	return results
}

// GetUnlabeledPaths returns paths that have no ML labels yet (for batch indexing).
func (s *LocalStore) GetUnlabeledPaths(limit int) []string {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return nil
	}
	rows, err := s.db.Query(`SELECT path FROM photos WHERE labels='[]' AND text='' LIMIT ?`, limit)
	if err != nil {
		return nil
	}
	defer rows.Close()
	var results []string
	for rows.Next() {
		var p string
		if rows.Scan(&p) == nil {
			results = append(results, p)
		}
	}
	return results
}
