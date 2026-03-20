package localstore

import "time"

// IsThumbFailed returns true if thumbnail generation has previously failed for path.
func (s *LocalStore) IsThumbFailed(path string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return false
	}
	var failedAt int64
	err := s.db.QueryRow(`SELECT failed_at FROM thumb_failures WHERE path=?`, path).Scan(&failedAt)
	return err == nil && failedAt > 0
}

// MarkThumbFailed records that thumbnail generation failed for path.
func (s *LocalStore) MarkThumbFailed(path string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	s.db.Exec(`INSERT OR REPLACE INTO thumb_failures(path, failed_at) VALUES(?,?)`,
		path, time.Now().Unix())
}

// ClearThumbFailure removes a failure record, e.g. after a client uploads a thumbnail.
func (s *LocalStore) ClearThumbFailure(path string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	s.db.Exec(`DELETE FROM thumb_failures WHERE path=?`, path)
}
