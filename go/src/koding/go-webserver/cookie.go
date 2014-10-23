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
		expireCookie(w, cookie)
		return nil, errors.New("clientId cookie value is empty")
	}

	return cookie, nil
}

func expireCookie(w http.ResponseWriter, cookie *http.Cookie) {
	cookie.Expires = time.Now()
	http.SetCookie(w, cookie)
}
