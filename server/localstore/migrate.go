package localstore

import (
	"database/sql"
	"encoding/gob"
	"fmt"
	"os"
	"time"
)

// Old gob types kept only for deserialization during migration.

type gobPhotoEntry struct {
	Path      string
	Filename  string
	Size      int64
	IndexedAt int64
	Labels    []string
	FaceIDs   []string
	Text      string
}

type gobThumbEntry struct {
	Path       string
	CacheFile  string
	Size       int64
	CachedAt   int64
	LastAccess int64
}

type gobIndexData struct {
	Photos         map[string]gobPhotoEntry
	FilenameIndex  map[string][]string
	Thumbs         map[string]gobThumbEntry
	LastFullIndex  int64
	LastSeenMarker string
	ClientID       string
}

func migrateFromGob(gobPath string, db *sql.DB, logger interface{ Printf(string, ...any) }) error {
	f, err := os.Open(gobPath)
	if err != nil {
		return fmt.Errorf("open gob file: %w", err)
	}
	defer f.Close()

	var data gobIndexData
	if err := gob.NewDecoder(f).Decode(&data); err != nil {
		return fmt.Errorf("decode gob: %w", err)
	}

	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback()

	// Migrate meta
	if data.ClientID != "" {
		if _, err := tx.Exec(`INSERT OR REPLACE INTO meta(key,value) VALUES('client_id',?)`, data.ClientID); err != nil {
			return fmt.Errorf("insert client_id: %w", err)
		}
	}
	if _, err := tx.Exec(`INSERT OR REPLACE INTO meta(key,value) VALUES('last_full_index',?)`, fmt.Sprintf("%d", data.LastFullIndex)); err != nil {
		return fmt.Errorf("insert last_full_index: %w", err)
	}
	if _, err := tx.Exec(`INSERT OR REPLACE INTO meta(key,value) VALUES('last_seen_marker',?)`, data.LastSeenMarker); err != nil {
		return fmt.Errorf("insert last_seen_marker: %w", err)
	}

	// Migrate photos
	photoStmt, err := tx.Prepare(`INSERT OR REPLACE INTO photos(path,filename,size,indexed_at,labels,face_ids,text) VALUES(?,?,?,?,?,?,?)`)
	if err != nil {
		return fmt.Errorf("prepare photo insert: %w", err)
	}
	defer photoStmt.Close()

	for _, p := range data.Photos {
		if _, err := photoStmt.Exec(p.Path, p.Filename, p.Size, p.IndexedAt,
			encodeStringSlice(p.Labels), encodeStringSlice(p.FaceIDs), p.Text); err != nil {
			return fmt.Errorf("insert photo %s: %w", p.Path, err)
		}
	}

	// Migrate thumbs
	thumbStmt, err := tx.Prepare(`INSERT OR REPLACE INTO thumbs(path,cache_file,size,cached_at,last_access) VALUES(?,?,?,?,?)`)
	if err != nil {
		return fmt.Errorf("prepare thumb insert: %w", err)
	}
	defer thumbStmt.Close()

	for _, t := range data.Thumbs {
		if _, err := thumbStmt.Exec(t.Path, t.CacheFile, t.Size, t.CachedAt, t.LastAccess); err != nil {
			return fmt.Errorf("insert thumb %s: %w", t.Path, err)
		}
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit migration: %w", err)
	}

	// Backup old file
	backupPath := gobPath + ".migrated"
	if err := os.Rename(gobPath, backupPath); err != nil {
		logger.Printf("Warning: could not rename gob file to %s: %v", backupPath, err)
	}

	now := time.Now().Format("2006-01-02 15:04:05")
	logger.Printf("Gob migration complete at %s: %d photos, %d thumbs migrated", now, len(data.Photos), len(data.Thumbs))
	return nil
}
