package koding

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/s3"
)

var defaultKlientBucket = "klient/production"

type Bucket struct {
	Bucket *s3.Bucket
	Folder string
}

func (b *Bucket) LatestDeb() (string, error) {
	l, err := b.Bucket.List(b.Folder, "", "", 100)
	if err != nil {
		return "", err
	}

	if len(l.Contents) == 0 {
		return "", fmt.Errorf("No .deb binary available for %s", b.Folder)
	}

	for _, content := range l.Contents {
		if strings.HasSuffix(content.Key, "deb") {
			return content.Key, nil
		}
	}

	return "", errors.New("couldn't find any .deb file")
}

func (b *Bucket) SignedURL(path string, expires time.Time) string {
	return b.Bucket.SignedURL(path, expires)
}

func (b *Bucket) URL(path string) string {
	return b.Bucket.URL(path)
}

func NewBucket(name, folder string, auth aws.Auth) *Bucket {
	// our s3 is based on this region, so we use it
	s := s3.New(auth, aws.USEast)

	return &Bucket{
		Bucket: s.Bucket(name),
		Folder: folder,
	}
}
