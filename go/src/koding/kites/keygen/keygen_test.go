package keygen_test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"koding/kites/keygen"
	"koding/kites/keygen/keygentest"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

func TestKeygen_UserBucket(t *testing.T) {
	var f keygentest.Flags

	if err := keygentest.ParseFlags(&f); err != nil {
		t.Fatal(err)
	}

	// to cleanup after tests
	rootS3 := s3.New(session.New(f.AWSConfig()))
	drv := &keygentest.Driver{ChanCap: 1}
	cfg := f.Config()

	defer drv.Server(cfg)()

	populate := map[string][]struct {
		Key     string
		Content string
	}{
		"testuser1": {
			{"user", "testuser1"},
			{"time", time.Now().String()},
		},
		"testuser2": {
			{"user", "testuser2"},
			{"time", time.Now().String()},
		},
		"testuser3": {
			{"user", "testuser3"},
			{"time", time.Now().String()},
		},
	}

	for username, files := range populate {
		ub := keygen.NewUserBucket(drv.Kite(cfg, username))

		for _, file := range files {
			if _, err := ub.Put(file.Key, strings.NewReader(file.Content)); err != nil {
				t.Fatalf("%s: Put(%s)=%s", username, file.Key, err)
			}

			defer rootS3.DeleteObject(&s3.DeleteObjectInput{
				Bucket: &cfg.Bucket,
				Key:    aws.String(username + "/" + file.Key),
			})
		}

		for otherUser, files := range populate {
			for _, file := range files {
				key := otherUser + "/" + file.Key

				// Ensure current user has no permission to upload to other user directories.
				if username != otherUser {
					_, err := ub.UserPut(key, strings.NewReader(file.Content))

					if e := testErrorCode(err, "AccessDenied"); e != nil {
						t.Errorf("%s -> %s: PutObject: %s", username, otherUser, e)
					}
				}

				// Ensure current user has no permissions to delete objects.
				_, err := ub.S3().DeleteObject(&s3.DeleteObjectInput{
					Bucket: &cfg.Bucket,
					Key:    &key,
				})

				if e := testErrorCode(err, "AccessDenied"); e != nil {
					t.Errorf("%s -> %s: DeleteObject: %s", username, otherUser, e)
				}

				// Ensure current user has no permissions to get objects.
				_, err = ub.S3().GetObject(&s3.GetObjectInput{
					Bucket: &cfg.Bucket,
					Key:    &key,
				})

				if e := testErrorCode(err, "AccessDenied"); e != nil {
					t.Errorf("%s -> %s: GetObject: %s", username, otherUser, e)
				}

				// Ensure current user has no permissions to list objects.
				_, err = ub.S3().ListObjects(&s3.ListObjectsInput{
					Bucket: &cfg.Bucket,
					Prefix: &key,
				})

				if e := testErrorCode(err, "AccessDenied"); e != nil {
					t.Errorf("%s -> %s: ListObjects: %s", username, otherUser, e)
				}
			}
		}
	}
}

func testErrorCode(err error, code string) error {
	e, ok := err.(awserr.Error)
	if !ok {
		return fmt.Errorf("got %v, want awserr.Error", err)
	}

	if e.Code() != code {
		return fmt.Errorf("got %s, want %s", e.Code(), code)
	}

	return nil
}
