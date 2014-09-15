package koding

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"strings"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kloud/protocol"
	"github.com/koding/logging"

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

func NewBucket(name, folder string) *Bucket {
	auth := aws.Auth{
		AccessKey: "AKIAI6IUMWKF3F4426CA",
		SecretKey: "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",
	}

	s := s3.New(auth, aws.USEast)

	return &Bucket{
		Bucket: s.Bucket(name),
		Folder: folder,
	}
}

type KodingDeploy struct {
	Kite *kite.Kite
	Log  logging.Logger

	DB *mongodb.MongoDB
}

func (k *KodingDeploy) ServeKite(r *kite.Request) (interface{}, error) {
	data, err := r.Context.Get("buildArtifact")
	if err != nil {
		return nil, errors.New("koding-deploy: build artifact is not available")
	}

	artifact, ok := data.(*protocol.Artifact)
	if !ok {
		return nil, fmt.Errorf("koding-deploy: build artifact is malformed: %+v", data)
	}

	return artifact, nil
}
