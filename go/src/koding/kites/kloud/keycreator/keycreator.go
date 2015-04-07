package keycreator

import (
	"errors"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
)

var (
	ErrSignUsernameEmpty   = errors.New("Username is empty")
	ErrSignKontrolURLEmpty = errors.New("Kontrol URL is empty")
	ErrSignPrivateKeyEmpty = errors.New("Private key is empty")
	ErrSignPublicKeyEmpty  = errors.New("Public key is empty")
)

type Key struct {
	KontrolURL        string
	KontrolPrivateKey string
	KontrolPublicKey  string
}

// Create signs a new key and returns the token back
func (k *Key) Create(username, kiteId string) (string, error) {
	if username == "" {
		return "", ErrSignUsernameEmpty
	}

	if k.KontrolURL == "" {
		return "", ErrSignKontrolURLEmpty
	}

	if k.KontrolPrivateKey == "" {
		return "", ErrSignPrivateKeyEmpty
	}

	if k.KontrolPublicKey == "" {
		return "", ErrSignPublicKeyEmpty
	}

	token := jwt.New(jwt.GetSigningMethod("RS256"))

	token.Claims = map[string]interface{}{
		"iss":        "koding",                              // Issuer, should be the same username as kontrol
		"sub":        username,                              // Subject
		"iat":        time.Now().UTC().Unix(),               // Issued At
		"jti":        kiteId,                                // JWT ID
		"kontrolURL": k.KontrolURL,                          // Kontrol URL
		"kontrolKey": strings.TrimSpace(k.KontrolPublicKey), // Public key of kontrol
	}

	return token.SignedString([]byte(k.KontrolPrivateKey))
}
