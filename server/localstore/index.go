package localstore

import (
	"fmt"
	"strings"
)

// UpdateLabels upserts ML labels for a photo path.
func (s *LocalStore) UpdateLabels(path string, labels []string, faceIDs []string, text string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return fmt.Errorf("store not initialized")
	}
	_, err := s.db.Exec(
		`INSERT OR REPLACE INTO ml_results(path,labels,face_ids,text) VALUES(?,?,?,?)`,
		path, encodeStringSlice(labels), encodeStringSlice(faceIDs), text)
	return err
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

// GetLabelSummary scans all ML results and returns per-label counts with a sample path, plus face stats.
func (s *LocalStore) GetLabelSummary() LabelSummaryResult {
	s.mu.Lock()
	defer s.mu.Unlock()
	var result LabelSummaryResult
	if !s.initialized {
		return result
	}

	rows, err := s.db.Query(`SELECT path, labels, face_ids FROM ml_results WHERE labels != '[]' OR face_ids != '[]'`)
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

// SearchLabels returns paths whose labels or text contain any of the query terms.
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
		rows, err := s.db.Query(`SELECT path FROM ml_results WHERE face_ids != '[]'`)
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
	if len(queryTerms) == 0 {
		return nil
	}

	rows, err := s.db.Query(`SELECT path, labels, text FROM ml_results WHERE labels LIKE '%' || ? || '%' OR text LIKE '%' || ? || '%'`,
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

// GetUnlabeledPaths returns paths from the provided set that lack ML results.
func (s *LocalStore) GetUnlabeledPaths(limit int) []string {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return nil
	}
	// Return paths that have ml_results but no labels yet
	rows, err := s.db.Query(
		`SELECT path FROM ml_results WHERE labels='[]' AND text='' LIMIT ?`, limit)
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
