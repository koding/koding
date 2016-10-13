// +build ignore

package api

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	mgo "gopkg.in/mgo.v2"

	"github.com/RangelReale/osin"
)

const (
	OauthAuthorization = "oauth-authorization"
	GenerateToken      = "generate-token"
)

// AddHandlers add oauth for koding api
func AddHandlers(m *mux.Mux, config *config.Config) {
	session := modelhelper.Mongo.Session

	oauth := NewOAuthHandler(session)
	m.AddUnscopedHandler(
		handler.Request{
			Handler:  oauth.AuthorizeClient,
			Name:     OauthAuthorization,
			Type:     handler.GetRequest,
			Endpoint: "/oauth/authorize",
		},
	)
	m.AddUnscopedHandler(
		handler.Request{
			Handler:  oauth.GenerateToken,
			Name:     GenerateToken,
			Type:     handler.GetRequest,
			Endpoint: "/oauth/token",
		},
	)

}

func NewOAuthHandler(session *mgo.Session) *Oauth {
	sconfig := osin.NewServerConfig()
	// AllowedAccessType is a collection of allowed access request types
	sconfig.AllowedAuthorizeTypes = osin.AllowedAuthorizeType{osin.CODE, osin.TOKEN}
	// AccessRequestType is the type for OAuth param `grant_type`
	sconfig.AllowedAccessTypes = osin.AllowedAccessType{osin.AUTHORIZATION_CODE,
		osin.REFRESH_TOKEN, osin.PASSWORD, osin.CLIENT_CREDENTIALS, osin.ASSERTION}
	// If true allows access request using GET, else only POST - default false
	sconfig.AllowGetAccessRequest = true
	storage := modelhelper.NewOauthStore(session)
	server := osin.NewServer(sconfig, storage)

	return &Oauth{
		sconfig: sconfig,
		server:  server,
		Storage: storage,
	}
}
