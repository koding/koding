// +build ignore

package api

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"

	"github.com/RangelReale/osin"
	"github.com/martint17r/osin-mongo-storage/mgostore"
)

var (
	ErrClientIdNotFound    = errors.New("client id is not found")
	ErrCookieValueNotFound = errors.New("cookie value is not found")
	ErrSessionNotFound     = errors.New("session is not found")
)

type Oauth struct {
	sconfig *osin.ServerConfig
	server  *osin.Server
	Storage *mgostore.MongoStorage
}

func (o *Oauth) AuthorizeClient(w http.ResponseWriter, r *http.Request) {
	server := oauth.server
	resp := server.NewResponse()
	if ar := server.HandleAuthorizeRequest(resp, r); ar != nil {

		session, err := getSession(r)
		if err != nil {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		// Handle the login page

		// if !example.HandleLoginPage(ar, w, r) {
		// return
		// }

		// ~to-do , needs to be added users data
		ar.UserData = session.Username
		ar.Authorized = true
		server.FinishAuthorizeRequest(resp, r, ar)

	}
	if resp.IsError && resp.InternalError != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	if !resp.IsError {
		resp.Output["custom_parameter"] = 187723
		return
	}
	osin.OutputJSON(resp, w, r)
}

func (o *Oauth) GenerateToken(w http.ResponseWriter, r *http.Request) {
	server := oauth.server
	resp := server.NewResponse()
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
	if resp.IsError && resp.InternalError != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	if !resp.IsError {
		resp.Output["custom_parameter"] = 19923
		return
	}
	osin.OutputJSON(resp, w, r)
}

func getSession(r *http.Request) (*models.Session, error) {
	cookie, err := r.Cookie("clientId")
	if err != nil {
		return "", ErrClientIdNotFound
	}

	if cookie.Value == "" {
		return "", ErrCookieValueNotFound
	}

	session, err := modelhelper.GetSession(cookie.Value)
	if err != nil {
		return "", ErrSessionNotFound
	}

	return session, nil
}
