package keygen

import (
	"encoding/json"
	"io"
	"net/url"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

// Policy represents S3/STS policy document.
type Policy struct {
	Version   string       `json:"Version"`
	Statement []Permission `json:"Statement"`
}

// Permission represents single permission statement within Policy document.
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
				"s3:PutObjectAcl",
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
				"s3:PutObjectAcl",
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

// UserBucket provides a client for writing to a publicly
// available bucket.
//
// Used for storing user logs.
type UserBucket struct {
	cfg *Config
	s3  *s3.S3
}

// NewUserBucket creates new bucket value for the given configuration.
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

// Put streams the content of rs reader to the S3 bucket under the given key.
func (ub *UserBucket) Put(key string, rs io.ReadSeeker) (*url.URL, error) {
	return ub.userPut(ub.cfg.username()+"/"+key, rs)
}

// URL gives the remote URL of the key.
func (ub *UserBucket) URL(key string) *url.URL {
	return &url.URL{
		Scheme: "https",
		Path:   "/" + ub.cfg.username() + "/" + key,
		Host:   ub.cfg.Bucket + ".s3.amazonaws.com",
	}
}

func (ub *UserBucket) userPut(path string, rs io.ReadSeeker) (*url.URL, error) {
	type lener interface {
		Len() int
	}

	input := &s3.PutObjectInput{
		ACL:    aws.String("bucket-owner-full-control"),
		Body:   rs,
		Bucket: &ub.cfg.Bucket,
		Key:    &path,
	}

	if l, ok := rs.(lener); ok {
		input.ContentLength = aws.Int64(int64(l.Len()))
	} else {
		size, err := rs.Seek(0, io.SeekEnd)
		if err != nil {
			return nil, err
		}

		_, err = rs.Seek(0, io.SeekStart)
		if err != nil {
			return nil, err
		}

		input.ContentLength = aws.Int64(size)
	}

	ub.cfg.log().Debug("PutObject()=%+v", input)

	if _, err := ub.s3.PutObject(input); err != nil {
		return nil, err
	}

	return &url.URL{
		Scheme: "https",
		Path:   "/" + path,
		Host:   ub.cfg.Bucket + ".s3.amazonaws.com",
	}, nil
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
