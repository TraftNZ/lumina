package resolver

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"sync"
	"time"
)

// dohResponse represents the JSON response from a DoH API.
type dohResponse struct {
	Status int `json:"Status"`
	Answer []struct {
		Type int    `json:"type"`
		Data string `json:"data"`
	} `json:"Answer"`
}

type dnsCache struct {
	mu      sync.RWMutex
	entries map[string]dnsCacheEntry
}

type dnsCacheEntry struct {
	ips       []string
	expiresAt time.Time
}

var cache = &dnsCache{entries: make(map[string]dnsCacheEntry)}

func (c *dnsCache) get(host string) ([]string, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	entry, ok := c.entries[host]
	if !ok || time.Now().After(entry.expiresAt) {
		return nil, false
	}
	return entry.ips, true
}

func (c *dnsCache) set(host string, ips []string, ttl time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.entries[host] = dnsCacheEntry{ips: ips, expiresAt: time.Now().Add(ttl)}
}

// dohServers lists DoH endpoints to try in order.
// Cloudflare (1.1.1.1) is primary, Google (8.8.8.8) is fallback.
var dohServers = []string{
	"https://1.1.1.1/dns-query",
	"https://8.8.8.8/dns-query",
}

// dohClient is a dedicated HTTP client for DoH requests.
// It dials by IP directly so it never needs DNS itself.
var dohClient = &http.Client{
	Timeout: 10 * time.Second,
	Transport: &http.Transport{
		DialContext: (&net.Dialer{Timeout: 5 * time.Second}).DialContext,
	},
}

// dohResolveWith resolves a hostname via a single DoH server endpoint.
func dohResolveWith(ctx context.Context, server, host string) ([]string, error) {
	url := fmt.Sprintf("%s?name=%s&type=A", server, host)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/dns-json")

	resp, err := dohClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("DoH request to %s failed: %w", server, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("DoH %s returned status %d", server, resp.StatusCode)
	}

	var result dohResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("DoH decode error: %w", err)
	}

	var ips []string
	for _, ans := range result.Answer {
		if ans.Type == 1 { // A record
			ips = append(ips, ans.Data)
		}
	}
	if len(ips) == 0 {
		return nil, fmt.Errorf("DoH: no A records for %s", host)
	}

	return ips, nil
}

// dohResolve resolves a hostname via DNS-over-HTTPS, trying Cloudflare first
// and falling back to Google if Cloudflare fails.
func dohResolve(ctx context.Context, host string) ([]string, error) {
	if ips, ok := cache.get(host); ok {
		return ips, nil
	}

	var lastErr error
	for _, server := range dohServers {
		ips, err := dohResolveWith(ctx, server, host)
		if err != nil {
			lastErr = err
			continue
		}
		cache.set(host, ips, 5*time.Minute)
		return ips, nil
	}

	return nil, fmt.Errorf("all DoH servers failed for %s: %w", host, lastErr)
}

// NewDoHDialContext returns a DialContext function that resolves hostnames
// via DNS-over-HTTPS before connecting. This works on Android where direct
// DNS queries (UDP/TCP port 53) are blocked for unprivileged apps.
func NewDoHDialContext(dialer *net.Dialer) func(ctx context.Context, network, addr string) (net.Conn, error) {
	return func(ctx context.Context, network, addr string) (net.Conn, error) {
		host, port, err := net.SplitHostPort(addr)
		if err != nil {
			return dialer.DialContext(ctx, network, addr)
		}
		if ip := net.ParseIP(host); ip != nil {
			return dialer.DialContext(ctx, network, addr)
		}
		ips, err := dohResolve(ctx, host)
		if err != nil {
			return nil, fmt.Errorf("DNS resolution for %s failed: %w", host, err)
		}
		var lastErr error
		for _, ip := range ips {
			conn, err := dialer.DialContext(ctx, network, net.JoinHostPort(ip, port))
			if err == nil {
				return conn, nil
			}
			lastErr = err
		}
		return nil, fmt.Errorf("all IPs for %s failed: %w", host, lastErr)
	}
}
