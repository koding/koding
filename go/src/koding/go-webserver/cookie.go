package main

import (
	"errors"
	"net/http"
	"time"
)

func getCookie(w http.ResponseWriter, r *http.Request) (*http.Cookie, error) {
	cookie, err := r.Cookie("clientId")
	if err != nil {
		return nil, err
	}

	if cookie.Value == "" {
		expireClientId(w, r)
		return nil, errors.New("clientId cookie value is empty")
	}

	return cookie, nil
}

func expireClientId(w http.ResponseWriter, r *http.Request) {
	cookie, err := r.Cookie("clientId")
	if err != nil {
		return
	}

	cookie.Expires = time.Now()
	http.SetCookie(w, cookie)
}
