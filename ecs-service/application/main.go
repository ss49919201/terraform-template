package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"time"
)

var logger = slog.New(slog.NewJSONHandler(os.Stdout, nil))

func logMiddleware(next func(http.ResponseWriter, *http.Request)) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		now := time.Now()
		next(w, r)
		logger.Info(
			"received request",
			slog.String("elaspe", fmt.Sprintf("%dns", int(time.Since(now)))),
			slog.String("host", r.Host),
			slog.String("method", r.Method),
			slog.String("url", r.URL.String()),
		)
	}
}

func main() {
	http.HandleFunc("/health", logMiddleware(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("ok"))
	}))
	http.HandleFunc("/ping", logMiddleware(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("pong"))
	}))

	logger.Info("listen and serve", slog.Int("port", 80), slog.Time("time", time.Now()))
	if err := http.ListenAndServe(":80", nil); err != nil {
		logger.Error("failed to listen and serve", slog.Time("time", time.Now()), slog.String("error", err.Error()))
		os.Exit(1)
	}
}
