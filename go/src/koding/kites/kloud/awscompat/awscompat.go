package awscompat

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	oldaws "github.com/mitchellh/goamz/aws"
)

func NewSession(a oldaws.Auth) *session.Session {
	c := credentials.NewStaticCredentials(a.AccessKey, a.SecretKey, a.Token)
	cfg := &aws.Config{
		Credentials: c,
	}
	return session.New(cfg, Transport)
}

func NewSessionCreds(key, secret string) *session.Session {
	return NewSession(oldaws.Auth{AccessKey: key, SecretKey: secret})
}

func CleanZoneID(id string) string {
	return id
}
