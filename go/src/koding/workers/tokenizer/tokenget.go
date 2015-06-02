package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"time"

	"github.com/dgrijalva/jwt-go"
)

func TokenGetHandler(w http.ResponseWriter, r *http.Request) {
	email := r.URL.Query().Get("email")
	if email == "" {
		Log.Error("Request to /mail/get failed: %v", ErrNoEmailInQuery)

		w.WriteHeader(500)
		return
	}

	authkey := r.URL.Query().Get("authkey")
	if authkey == "" || authkey != IterableAuthKey {
		Log.Error("Request to /mail/get failed: %v", ErrNoAuthKeyInQuery)

		w.WriteHeader(500)
		return
	}

	user, err := modelhelper.FetchUserByEmail(email)
	if err != nil {
		Log.Error("Request to /mail/get failed: %v", err)

		w.WriteHeader(500)
		return
	}

	now := time.Now()

	token := jwt.New(jwt.SigningMethodHS256)
	token.Claims = map[string]interface{}{
		"username": user.Name,
		"iat":      now.Unix(),
		"exp":      now.Add(tokenExpiresIn).Unix(),
	}

	tokenStr, err := token.SignedString([]byte(SecretMailSigningKey))
	if err != nil {
		Log.Error("Request to /mail/get failed: %s", err.Error())

		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(fmt.Sprintf(`{"token":"%s"}`, tokenStr)))
}
