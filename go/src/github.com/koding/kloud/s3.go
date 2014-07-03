package kloud

import (
	"fmt"
	"log"
	"os"
	"time"

	"launchpad.net/goamz/s3"
)

var defaultKlientBucket = "klient/production"

type Bucket struct {
	Bucket *s3.Bucket
	Folder string
}

func (b *Bucket) Latest() (string, error) {
	l, err := b.Bucket.List(b.Folder, "", "", 100)
	if err != nil {
		return "", err
	}

	if len(l.Contents) == 0 {
		return "", fmt.Errorf("No .deb binary available for %s", b.Folder)
	}

	return l.Contents[0].Key, nil
}

func (b *Bucket) SignedURL(path string, expires time.Time) string {
	return b.Bucket.SignedURL(path, expires)
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

	return b.Bucket.PutReader(
		"klient/klient_0.0.3_amd64.deb",
		file,
		fi.Size(),
		"application/gzip",
		s3.Private,
	)
}
