package resolver

import (
	"context"
	"net"
	"testing"
	"time"
)

func TestDoHResolve(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	ips, err := dohResolve(ctx, "drive.aiaas.dev")
	if err != nil {
		t.Fatalf("dohResolve failed: %v", err)
	}
	if len(ips) == 0 {
		t.Fatal("dohResolve returned no IPs")
	}
	for _, ip := range ips {
		if net.ParseIP(ip) == nil {
			t.Errorf("invalid IP: %s", ip)
		}
	}
	t.Logf("Resolved drive.aiaas.dev to: %v", ips)
}

func TestDoHResolveCache(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// First call populates cache
	ips1, err := dohResolve(ctx, "google.com")
	if err != nil {
		t.Fatalf("first resolve failed: %v", err)
	}

	// Second call should use cache
	ips2, err := dohResolve(ctx, "google.com")
	if err != nil {
		t.Fatalf("cached resolve failed: %v", err)
	}
	if len(ips1) != len(ips2) {
		t.Errorf("cache returned different results: %v vs %v", ips1, ips2)
	}
}

func TestDoHDialContext(t *testing.T) {
	dialer := &net.Dialer{Timeout: 10 * time.Second}
	dialFn := NewDoHDialContext(dialer)

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	conn, err := dialFn(ctx, "tcp", "drive.aiaas.dev:443")
	if err != nil {
		t.Fatalf("DoH dial failed: %v", err)
	}
	conn.Close()
	t.Log("Successfully connected to drive.aiaas.dev:443 via DoH")
}

func TestDoHResolveFallback(t *testing.T) {
	// Save original servers and restore after test
	origServers := dohServers
	defer func() { dohServers = origServers }()

	// Clear cache to force fresh resolution
	cache.mu.Lock()
	delete(cache.entries, "example.com")
	cache.mu.Unlock()

	// Set primary to an unreachable server so it must fall back to Google
	dohServers = []string{
		"https://192.0.2.1/dns-query", // RFC 5737 TEST-NET, will timeout
		"https://8.8.8.8/dns-query",   // Google DoH fallback
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	ips, err := dohResolve(ctx, "example.com")
	if err != nil {
		t.Fatalf("fallback resolve failed: %v", err)
	}
	if len(ips) == 0 {
		t.Fatal("fallback returned no IPs")
	}
	t.Logf("Resolved example.com via fallback to: %v", ips)
}
