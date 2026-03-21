package localstore

import (
	"fmt"
	"strings"
	"time"
)

type RemoteFile struct {
	Path      string
	Size      int64
	ModTime   time.Time
	TakenAt   time.Time
	Latitude  float64
	Longitude float64
}

func (s *LocalStore) UpsertRemoteFile(path string, size int64, modTime time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	s.db.Exec(
		`INSERT INTO remote_files(path, size, mod_time, taken_at, latitude, longitude) VALUES(?,?,?,0,0,0)
		 ON CONFLICT(path) DO UPDATE SET size=excluded.size, mod_time=excluded.mod_time`,
		path, size, modTime.Unix(),
	)
}

func (s *LocalStore) UpsertRemoteFiles(files []RemoteFile) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized || len(files) == 0 {
		return
	}
	tx, err := s.db.Begin()
	if err != nil {
		s.logger.Printf("begin tx: %v", err)
		return
	}
	stmt, err := tx.Prepare(
		`INSERT INTO remote_files(path, size, mod_time, taken_at, latitude, longitude) VALUES(?,?,?,?,?,?)
		 ON CONFLICT(path) DO UPDATE SET size=excluded.size, mod_time=excluded.mod_time,
		 taken_at=excluded.taken_at, latitude=excluded.latitude, longitude=excluded.longitude`,
	)
	if err != nil {
		tx.Rollback()
		s.logger.Printf("prepare stmt: %v", err)
		return
	}
	defer stmt.Close()
	for _, f := range files {
		var takenUnix int64
		if !f.TakenAt.IsZero() {
			takenUnix = f.TakenAt.Unix()
		}
		stmt.Exec(f.Path, f.Size, f.ModTime.Unix(), takenUnix, f.Latitude, f.Longitude)
	}
	tx.Commit()
}

func (s *LocalStore) RemoveRemoteFile(path string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	s.db.Exec(`DELETE FROM remote_files WHERE path=?`, path)
}

func (s *LocalStore) RemoveRemoteFiles(paths []string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized || len(paths) == 0 {
		return
	}
	tx, err := s.db.Begin()
	if err != nil {
		return
	}
	stmt, err := tx.Prepare(`DELETE FROM remote_files WHERE path=?`)
	if err != nil {
		tx.Rollback()
		return
	}
	defer stmt.Close()
	for _, p := range paths {
		stmt.Exec(p)
	}
	tx.Commit()
}

func (s *LocalStore) ListRemoteFiles() []RemoteFile {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return nil
	}
	rows, err := s.db.Query(`SELECT path, size, mod_time, taken_at, latitude, longitude FROM remote_files ORDER BY path DESC`)
	if err != nil {
		s.logger.Printf("list remote files: %v", err)
		return nil
	}
	defer rows.Close()
	var files []RemoteFile
	for rows.Next() {
		var f RemoteFile
		var modUnix, takenUnix int64
		if err := rows.Scan(&f.Path, &f.Size, &modUnix, &takenUnix, &f.Latitude, &f.Longitude); err != nil {
			continue
		}
		f.ModTime = time.Unix(modUnix, 0)
		if takenUnix > 0 {
			f.TakenAt = time.Unix(takenUnix, 0)
		}
		files = append(files, f)
	}
	return files
}

func (s *LocalStore) GetLastIndexedDate() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return ""
	}
	return s.getMeta("last_indexed_date")
}

func (s *LocalStore) SetLastIndexedDate(date string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	s.setMeta("last_indexed_date", date)
}

func (s *LocalStore) ClearRemoteFiles() {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	s.db.Exec(`DELETE FROM remote_files`)
	s.setMeta("last_indexed_date", "")
}

type YearSummary struct {
	Year       int
	Count      int
	SamplePath string
}

func (s *LocalStore) GetYearSummary() []YearSummary {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return nil
	}
	rows, err := s.db.Query(`
		SELECT
			CAST(CASE WHEN taken_at > 0 THEN strftime('%Y', taken_at, 'unixepoch')
			     ELSE substr(path, 1, 4) END AS INTEGER) AS year,
			COUNT(*) AS cnt,
			MIN(path) AS sample_path
		FROM remote_files
		GROUP BY year
		ORDER BY year DESC`)
	if err != nil {
		s.logger.Printf("get year summary: %v", err)
		return nil
	}
	defer rows.Close()
	var result []YearSummary
	for rows.Next() {
		var ys YearSummary
		if err := rows.Scan(&ys.Year, &ys.Count, &ys.SamplePath); err != nil {
			continue
		}
		if ys.Year >= 1990 && ys.Year <= 2100 {
			result = append(result, ys)
		}
	}
	return result
}

func (s *LocalStore) GetPhotosByYear(year, offset, limit int) ([]string, int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return nil, 0
	}
	yearStr := fmt.Sprintf("%d", year)
	var total int
	s.db.QueryRow(`
		SELECT COUNT(*) FROM remote_files
		WHERE CASE WHEN taken_at > 0 THEN strftime('%Y', taken_at, 'unixepoch')
		      ELSE substr(path, 1, 4) END = ?`, yearStr).Scan(&total)

	rows, err := s.db.Query(`
		SELECT path FROM remote_files
		WHERE CASE WHEN taken_at > 0 THEN strftime('%Y', taken_at, 'unixepoch')
		      ELSE substr(path, 1, 4) END = ?
		ORDER BY path DESC
		LIMIT ? OFFSET ?`, yearStr, limit, offset)
	if err != nil {
		return nil, total
	}
	defer rows.Close()
	var paths []string
	for rows.Next() {
		var p string
		if err := rows.Scan(&p); err != nil {
			continue
		}
		paths = append(paths, p)
	}
	return paths, total
}

func (s *LocalStore) GetPhotosWithLocation() []RemoteFile {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return nil
	}
	rows, err := s.db.Query(`
		SELECT path, size, mod_time, taken_at, latitude, longitude
		FROM remote_files
		WHERE latitude != 0 AND longitude != 0
		ORDER BY path DESC`)
	if err != nil {
		s.logger.Printf("get photos with location: %v", err)
		return nil
	}
	defer rows.Close()
	var files []RemoteFile
	for rows.Next() {
		var f RemoteFile
		var modUnix, takenUnix int64
		if err := rows.Scan(&f.Path, &f.Size, &modUnix, &takenUnix, &f.Latitude, &f.Longitude); err != nil {
			continue
		}
		f.ModTime = time.Unix(modUnix, 0)
		if takenUnix > 0 {
			f.TakenAt = time.Unix(takenUnix, 0)
		}
		files = append(files, f)
	}
	return files
}

func ParseDateFromPath(p string) time.Time {
	parts := strings.SplitN(p, "/", 4)
	if len(parts) >= 3 {
		t, _ := time.Parse("2006/01/02", parts[0]+"/"+parts[1]+"/"+parts[2])
		return t
	}
	return time.Time{}
}

func (s *LocalStore) CountRemoteFiles() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return 0
	}
	var count int
	s.db.QueryRow(`SELECT COUNT(*) FROM remote_files`).Scan(&count)
	return count
}
