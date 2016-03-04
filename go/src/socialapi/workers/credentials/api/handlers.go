package api

import (
	"net/url"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kms"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/codahale/sneaker"
)

const (
	CredentialStore  = "credential-store"
	CredentialGet    = "credential-get"
	CredentialDelete = "credential-delete"
)

// AddHandlers adds handlers for slack integration
func AddHandlers(m *mux.Mux, config *config.Config) {
	manager, err := loadManager(config)
	if err != nil {
		panic(err)
	}
	s := &SneakerS3{
		manager,
	}

	m.AddHandler(
		handler.Request{
			Handler:  s.Store,
			Name:     CredentialStore,
			Type:     handler.PostRequest,
			Endpoint: "/credential/{pathName}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.Get,
			Name:     CredentialGet,
			Type:     handler.GetRequest,
			Endpoint: "/credential/{pathName}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.Delete,
			Name:     CredentialDelete,
			Type:     handler.DeleteRequest,
			Endpoint: "/credential/{pathName}",
		},
	)

}

func loadManager(config *config.Config) (*sneaker.Manager, error) {
	u, err := url.Parse(config.SneakerS3.SneakerS3Path)
	if err != nil {

		return nil, err
	}
	if u.Path != "" && u.Path[0] == '/' {
		u.Path = u.Path[1:]
	}

	session := session.New()

	return &sneaker.Manager{
		Objects: s3.New(session),
		Envelope: sneaker.Envelope{
			KMS: kms.New(session),
		},
		Bucket:            u.Host,
		Prefix:            u.Path,
		EncryptionContext: nil,
		KeyId:             config.SneakerS3.SneakerMasterKey,
	}, nil
}
