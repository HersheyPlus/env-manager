package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	fmt.Println("🚀 Starting env-manager server...")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello from env-manager! 🔐")
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok","service":"env-manager"}`)
	})

	port := "8080"
	fmt.Printf("🌟 Server running on port %s\n", port)

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal("❌ Server failed:", err)
	}
}
