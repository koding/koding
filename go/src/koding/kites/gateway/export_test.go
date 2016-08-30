package gateway

import (
	"io"

	"github.com/aws/aws-sdk-go/service/s3"
)

// UserPut
func (ub *UserBucket) UserPut(path string, rs io.ReadSeeker) error {
	return ub.userPut(path, rs)
}

// S3
func (ub *UserBucket) S3() *s3.S3 {
	return ub.s3
}
