package main

import (
	"errors"
	"log"
	"strings"
	"time"

	"koding/kites/kloud/digitalocean"

	"github.com/dgrijalva/jwt-go"
	"github.com/koding/kite"
	"github.com/nu7hatch/gouuid"
)

// Builder is used to create and provisiong a single image or machine for a
// given Provider.
type Builder interface {
	// Prepare is responsible of configuring the builder and validating the
	// given configuration prior Build.
	Prepare(...interface{}) error

	// Build is creating a image and a machine.
	Build(...interface{}) (interface{}, error)
}

type buildArgs struct {
	Provider     string
	SnapshotName string
	Credential   map[string]interface{}
	Builder      map[string]interface{}
}

var (
	defaultSnapshotName = "koding-klient-0.0.1"
	providers           = map[string]interface{}{
		"digitalocean": &digitalocean.DigitalOcean{},
	}
)

func build(r *kite.Request) (interface{}, error) {
	args := &buildArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	p, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	provider, ok := p.(Builder)
	if !ok {
		return nil, errors.New("provider doesn't satisfy the builder interface.")
	}

	if err := provider.Prepare(args.Credential, args.Builder); err != nil {
		return nil, err
	}

	snapshotName := defaultSnapshotName
	if args.SnapshotName != "" {
		snapshotName = args.SnapshotName
	}

	signer := func() (string, error) {
		return createKey(r.Username)
	}

	artifact, err := provider.Build(snapshotName, r.Username, signer)
	if err != nil {
		return nil, err
	}

	return artifact, nil
}

func createKey(username string) (string, error) {
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
