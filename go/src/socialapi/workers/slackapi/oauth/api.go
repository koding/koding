package api

import (
	"fmt"
	"net/http"

	"golang.org/x/oauth2"
)

type Slack struct {
	OAuthConf *oauth2.Config
}

func (s *Slack) Send(w http.ResponseWriter, req *http.Request) {
	url := s.OAuthConf.AuthCodeURL("state", oauth2.AccessTypeOffline)
	http.Redirect(w, req, url, http.StatusTemporaryRedirect)
}

func (s *Slack) Callback(w http.ResponseWriter, req *http.Request) {

	// state := req.FormValue("state")
	// if state != oauthStateString {
	// 	fmt.Printf("invalid oauth state, expected '%s', got '%s'\n", oauthStateString, state)
	// 	http.Redirect(w, req, "/", http.StatusTemporaryRedirect)
	// 	return
	// }
	code := req.FormValue("code")
	token, err := s.OAuthConf.Exchange(oauth2.NoContext, code)
	if err != nil {
		fmt.Printf("oauthConf.Exchange() failed with '%s'\n", err)
		http.Redirect(w, req, "/", http.StatusTemporaryRedirect)
		return
	}

	fmt.Printf("TOKEN IS: %+v", token)
}
