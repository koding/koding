package kloud

import (
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/nu7hatch/gouuid"
)

func createKey(username, kontrolURL, privateKey, publicKey string) (string, string, error) {
	if username == "" {
		return "", "", NewError(ErrSignUsernameEmpty)
	}

	if kontrolURL == "" {
		return "", "", NewError(ErrSignKontrolURLEmpty)
	}

	if privateKey == "" {
		return "", "", NewError(ErrSignPrivateKeyEmpty)
	}

	if publicKey == "" {
		return "", "", NewError(ErrSignPublicKeyEmpty)
	}

	tknID, err := uuid.NewV4()
	if err != nil {
		return "", "", NewError(ErrSignGenerateToken)
	}

	token := jwt.New(jwt.GetSigningMethod("RS256"))

	token.Claims = map[string]interface{}{
		"iss":        "koding",                     // Issuer, should be the same username as kontrol
		"sub":        username,                     // Subject
		"iat":        time.Now().UTC().Unix(),      // Issued At
		"jti":        tknID.String(),               // JWT ID
		"kontrolURL": kontrolURL,                   // Kontrol URL
		"kontrolKey": strings.TrimSpace(publicKey), // Public key of kontrol
	}

	tokenString, err := token.SignedString([]byte(privateKey))
	if err != nil {
		return "", "", err
	}

	return tokenString, tknID.String(), nil
}
