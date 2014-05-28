package kloud

import (
	"errors"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/nu7hatch/gouuid"
)

func createKey(username, kontrolURL, privateKey, publicKey string) (string, string, error) {
	if username == "" {
		return "", "", errors.New("username is empty")
	}

	if kontrolURL == "" {
		return "", "", errors.New("kontrolURL is empty")
	}

	if privateKey == "" {
		return "", "", errors.New("privateKey is empty")
	}

	if publicKey == "" {
		return "", "", errors.New("publicKey is empty")
	}

	tknID, err := uuid.NewV4()
	if err != nil {
		return "", "", errors.New("cannot generate a token")
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
