package keycreator

import (
	"errors"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/koding/kite/kitekey"
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

	rsaKey, err := jwt.ParseRSAPrivateKeyFromPEM([]byte(k.KontrolPrivateKey))
	if err != nil {
		return "", err
	}

	if k.KontrolPublicKey == "" {
		return "", ErrSignPublicKeyEmpty
	}

	claims := &kitekey.KiteClaims{
		StandardClaims: jwt.StandardClaims{
			Issuer:   "koding",
			Subject:  username,
			IssuedAt: time.Now().UTC().Unix(),
			Id:       kiteId,
		},
		KontrolURL: k.KontrolURL,
		KontrolKey: strings.TrimSpace(k.KontrolPublicKey),
	}

	token := jwt.NewWithClaims(jwt.GetSigningMethod("RS256"), claims)

	return token.SignedString(rsaKey)
}
