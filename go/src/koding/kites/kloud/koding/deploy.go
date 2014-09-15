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

	kiteprotocol "github.com/koding/kite/protocol"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/s3"
	"koding/kites/kloud/klient"
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

	KlientToken string

	Bucket *Bucket
	DB     *mongodb.MongoDB
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

	query := kiteprotocol.Kite{ID: k.KlientToken}

	// make a custom logger which just prepends our machineid
	infoLog := func(format string, formatArgs ...interface{}) {
		format = "[%s] " + format
		args := []interface{}{artifact.MachineId}
		args = append(args, formatArgs...)
		k.Log.Info(format, args...)
	}

	infoLog("Connecting to remote Klient instance")
	klientRef, err := klient.NewWithTimeout(k.Kite, query.String(), time.Minute)
	if err != nil {
		k.Log.Warning("Connecting to remote Klient instance err: %s", err)
	} else {
		defer klientRef.Close()
		infoLog("Sending a ping message")
		if err := klientRef.Ping(); err != nil {
			k.Log.Warning("Sending a ping message err:", err)
		}
	}

	artifact.KiteQuery = query.String()

	return artifact, nil
}
