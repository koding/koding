package kloud

import (
	"fmt"
	"log"
	"os"
	"time"

	"launchpad.net/goamz/aws"
	"launchpad.net/goamz/s3"
)

var defaultKlientBucket = "klient/production"

type Bucket struct {
	bucket *s3.Bucket
	folder string
}

func NewBucket(name, folder string) *Bucket {
	auth := aws.Auth{
		AccessKey: "AKIAI6IUMWKF3F4426CA",
		SecretKey: "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",
	}

	s := s3.New(auth, aws.USEast)

	return &Bucket{
		bucket: s.Bucket(name),
		folder: folder,
	}
}

func (b *Bucket) Latest() (string, error) {
	l, err := b.bucket.List(b.folder, "", "", 100)
	if err != nil {
		return "", err
	}

	if len(l.Contents) == 0 {
		return "", fmt.Errorf("No .deb binary available for %s", b.folder)
	}

	return l.Contents[0].Key, nil
}

func (b *Bucket) SignedURL(path string, expires time.Time) string {
	return b.bucket.SignedURL(path, expires)
}

func (b *Bucket) Upload(path string) error {
	file, err := os.Open(path)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	fi, err := file.Stat()
	if err != nil {
		log.Fatalln(err)
	}

	return b.bucket.PutReader(
		"klient/klient_0.0.3_amd64.deb",
		file,
		fi.Size(),
		"application/gzip",
		s3.Private,
	)
}
