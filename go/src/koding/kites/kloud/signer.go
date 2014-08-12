package main

import (
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/koding/kloud"
)

// createKey signs a new key and returns the token back
func (k *KodingDeploy) createKey(username, kiteId string) (string, error) {
	if username == "" {
		return "", kloud.NewError(kloud.ErrSignUsernameEmpty)
	}

	if k.KontrolURL == "" {
		return "", kloud.NewError(kloud.ErrSignKontrolURLEmpty)
	}

	if k.KontrolPrivateKey == "" {
		return "", kloud.NewError(kloud.ErrSignPrivateKeyEmpty)
	}

	if k.KontrolPublicKey == "" {
		return "", kloud.NewError(kloud.ErrSignPublicKeyEmpty)
	}

	token := jwt.New(jwt.GetSigningMethod("RS256"))

	token.Claims = map[string]interface{}{
		"iss":         "koding",                              // Issuer, should be the same username as kontrol
		"sub":         username,                              // Subject
		"iat":         time.Now().UTC().Unix(),               // Issued At
		"jti":         kiteId,                                // JWT ID
		"discoverURL": k.DiscoveryURL,                        // Use discovery to search fo a Kontrol URL
		"kontrolURL":  k.KontrolURL,                          // Kontrol URL
		"kontrolKey":  strings.TrimSpace(k.KontrolPublicKey), // Public key of kontrol
	}

	return token.SignedString([]byte(k.KontrolPrivateKey))
}
