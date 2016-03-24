package main

import (
	"fmt"
	"net/http"

	"github.com/RangelReale/osin"
	"github.com/osin-mongo-storage/mgostore"
	"gopkg.in/mgo.v2"
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
		// if !example.HandleLoginPage(ar, w, r) {
		// 	return
		// }
		// ar.UserData = UserData{"Login": "test"}
		// ar.Authorized = true
		// server.FinishAuthorizeRequest(resp, r, ar)

		//
		// HANDLE LOGIN PAGE HERE !!!
		//
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

func NewOAuthHandler(session *mgo.Session, dbName string) *Oauth {
	sconfig := osin.NewServerConfig()
	sconfig.AllowedAuthorizeTypes = osin.AllowedAuthorizeType{osin.CODE, osin.TOKEN}
	sconfig.AllowedAccessTypes = osin.AllowedAccessType{osin.AUTHORIZATION_CODE,
		osin.REFRESH_TOKEN, osin.PASSWORD, osin.CLIENT_CREDENTIALS, osin.ASSERTION}
	sconfig.AllowGetAccessRequest = true
	storage := mgostore.New(session, dbName)
	server := osin.NewServer(sconfig, storage)

	// return &Oauth{sconfig, server, storage}

	return &Oauth{
		sconfig: sconfig,
		server:  server,
		Storage: storage,
	}

}

///////

///////
/////
///////
//////
//////
/////
//////

//////

/// THIS PART IS JUST FOR TESTING
// WILL BE REMOVED !!
func main() {
	// TestStorage implements the "osin.Storage" interface
	server := osin.NewServer(osin.NewServerConfig(), &TestStorage{})

	// Authorization code endpoint
	http.HandleFunc("/authorize", func(w http.ResponseWriter, r *http.Request) {
		resp := server.NewResponse()
		defer resp.Close()

		if ar := server.HandleAuthorizeRequest(resp, r); ar != nil {

			// HANDLE LOGIN PAGE HERE

			ar.Authorized = true
			server.FinishAuthorizeRequest(resp, r, ar)
		}
		osin.OutputJSON(resp, w, r)
	})

	// Access token endpoint
	http.HandleFunc("/token", func(w http.ResponseWriter, r *http.Request) {
		resp := server.NewResponse()
		defer resp.Close()

		if ar := server.HandleAccessRequest(resp, r); ar != nil {
			ar.Authorized = true
			server.FinishAccessRequest(resp, r, ar)
		}
		osin.OutputJSON(resp, w, r)
	})

	http.ListenAndServe(":14000", nil)

}
