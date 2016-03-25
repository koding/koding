package api

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/RangelReale/osin"
	"gopkg.in/mgo.v2"
)

const (
	OauthAuthorization = "oauth-authorization"
	GenerateToken      = "generate-token"
	dbName             = "koding"
)

// AddHandlers add oauth for koding api
func AddHandlers(m *mux.Mux, config *config.Config) {
	session := modelhelper.Mongo.Session

	oauth := NewOAuthHandler(session, dbName)
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

func NewOAuthHandler(session *mgo.Session, dbName string) *Oauth {
	sconfig := osin.NewServerConfig()
	sconfig.AllowedAuthorizeTypes = osin.AllowedAuthorizeType{osin.CODE, osin.TOKEN}
	sconfig.AllowedAccessTypes = osin.AllowedAccessType{osin.AUTHORIZATION_CODE,
		osin.REFRESH_TOKEN, osin.PASSWORD, osin.CLIENT_CREDENTIALS, osin.ASSERTION}
	sconfig.AllowGetAccessRequest = true
	storage := modelhelper.NewOauthStore(session, dbName)
	server := osin.NewServer(sconfig, storage)

	return &Oauth{
		sconfig: sconfig,
		server:  server,
		Storage: storage,
	}
}
