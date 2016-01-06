package gatherrun

import (
	"os"
	"path/filepath"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/aws"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/aws/session"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/service/s3"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/service/s3/s3manager"
)

const (
	contentTypeTar = "application/tar"
	tarSuffix      = ".tar"
)

// Fetcher defines interface for downloading gather binary to user VMs.
type Fetcher interface {
	Download(string) error
	GetFileName() string
}

// S3Fetcher downloads gather binary from a private S3 bucket.
type S3Fetcher struct {
	BucketName string
	FileName   string
	Region     string
}

func (s *S3Fetcher) Downloader() *s3manager.Downloader {
	config := &aws.Config{
		Credentials: credentials.AnonymousCredentials,
		Region:      aws.String(s.Region),
	}

	sess := session.New(config)
	return s3manager.NewDownloader(sess)
}

func (s *S3Fetcher) GetFileName() string {
	return s.FileName
}

// Download downloads scripts from S3 bucket into specified folder.
func (s *S3Fetcher) Download(folderName string) error {
	params := &s3.GetObjectInput{
		Bucket: aws.String(s.BucketName),
		Key:    aws.String(s.FileName),
	}

	w, err := os.Create(filepath.Join(folderName, s.FileName))
	if w != nil {
		defer w.Close()
	}

	if err != nil {
		return err
	}

	_, err = s.Downloader().Download(w, params)
	return err
}
