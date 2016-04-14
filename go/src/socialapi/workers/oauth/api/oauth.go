package main

import (
	"fmt"
	"net/http"

	"github.com/RangelReale/osincli"
)

func main() {
	config := &osincli.ClientConfig{
		ClientId:                 "koding_client_id",
		ClientSecret:             "koding_secret",
		AuthorizeUrl:             "http://dev.koding.com:8090/api/social/oauth/authorize",
		TokenUrl:                 "http://dev.koding.com:8090/api/social/oauth/token",
		RedirectUrl:              "http://dev.koding.com:8090/api/social/oauth/callback",
		ErrorsInStatusCode:       true,
		SendClientSecretInParams: true,
		Scope: "user_role",
	}
	client, err := osincli.NewClient(config)
	if err != nil {
		panic(err)
	}

	// create a new request to generate the url
	areq := client.NewAuthorizeRequest(osincli.CODE)
	areq.CustomParameters["access_type"] = "online"
	areq.CustomParameters["approval_prompt"] = "auto"

	// Home
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		u := areq.GetAuthorizeUrl()
		w.Write([]byte(fmt.Sprintf("<a href=\"%s\">Login</a>", u.String())))
	})

	// Auth endpoint
	http.HandleFunc("/appauth", func(w http.ResponseWriter, r *http.Request) {
		// parse a token request
		if areqdata, err := areq.HandleRequest(r); err == nil {
			treq := client.NewAccessRequest(osincli.AUTHORIZATION_CODE, areqdata)

			// exchange the authorize token for the access token
			ad, er := treq.GetToken()
			if er == nil {
				w.Write([]byte(fmt.Sprintf("Access token: %+v\n\n", ad)))

				// use the token in ad.AccessToken
			} else {
				w.Write([]byte(fmt.Sprintf("ERROR: %s\n", err)))
			}
		} else {
			w.Write([]byte(fmt.Sprintf("ERROR: %s\n", err)))
		}
	})

	http.ListenAndServe(":8090", nil)

}
