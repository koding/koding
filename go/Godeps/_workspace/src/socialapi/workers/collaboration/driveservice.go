package collaboration

import (
	"io/ioutil"
	"net/http"
	"socialapi/config"

	"code.google.com/p/goauth2/oauth"
	"code.google.com/p/goauth2/oauth/jwt"
	"code.google.com/p/google-api-go-client/drive/v2"
	"code.google.com/p/google-api-go-client/googleapi"
)

// deleteFile deletes the file from google drive api, if file is not there
// doesnt do anything
func (c *Controller) deleteFile(fileId string) error {
	svc, err := CreateService(&c.conf.GoogleapiServiceAccount)
	if err != nil {
		return err
	}

	// files delete call
	err = svc.Files.Delete(fileId).Do()
	if err != nil {
		if e, ok := err.(*googleapi.Error); ok {
			if e.Code == 404 { // file not found
				return nil
			}
		}
		return err
	}

	return nil
}

// getFile gets the file from google drive api
func (c *Controller) getFile(fileId string) (*drive.File, error) {
	svc, err := CreateService(&c.conf.GoogleapiServiceAccount)
	if err != nil {
		return nil, err
	}

	//get the file
	return svc.Files.Get(fileId).Do()
}

// CreateService creates a service with Server auth enabled system
func CreateService(gs *config.GoogleapiServiceAccount) (*drive.Service, error) {
	// Settings for authorization.
	var configG = &oauth.Config{
		ClientId:     gs.ClientId,
		ClientSecret: gs.ClientSecret,
		Scope:        "https://www.googleapis.com/auth/drive",
		RedirectURL:  "urn:ietf:wg:oauth:2.0:oob",
		AuthURL:      "https://accounts.google.com/o/oauth2/auth",
		TokenURL:     "https://accounts.google.com/o/oauth2/token",
	}

	// Read the pem file bytes for the private key.
	keyBytes, err := ioutil.ReadFile(gs.ServiceAccountKeyFile)
	if err != nil {
		return nil, err
	}

	// Craft the ClaimSet and JWT token.
	t := jwt.NewToken(gs.ServiceAccountEmail, configG.Scope, keyBytes)
	t.ClaimSet.Aud = configG.TokenURL

	// Get the access token.
	o, err := t.Assert(&http.Client{}) // We need to provide a client.
	if err != nil {
		return nil, err
	}

	tr := &oauth.Transport{
		Config:    configG,
		Token:     o,
		Transport: http.DefaultTransport,
	}

	// Create a new authorized Drive client.
	return drive.New(tr.Client())
}
