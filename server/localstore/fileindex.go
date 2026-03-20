package localstore

import "time"

type RemoteFile struct {
	Path    string
	Size    int64
	ModTime time.Time
}

func (s *LocalStore) UpsertRemoteFile(path string, size int64, modTime time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.initialized {
		return
	}
	s.db.Exec(
		`INSERT INTO remote_files(path, size, mod_time) VALUES(?,?,?)
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
		`INSERT INTO remote_files(path, size, mod_time) VALUES(?,?,?)
		 ON CONFLICT(path) DO UPDATE SET size=excluded.size, mod_time=excluded.mod_time`,
	)
	if err != nil {
		tx.Rollback()
		s.logger.Printf("prepare stmt: %v", err)
		return
	}
	defer stmt.Close()
	for _, f := range files {
		stmt.Exec(f.Path, f.Size, f.ModTime.Unix())
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
	rows, err := s.db.Query(`SELECT path, size, mod_time FROM remote_files ORDER BY path DESC`)
	if err != nil {
		s.logger.Printf("list remote files: %v", err)
		return nil
	}
	defer rows.Close()
	var files []RemoteFile
	for rows.Next() {
		var f RemoteFile
		var modUnix int64
		if err := rows.Scan(&f.Path, &f.Size, &modUnix); err != nil {
			continue
		}
		f.ModTime = time.Unix(modUnix, 0)
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
