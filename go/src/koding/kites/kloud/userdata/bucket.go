package userdata

import (
	"errors"
	"fmt"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

var ErrNoContents = errors.New("no contents")

type Bucket struct {
	S3     *s3.S3
	Name   string
	Folder string
}

func (b *Bucket) LatestDeb() (string, error) {
	objs, err := b.listContents(b.Folder, 100)
	if err == ErrNoContents {
		return "", fmt.Errorf("no .deb binary available for %q", b.Folder)
	}
	if err != nil {
		return "", err
	}

	for _, obj := range objs {
		if key := aws.StringValue(obj.Key); strings.HasSuffix(key, "deb") {
			return key, nil
		}
	}

	return "", errors.New("couldn't find any .deb file")
}

func (b *Bucket) listContents(prefix string, max int) ([]*s3.Object, error) {
	params := &s3.ListObjectsInput{
		Bucket:  aws.String(b.Name),
		Prefix:  aws.String(prefix),
		MaxKeys: aws.Int64(int64(max)),
	}
	resp, err := b.S3.ListObjects(params)
	if err != nil {
		return nil, err
	}
	if len(resp.Contents) == 0 {
		return nil, ErrNoContents
	}
	return resp.Contents, nil
}

func (b *Bucket) URL(path string) string {
	params := &s3.GetObjectInput{
		Bucket: aws.String(b.Name),
		Key:    aws.String(path),
	}
	req, _ := b.S3.GetObjectRequest(params)
	// Presign builds the actual URL with specified params, we do not care
	// about signed request here.
	req.Presign(0)
	return req.HTTPRequest.URL.String()
}

func NewBucket(name, folder string, c *credentials.Credentials) *Bucket {
	cfg := &aws.Config{
		Credentials: c,
		Region:      aws.String("us-east-1"), // our s3 is based on this region, so we use it
	}
	srvc := s3.New(session.New(cfg))

	return &Bucket{
		S3:     srvc,
		Name:   name,
		Folder: folder,
	}
}
