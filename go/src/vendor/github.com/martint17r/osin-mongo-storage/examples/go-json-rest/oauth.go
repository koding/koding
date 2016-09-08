package main

import (
	"fmt"
	"net/http"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/RangelReale/osin"
	"github.com/RangelReale/osin/example"
	"github.com/martint17r/osin-mongo-storage/mgostore"
)

type UserData bson.M

// AuthorizeClient is the Authorization code endpoint
func (oauth *oAuthHandler) AuthorizeClient(w http.ResponseWriter, r *http.Request) {
	server := oauth.server
	resp := server.NewResponse()
	if ar := server.HandleAuthorizeRequest(resp, r); ar != nil {
		if !example.HandleLoginPage(ar, w, r) {
			return
		}
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

// Access token endpoint
func (oauth *oAuthHandler) GenerateToken(w http.ResponseWriter, r *http.Request) {
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

// Information endpoint
func (oauth *oAuthHandler) HandleInfo(w http.ResponseWriter, r *http.Request) {
	server := oauth.server
	resp := server.NewResponse()
	if ir := server.HandleInfoRequest(resp, r); ir != nil {
		server.FinishInfoRequest(resp, r, ir)
	}
	osin.OutputJSON(resp, w, r)
}

type oAuthHandler struct {
	sconfig *osin.ServerConfig
	server  *osin.Server
	Storage *mgostore.MongoStorage
}

func NewOAuthHandler(session *mgo.Session, dbName string) *oAuthHandler {
	sconfig := osin.NewServerConfig()
	sconfig.AllowedAuthorizeTypes = osin.AllowedAuthorizeType{osin.CODE, osin.TOKEN}
	sconfig.AllowedAccessTypes = osin.AllowedAccessType{osin.AUTHORIZATION_CODE,
		osin.REFRESH_TOKEN, osin.PASSWORD, osin.CLIENT_CREDENTIALS, osin.ASSERTION}
	sconfig.AllowGetAccessRequest = true
	storage := mgostore.New(session, dbName)
	server := osin.NewServer(sconfig, storage)
	return &oAuthHandler{sconfig, server, storage}
}
