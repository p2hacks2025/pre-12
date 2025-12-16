package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"
	"time"
)

type loginRequest struct {
	ID          string `json:"id"`
	DisplayName string `json:"displayName"`
}

type work struct {
	ID          string `json:"id"`
	UserID      string `json:"user_id"`
	Username    string `json:"username"`
	IconURL     string `json:"icon_url"`
	ImageURL    string `json:"image_url"`
	Title       string `json:"title"`
	Description string `json:"description"`
	CreatedAt   string `json:"created_at"`
}

type swipeRequest struct {
	FromUserID string `json:"from_user_id"`
	ToWorkID   string `json:"to_work_id"`
	IsLike     bool   `json:"is_like"`
}

type swipeLog struct {
	At         string `json:"at"`
	FromUserID string `json:"from_user_id"`
	ToWorkID   string `json:"to_work_id"`
	IsLike     bool   `json:"is_like"`
}

type store struct {
	mu sync.Mutex

	works []work
	// swipes[fromUserID][toWorkID] = isLike
	swipes map[string]map[string]bool
	logs   []swipeLog
}

func main() {
	mux := http.NewServeMux()

	s := &store{
		works:  seedWorks(),
		swipes: make(map[string]map[string]bool),
		logs:   make([]swipeLog, 0, 256),
	}

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		withCORS(w, r)
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"status": "ok"})
	})

	mux.HandleFunc("/login", func(w http.ResponseWriter, r *http.Request) {
		withCORS(w, r)
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var req loginRequest
		dec := json.NewDecoder(r.Body)
		dec.DisallowUnknownFields()
		if err := dec.Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": err.Error()})
			return
		}
		if req.ID == "" || req.DisplayName == "" {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "id/displayName is required"})
			return
		}

		writeJSON(w, http.StatusOK, map[string]any{
			"status": "ok",
			"user": map[string]any{
				"id":          req.ID,
				"displayName": req.DisplayName,
			},
		})
	})

	// GET /works?user_id=... -> []work
	mux.HandleFunc("/works", func(w http.ResponseWriter, r *http.Request) {
		withCORS(w, r)
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		userID := r.URL.Query().Get("user_id")
		items := s.getWorksFor(userID, 10)
		writeJSON(w, http.StatusOK, items)
	})

	// POST /swipes (spec) / POST /swipe (current backend) -> { message: "..." }
	postSwipe := func(w http.ResponseWriter, r *http.Request) {
		withCORS(w, r)
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var req swipeRequest
		dec := json.NewDecoder(r.Body)
		dec.DisallowUnknownFields()
		if err := dec.Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": err.Error()})
			return
		}
		if req.FromUserID == "" || req.ToWorkID == "" {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "from_user_id/to_work_id is required"})
			return
		}

		s.recordSwipe(req)
		writeJSON(w, http.StatusOK, map[string]any{"message": "swipe saved"})
	}
	mux.HandleFunc("/swipes", postSwipe)
	mux.HandleFunc("/swipe", postSwipe)

	// デバッグ用: 受信したswipeを確認
	mux.HandleFunc("/debug/swipes", func(w http.ResponseWriter, r *http.Request) {
		withCORS(w, r)
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		writeJSON(w, http.StatusOK, s.getLogs())
	})

	addr := ":" + envOrDefault("PORT", "8080")
	log.Printf("mock backend listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}

func withCORS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func envOrDefault(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func seedWorks() []work {
	// Flutter 側で assets/ も表示できるので、image_url は assets パスにしておく。
	// created_at は RFC3339 形式。
	now := time.Now()
	items := make([]work, 0, 12)
	for i := 1; i <= 12; i++ {
		items = append(items, work{
			ID:          fmt.Sprintf("work_%05d", i),
			UserID:      fmt.Sprintf("user_%03d", 100+i),
			Username:    fmt.Sprintf("ダミーユーザー%02d", i),
			IconURL:     "",
			ImageURL:    fmt.Sprintf("assets/works/work_%02d.jpg", ((i-1)%4)+1),
			Title:       fmt.Sprintf("ダミー作品 %02d", i),
			Description: "モックサーバから取得した作品です（スワイプでPOSTも確認できます）",
			CreatedAt:   now.Add(-time.Duration(i) * time.Hour).UTC().Format(time.RFC3339),
		})
	}
	return items
}

func (s *store) recordSwipe(req swipeRequest) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.swipes[req.FromUserID] == nil {
		s.swipes[req.FromUserID] = make(map[string]bool)
	}
	s.swipes[req.FromUserID][req.ToWorkID] = req.IsLike

	entry := swipeLog{
		At:         time.Now().UTC().Format(time.RFC3339Nano),
		FromUserID: req.FromUserID,
		ToWorkID:   req.ToWorkID,
		IsLike:     req.IsLike,
	}
	s.logs = append(s.logs, entry)
	log.Printf("swipe received: from=%s to_work=%s is_like=%v", req.FromUserID, req.ToWorkID, req.IsLike)
}

func (s *store) getWorksFor(userID string, limit int) []work {
	s.mu.Lock()
	defer s.mu.Unlock()

	seen := map[string]bool{}
	if userID != "" {
		if m := s.swipes[userID]; m != nil {
			for k := range m {
				seen[k] = true
			}
		}
	}

	out := make([]work, 0, limit)
	for _, w := range s.works {
		if len(out) >= limit {
			break
		}
		if userID != "" && w.UserID == userID {
			continue
		}
		if seen[w.ID] {
			continue
		}
		out = append(out, w)
	}
	return out
}

func (s *store) getLogs() []swipeLog {
	s.mu.Lock()
	defer s.mu.Unlock()

	out := make([]swipeLog, len(s.logs))
	copy(out, s.logs)
	return out
}
