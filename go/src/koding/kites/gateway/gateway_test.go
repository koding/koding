package gateway_test

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"koding/kites/gateway"

	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/koding/logging"
)

func TestGateway_UserBucket(t *testing.T) {
	drv := &Driver{}
	cfg := &gateway.Config{
		AccessKey:  os.Getenv("GATEWAY_ACCESSKEY"),
		SecretKey:  os.Getenv("GATEWAY_SECRETKEY"),
		Bucket:     "kodingdev-publiclogs",
		AuthExpire: 15 * time.Minute,
		Log:        logging.NewCustom("gateway-test", true),
	}

	defer drv.Server(cfg)()

	populate := map[string][]struct {
		Key     string
		Content string
	}{
		"testuser1": {
			{"time", time.Now().String()},
		},
		"testuser2": {
			{"time", time.Now().String()},
		},
		"testuser3": {
			{"time", time.Now().String()},
		},
	}

	for username, files := range populate {
		ub := gateway.NewUserBucket(drv.Kite(cfg, username))

		for _, file := range files {
			if err := ub.Put(file.Key, strings.NewReader(file.Content)); err != nil {
				t.Fatalf("%s: Put(%s)=%s", username, file.Key, err)
			}
		}

		for otherUser, files := range populate {
			for _, file := range files {
				key := otherUser + "/" + file.Key

				// Ensure current user has no permission to upload to other user directories.
				if username != otherUser {
					err := ub.UserPut(key, strings.NewReader(file.Content))

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
