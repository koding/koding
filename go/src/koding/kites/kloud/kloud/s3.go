package kloud

import (
	"log"
	"os"
	"time"

	"launchpad.net/goamz/aws"
	"launchpad.net/goamz/s3"
)

type Bucket struct {
	bucket *s3.Bucket
}

func NewBucket() *Bucket {
	// os.Getenv("AWS_ACCESS_KEY_ID")
	// os.Getenv("AWS_SECRET_ACCESS_KEY")
	// auth, err := aws.EnvAuth()
	// if err != nil {
	// 	panic(err)
	// }

	auth := aws.Auth{
		AccessKey: "AKIAI6IUMWKF3F4426CA",
		SecretKey: "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",
	}

	s := s3.New(auth, aws.USEast)

	return &Bucket{
		bucket: s.Bucket("koding-kites"),
	}
}

func (b *Bucket) List(path string) (*s3.ListResp, error) {
	return b.bucket.List("", "", "", 100)
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
