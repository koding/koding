package s3utils

import (
	"launchpad.net/goamz/aws"
	"launchpad.net/goamz/s3"
)

// TODO: read from config
var s3store = s3.New(
	aws.Auth{
		AccessKey: "",
		SecretKey: "",
	},
	aws.USEast,
)

type Bucket struct {
	bucket *s3.Bucket
}

func NewBucket(name string) *Bucket {
	return &Bucket{
		bucket: s3store.Bucket(name),
	}
}

func (s *Bucket) List(prefix, delim, marker string, max int) (*s3.ListResp, error) {
	return s.bucket.List(prefix, delim, marker, max)
}

func (s *Bucket) Put(path string, data []byte, contType string, perm s3.ACL) error {
	return s.bucket.Put(path, data, contType, perm)
}

func (s *Bucket) Del(path string) error {
	return s.bucket.Del(path)
}
