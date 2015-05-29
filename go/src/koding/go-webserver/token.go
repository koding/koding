package main

import (
	"errors"
	"net/http"
	"time"

	"github.com/dgrijalva/jwt-go"
)

var (
	ErrNoEmailInQuery     = errors.New("no email in query")
	ErrNoTokenInQuery     = errors.New("no token in query")
	ErrTokenNotValid      = errors.New("token not valid")
	ErrNoUsernameInClaims = errors.New("no username in claims")

	// token expires 7 days; can be used numerous times in that period
	tokenExpiresIn = 7 * 24 * time.Hour

	// key used to sign requests
	secretKey = "ac25b4e6009c1b6ba336a3eb17fbc3b7"
)

func validateJWTToken(r *http.Request) (map[string]interface{}, error) {
	tokenStr := r.URL.Query().Get("token")
	if tokenStr == "" {
		return nil, ErrNoTokenInQuery
	}

	token, err := jwt.Parse(tokenStr, tokenKeyFunc)
	if err != nil {
		return nil, err
	}

	// jwt-go library intervally validates if token is expired or not based
	// on `exp` claim encoded in token
	if !token.Valid {
		return nil, ErrTokenNotValid
	}

	username, ok := token.Claims["username"].(string)
	if !ok {
		return nil, ErrNoUsernameInClaims
	}

	if username == "" {
		return nil, ErrNoUsernameInClaims
	}

	return token.Claims, nil
}

func tokenKeyFunc(token *jwt.Token) (interface{}, error) {
	return []byte(secretKey), nil
}
