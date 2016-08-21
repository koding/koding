package gateway

import (
	"encoding/json"
	"io"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

type Policy struct {
	Version   string       `json:"Version"`
	Statement []Permission `json:"Statement"`
}

type Permission struct {
	Effect    string      `json:"Effect"`
	Action    []string    `json:"Action"`
	Resource  []string    `json:"Resource"`
	Principal interface{} `json:"Principal,omitempty"`
}

var (
	stsPolicyTmpl = mustJSON(&Policy{
		Version: "2012-10-17",
		Statement: []Permission{{
			Effect: "Allow",
			Action: []string{
				"s3:PutObject",
			},
			Resource: []string{
				"arn:aws:s3:::%[1]s/%[2]s",
				"arn:aws:s3:::%[1]s/%[2]s/*",
			},
		}},
	})

	s3PolicyTmpl = mustJSON(&Policy{
		Version: "2012-10-17",
		Statement: []Permission{{
			Effect: "Allow",
			Action: []string{
				"s3:PutObject",
				"s3:PutObjectAcl", // TODO(rjeczalik): no idea why this is required, since credentials does not have such policy so setting this should be a nop
			},
			Resource: []string{
				"arn:aws:s3:::%[1]s/%[2]s",
				"arn:aws:s3:::%[1]s/%[2]s/*",
			},
			Principal: map[string]string{
				"AWS": "%[3]s",
			},
		}},
	})
)

// UserBucket
type UserBucket struct {
	cfg *Config
	s3  *s3.S3
}

// NewUserBucket
func NewUserBucket(cfg *Config) *UserBucket {
	p := NewProvider(cfg)

	return &UserBucket{
		cfg: cfg,
		s3: s3.New(session.New(&aws.Config{
			Credentials: credentials.NewCredentials(p),
			Region:      aws.String(cfg.region()),
		})),
	}
}

// Put
func (ub *UserBucket) Put(key string, rs io.ReadSeeker) error {
	type lener interface {
		Len() int
	}

	input := &s3.PutObjectInput{
		ACL:    aws.String("authenticated-read"),
		Body:   rs,
		Bucket: &ub.cfg.Bucket,
		Key:    aws.String(ub.cfg.username() + "/" + key),
	}

	if l, ok := rs.(lener); ok {
		input.ContentLength = aws.Int64(int64(l.Len()))
	}

	ub.cfg.log().Debug("PutObject()=%+v", input)

	_, err := ub.s3.PutObject(input)
	return err
}

// mustJSON returns a JSON representation of v as a string,
// so it can be used as a format argument.
func mustJSON(v interface{}) string {
	p, err := json.Marshal(v)
	if err != nil {
		panic(err)
	}
	return string(p)
}
