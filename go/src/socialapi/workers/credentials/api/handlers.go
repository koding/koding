package api

import (
	"log"
	"net/url"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kms"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/codahale/sneaker"
)

// AddHandlers adds handlers for slack integration
func AddHandlers(m *mux.Mux, config *config.Config) {
	s := &SneakerS3{
		loadManager(config),
	}

	m.AddHandler(
		handler.Request{
			Handler:  s.Store,
			Name:     "credential-store",
			Type:     handler.PostRequest,
			Endpoint: "/credential/{pathName}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.Get,
			Name:     "credential-get",
			Type:     handler.GetRequest,
			Endpoint: "/credential/{pathName}",
		},
	)

}

func loadManager(config *config.Config) *sneaker.Manager {
	u, err := url.Parse(config.SneakerS3.SneakerS3Path)
	if err != nil {
		log.Fatalf("bad SNEAKER_S3_PATH: %s", err)
	}
	if u.Path != "" && u.Path[0] == '/' {
		u.Path = u.Path[1:]
	}

	// we wont gonna use context in storing system
	ctxt, err := parseContext("")
	if err != nil {
		log.Fatalf("bad SNEAKER_MASTER_CONTEXT: %s", err)
	}

	return &sneaker.Manager{
		Objects: s3.New(session.New()),
		Envelope: sneaker.Envelope{
			KMS: kms.New(session.New()),
		},
		Bucket:            u.Host,
		Prefix:            u.Path,
		EncryptionContext: ctxt,
		KeyId:             config.SneakerS3.SneakerMasterKey,
	}
}
