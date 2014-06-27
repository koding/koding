package kloud

import (
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
)

// createKey signs a new key and returns the token back
func (k *Kloud) createKey(username, kiteId string) (string, error) {
	if username == "" {
		return "", NewError(ErrSignUsernameEmpty)
	}

	if k.KontrolURL == "" {
		return "", NewError(ErrSignKontrolURLEmpty)
	}

	if k.KontrolPrivateKey == "" {
		return "", NewError(ErrSignPrivateKeyEmpty)
	}

	if k.KontrolPublicKey == "" {
		return "", NewError(ErrSignPublicKeyEmpty)
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
