package localstore

import "time"

const (
	// A recorded failure suppresses further attempts for a window that widens
	// with each consecutive failure. Most failures are transient — a cloud
	// backend that has not finished generating the thumbnail for a just-uploaded
	// file — and resolve within seconds, while a format nothing can render must
	// not cost a request on every scroll.
	thumbRetryBaseDelay = 30 * time.Second
	thumbRetryMaxDelay  = 24 * time.Hour
	// Bounds the shift below; the cap is reached well before this.
	thumbRetryMaxAttempts = 12
)

// thumbRetryDelay returns how long a path stays suppressed after the given
// number of consecutive failures.
func thumbRetryDelay(attempts int64) time.Duration {
	if attempts < 1 {
		attempts = 1
	}
	if attempts > thumbRetryMaxAttempts {
		attempts = thumbRetryMaxAttempts
	}
	delay := thumbRetryBaseDelay << (attempts - 1)
	if delay > thumbRetryMaxDelay {
		return thumbRetryMaxDelay
	}
	return delay
}

// IsThumbFailed reports whether thumbnail generation for path failed recently
// enough that retrying now would very likely fail again.
func (s *LocalStore) IsThumbFailed(path string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return false
	}
	var failedAt, attempts int64
	err := s.db.QueryRow(`SELECT failed_at, attempts FROM thumb_failures WHERE path=?`, path).
		Scan(&failedAt, &attempts)
	if err != nil || failedAt <= 0 {
		return false
	}
	return time.Since(time.Unix(failedAt, 0)) < thumbRetryDelay(attempts)
}

// MarkThumbFailed records that thumbnail generation failed for path, extending
// the backoff window each time it is called for the same path.
func (s *LocalStore) MarkThumbFailed(path string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	s.db.Exec(`INSERT INTO thumb_failures(path, failed_at, attempts) VALUES(?,?,1)
		ON CONFLICT(path) DO UPDATE SET failed_at=excluded.failed_at, attempts=attempts+1`,
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
