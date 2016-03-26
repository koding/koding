package main

import (
	"fmt"
	"net/http"

	"github.com/RangelReale/osin"
	"github.com/osin-mongo-storage/mgostore"
)

type Oauth struct {
	sconfig *osin.ServerConfig
	server  *osin.Server
	Storage *mgostore.MongoStorage
}

func (o *Oauth) AuthorizeClientAuthorizeClient(w http.ResponseWriter, r *http.Request) {
	server := oauth.server
	resp := server.NewResponse()
	if ar := server.HandleAuthorizeRequest(resp, r); ar != nil {

		// Handle the login page

		// if !example.HandleLoginPage(ar, w, r) {
		// return
		// }

		// ~to-do , needs to be added users data
		ar.UserData = UserData{"Login": "test"}
		ar.Authorized = true
		server.FinishAuthorizeRequest(resp, r, ar)

	}
	if resp.IsError && resp.InternalError != nil {
		fmt.Printf("ERROR: %s\n", resp.InternalError)
	}
	if !resp.IsError {
		resp.Output["custom_parameter"] = 187723
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
		fmt.Printf("ERROR: %s\n", resp.InternalError)
	}
	if !resp.IsError {
		resp.Output["custom_parameter"] = 19923
	}
	osin.OutputJSON(resp, w, r)
}
