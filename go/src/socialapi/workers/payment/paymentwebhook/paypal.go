package main

import "net/http"

type paypalMux struct{}

func (p *paypalMux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
}
