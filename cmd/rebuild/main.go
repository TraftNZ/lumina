package main

import (
	"fmt"
	"log"
	"os"

	"github.com/studio-b12/gowebdav"
)

func main() {
	url := os.Getenv("WEBDAV_URL")
	user := os.Getenv("WEBDAV_USERNAME")
	pass := os.Getenv("WEBDAV_PASSWORD")

	cli := gowebdav.NewClient(url, user, pass)
	infos, err := cli.ReadDir("/")
	if err != nil {
		log.Fatalf("Failed to list root: %v", err)
	}
	fmt.Println("Root directory contents:")
	for _, info := range infos {
		kind := "   "
		if info.IsDir() {
			kind = "DIR"
		}
		fmt.Printf("  %s  %-50s  %d bytes\n", kind, info.Name(), info.Size())
	}
}
