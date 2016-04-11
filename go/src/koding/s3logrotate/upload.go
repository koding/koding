package s3logrotate

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"os"
	"os/user"
	"path/filepath"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

type Uploader struct {
	Region    string
	Bucket    string
	FileNamer func() *string
	Client    *s3.S3
}

func NewUploadClient(region, bucket string) (*Uploader, error) {
	svc := s3.New(session.New(&aws.Config{
		Region: aws.String(region)},
	))

	return &Uploader{
		Client:    svc,
		FileNamer: fileNamer,
		Bucket:    bucket,
		Region:    region,
	}, nil
}

func (u *Uploader) Upload(b []byte) error {
	fileName := *u.FileNamer() + ".zip"

	_, err := u.Client.PutObject(&s3.PutObjectInput{
		Body:   bytes.NewReader(b),
		Bucket: &u.Bucket,
		Key:    &fileName,
	})

	return err
}

func fileNamer() *string {
	b := make([]byte, 10)
	rand.Read(b)

	i, _ := getId()                                      // get id
	h := string([]rune(hex.EncodeToString(b))[:8])       // add random hash
	t := time.Now().UTC().Format("01-02-2006-15-04") + h // get time
	f := filepath.Join(i, t)                             // join together

	return &f
}

func getId() (string, error) {
	usr, err := user.Current()
	if err != nil {
		return "", err
	}

	// in cases where we can't get hostname, use what we've
	hostname, err := os.Hostname()
	if err != nil {
		return usr.Username, nil
	}

	return usr.Username + ":" + hostname, nil
}
