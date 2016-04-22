package api

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"log"
	"net/http"

	"github.com/RangelReale/osin"
	"github.com/kr/pretty"
)

var (
	ErrClientIdNotFound    = errors.New("client id is not found")
	ErrCookieValueNotFound = errors.New("cookie value is not found")
	ErrSessionNotFound     = errors.New("session is not found")
)

type Oauth struct {
	sconfig *osin.ServerConfig
	server  *osin.Server
	Storage osin.Storage
}

func (o *Oauth) AuthorizeClient(w http.ResponseWriter, r *http.Request) {
	server := o.server
	resp := server.NewResponse()
	defer resp.Close()

	if ar := server.HandleAuthorizeRequest(resp, r); ar != nil {

		session := HandleLoginPage(ar, w, r)
		if session == nil {
			return
		}

		// ~to-do , needs to be added users data
		ar.UserData = session.Username
		ar.Authorized = true
		server.FinishAuthorizeRequest(resp, r, ar)

	}
	if resp.IsError && resp.InternalError != nil {
		fmt.Printf("resp %# v", pretty.Formatter(resp))
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	if !resp.IsError {
		resp.Output["custom_parameter"] = 199231234
		// return
	}
	if err := osin.OutputJSON(resp, w, r); err != nil {
		log.Fatalf("osing output error: %s", err.Error())
	}
}

func HandleLoginPage(ar *osin.AuthorizeRequest, w http.ResponseWriter, r *http.Request) *models.Session {
	session, err := getSession(r)
	if err != nil || session == nil {
		w.Header().Set("Location", "/Login")
		w.WriteHeader(http.StatusTemporaryRedirect)
		return nil
	}

	return session
}

func (o *Oauth) GenerateToken(w http.ResponseWriter, r *http.Request) {
	server := o.server
	resp := server.NewResponse()
	defer resp.Close()

	if ar := server.HandleAccessRequest(resp, r); ar != nil {
		switch ar.Type {
		case osin.AUTHORIZATION_CODE:
			ar.Authorized = true
		case osin.REFRESH_TOKEN:
			ar.Authorized = true
		case osin.CLIENT_CREDENTIALS:
			ar.Authorized = true
		}
		server.FinishAccessRequest(resp, r, ar)
	}
	fmt.Printf("resp %# v", pretty.Formatter(resp))
	if resp.IsError && resp.InternalError != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	if !resp.IsError {
		resp.Output["custom_parameter"] = 19923
		// return
	}
	if err := osin.OutputJSON(resp, w, r); err != nil {
		log.Fatalf("osing output error: %s", err.Error())
	}
}

func (o *Oauth) Info(w http.ResponseWriter, r *http.Request) {
	server := o.server
	resp := server.NewResponse()
	defer resp.Close()

	if ir := server.HandleInfoRequest(resp, r); ir != nil {
		server.FinishInfoRequest(resp, r, ir)
	}

	osin.OutputJSON(resp, w, r)
}

///// TEST FOR OAUTH SERVER ////
//
// config := &osincli.ClientConfig{
// 	ClientId:     "koding_client_id",
// 	ClientSecret: "koding_secret",
// 	AuthorizeUrl: "http://dev.koding.com:8090/api/social/oauth/authorize",
// 	TokenUrl:     "http://dev.koding.com:8090/api/social/oauth/token",
// 	// RedirectUrl:              "http://dev.koding.com:8090/api/social/oauth/callback",
// 	RedirectUrl:              "http://dev.koding.com:8090/api/social/appauth",
// 	ErrorsInStatusCode:       true,
// 	SendClientSecretInParams: true,
// 	Scope: "user_role",
// }
//
// func (o *Oauth) Callback(w http.ResponseWriter, r *http.Request) {
// 	client, err := osincli.NewClient(config)
// 	if err != nil {
// 		panic(err)
// 	}
//
// 	areq := client.NewAuthorizeRequest(osincli.CODE)
//
// 	if areqdata, err := areq.HandleRequest(r); err == nil {
// 		treq := client.NewAccessRequest(osincli.AUTHORIZATION_CODE, areqdata)
//
// 		// exchange the authorize token for the access token
// 		ad, er := treq.GetToken()
// 		if er == nil {
// 			w.Write([]byte(fmt.Sprintf("Access token: %+v\n\n", ad)))
//
// 			// use the token in ad.AccessToken
// 		} else {
// 			w.Write([]byte(fmt.Sprintf("ERROR: %s\n", err)))
// 		}
// 	} else {
// 		w.Write([]byte(fmt.Sprintf("ERROR: %s\n", err)))
// 	}
//
// }

func getSession(r *http.Request) (*models.Session, error) {
	cookie, err := r.Cookie("clientId")
	if err != nil {
		return nil, ErrClientIdNotFound
	}

	if cookie.Value == "" {
		return nil, ErrCookieValueNotFound
	}

	session, err := modelhelper.GetSession(cookie.Value)
	if err != nil {
		return nil, ErrSessionNotFound
	}

	return session, nil
}
