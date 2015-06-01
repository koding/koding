package main

import (
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/dgrijalva/jwt-go"
)

var (
	ErrNoEmailInQuery     = errors.New("no email in query")
	ErrNoTokenInQuery     = errors.New("no token in query")
	ErrNoAuthKeyInQuery   = errors.New("no auth key in query")
	ErrTokenNotValid      = errors.New("token not valid")
	ErrNoUsernameInClaims = errors.New("no username in claims")

	// token expires 7 days; can be used numerous times in that period
	tokenExpiresIn = 7 * 24 * time.Hour
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

	// jwt-go library internally validates if token is expired or not based
	// on `exp` claim encoded in token, in addition to other validations
	if !token.Valid {
		return nil, ErrTokenNotValid
	}

	username, ok := token.Claims["username"].(string)
	if !ok || username == "" {
		return nil, ErrNoUsernameInClaims
	}

	return token.Claims, nil
}

func tokenKeyFunc(token *jwt.Token) (interface{}, error) {
	if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
		return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
	}

	return []byte(Jwttoken), nil
}
