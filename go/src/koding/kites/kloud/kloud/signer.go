package kloud

import (
	"errors"
	"log"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/nu7hatch/gouuid"
)

type signer func() (string, error)

func createKey(username, kontrolURL, privateKey, publicKey string) (string, error) {
	if username == "" {
		return "", errors.New("username is empty")
	}

	if kontrolURL == "" {
		return "", errors.New("kontrolURL is empty")
	}

	if privateKey == "" {
		return "", errors.New("privateKey is empty")
	}

	if publicKey == "" {
		return "", errors.New("publicKey is empty")
	}

	tknID, err := uuid.NewV4()
	if err != nil {
		return "", errors.New("cannot generate a token")
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

	log.Printf("Registered machine on user: %s", username)

	return token.SignedString([]byte(privateKey))
}
