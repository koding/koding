package keygen

import (
	"io"
	"net/url"

	"github.com/aws/aws-sdk-go/service/s3"
)

func (ub *UserBucket) UserPut(path string, rs io.ReadSeeker) (*url.URL, error) {
	return ub.userPut(path, rs)
}

func (ub *UserBucket) S3() *s3.S3 {
	return ub.s3
}
