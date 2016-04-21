package api

import (
	"net/url"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kms"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/codahale/sneaker"
	"github.com/koding/logging"
)

const (
	CredentialStore  = "credential-store"
	CredentialGet    = "credential-get"
	CredentialDelete = "credential-delete"
)

// AddHandlers adds handlers for slack integration
func AddHandlers(m *mux.Mux, l logging.Logger, config *config.Config) {
	manager, err := loadManager(config)
	if err != nil {
		panic(err)
	}

	s := &SneakerS3{
		Manager: manager,
		log:     l,
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

	// here, we provide access and secret keys for aws
	creds := credentials.NewStaticCredentials(config.SneakerS3.AwsAccesskeyId, config.SneakerS3.AwsSecretAccessKey, "")

	// we'r gonna use aws providers and region to init aws config
	session := session.New(aws.NewConfig().WithCredentials(creds).WithRegion(config.SneakerS3.AwsRegion))

	return &sneaker.Manager{
		Objects: s3.New(session),
		Envelope: sneaker.Envelope{
			KMS: kms.New(session),
		},
		Bucket: u.Host,
		Prefix: u.Path,
		KeyId:  config.SneakerS3.SneakerMasterKey,
	}, nil
}
