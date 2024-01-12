package main

import (
	"log/slog"
	"net/http"
	"os"
	"time"
)

var logger = slog.New(slog.NewJSONHandler(os.Stdout, nil))

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("ok"))
	})
	http.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("pong"))
	})

	logger.Info("listen and serve", slog.Int("port", 80), slog.Time("time", time.Now()))
	if err := http.ListenAndServe(":80", nil); err != nil {
		logger.Error("failed to listen and serve", slog.Time("time", time.Now()), slog.String("error", err.Error()))
		os.Exit(1)
	}
}
