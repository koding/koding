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

func CleanZoneID(id string) string {
	return id
}
