package main

import "net/http"

type stripeMux struct{}

func (s *stripeMux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
}
