package gatherrun

import (
	"io"
	"os"
	"path/filepath"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/aws"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/service/s3"
)

const (
	CONTENT_TYPE_TAR = "application/tar"
	TAR_SUFFIX       = ".tar"
)

type Fetcher interface {
	Download(string) error
	GetFileName() string
}

type S3Fetcher struct {
	AccessKey  string
	SecretKey  string
	BucketName string
	FileName   string
	Region     string
}

func (s *S3Fetcher) Bucket() *s3.S3 {
	config := &aws.Config{
		Credentials: credentials.NewStaticCredentials(s.AccessKey, s.SecretKey, ""),
		Region:      s.Region,
	}

	return s3.New(config)
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

	resp, err := s.Bucket().GetObject(params)
	if err != nil {
		return err
	}

	w, err := os.Create(filepath.Join(folderName, s.FileName))
	if err != nil {
		return err
	}
	defer w.Close()

	_, err = io.Copy(w, resp.Body)

	return err
}
