package main

import (
  "bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"
)

type loginRequest struct {
	ID          string `json:"id"`
	DisplayName string `json:"displayName"`
}

type profile struct {
	ID       string
	Username string
	Email    string
	Bio      string
}

type iconData struct {
	ContentType string
	Bytes       []byte
}

var (
	mu     sync.RWMutex
	users  = map[string]profile{}
	icons  = map[string]iconData{}
)

func main() {
	mux := http.NewServeMux()

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

		mu.Lock()
		if _, ok := users[req.ID]; !ok {
			users[req.ID] = profile{
				ID:       req.ID,
				Username: req.DisplayName,
				Email:    "",
				Bio:      "",
			}
		}
		mu.Unlock()

		writeJSON(w, http.StatusOK, map[string]any{
			"status": "ok",
			"user": map[string]any{
				"id":          req.ID,
				"displayName": req.DisplayName,
			},
		})
	})

	mux.HandleFunc("/me", func(w http.ResponseWriter, r *http.Request) {
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
		if userID == "" {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "user_id is required"})
			return
		}

		mu.RLock()
		p, ok := users[userID]
		_, hasIcon := icons[userID]
		mu.RUnlock()
		if !ok {
			p = profile{ID: userID, Username: userID, Email: "", Bio: ""}
			mu.Lock()
			users[userID] = p
			mu.Unlock()
		}

		iconURL := ""
		if hasIcon {
			iconURL = fmt.Sprintf("http://%s/icons/%s", r.Host, userID)
		}

		writeJSON(w, http.StatusOK, map[string]any{
			"id":       p.ID,
			"username": p.Username,
			"email":    p.Email,
			"icon_url": iconURL,
			"bio":      p.Bio,
		})
	})

	mux.HandleFunc("/update-profile", func(w http.ResponseWriter, r *http.Request) {
		withCORS(w, r)
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		userID := r.URL.Query().Get("user_id")
		if userID == "" {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "user_id is required"})
			return
		}

		if err := r.ParseMultipartForm(20 << 20); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": err.Error()})
			return
		}

		username := r.FormValue("username")
		bio := r.FormValue("bio")

		mu.Lock()
		p, ok := users[userID]
		if !ok {
			p = profile{ID: userID, Username: userID, Email: "", Bio: ""}
		}
		if username != "" {
			p.Username = username
		}
		if bio != "" {
			p.Bio = bio
		}
		users[userID] = p
		mu.Unlock()

		file, header, err := r.FormFile("icon")
		if err == nil {
			defer file.Close()
			buf := new(bytes.Buffer)
			_, _ = buf.ReadFrom(file)
			ct := header.Header.Get("Content-Type")
			if ct == "" {
				ct = http.DetectContentType(buf.Bytes())
			}
			mu.Lock()
			icons[userID] = iconData{ContentType: ct, Bytes: buf.Bytes()}
			mu.Unlock()
		}

		iconURL := ""
		mu.RLock()
		_, hasIcon := icons[userID]
		mu.RUnlock()
		if hasIcon {
			iconURL = fmt.Sprintf("http://%s/icons/%s", r.Host, userID)
		}

		writeJSON(w, http.StatusOK, map[string]any{
			"message":  "profile updated",
			"icon_url": iconURL,
		})
	})

	mux.HandleFunc("/icons/", func(w http.ResponseWriter, r *http.Request) {
		withCORS(w, r)
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		userID := r.URL.Path[len("/icons/"):]
		if userID == "" {
			http.NotFound(w, r)
			return
		}

		mu.RLock()
		ic, ok := icons[userID]
		mu.RUnlock()
		if !ok || len(ic.Bytes) == 0 {
			http.NotFound(w, r)
			return
		}

		w.Header().Set("Content-Type", ic.ContentType)
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(ic.Bytes)
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	addr := ":" + port
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
