package storage

import (
	"io"
	"io/ioutil"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/s3"
)

var _ Interface = S3{}

// S3 provides Storage functionality backed by S3
type S3 struct {
	// Bucket holds the plans of terraform
	bucket *s3.Bucket
}

// NewS3 creates a new S3 system
func NewS3(key, secret, bucketName string) (S3, error) {
	// init s3 auth
	awsAuth, err := aws.GetAuth(key, secret)
	if err != nil {
		return S3{}, err
	}

	// we are only using us east
	awsS3Bucket := s3.New(awsAuth, aws.USEast).Bucket(bucketName)

	if err := awsS3Bucket.PutBucket(s3.Private); err != nil {
		return S3{}, err
	}

	return S3{
		bucket: awsS3Bucket,
	}, nil
}

// BasePath returns bucket name
func (s S3) BasePath() (string, error) {
	return s.bucket.Name, nil
}

// Clean doesnt do anything
func (s S3) Clean(path string) error {
	return nil
}

// Write writes to a s3 bucket
func (s S3) Write(path string, file io.Reader) error {
	// TODO(cihangir): we can use bucket.PutReader here
	content, err := ioutil.ReadAll(file)
	if err != nil {
		return err
	}

	return s.bucket.Put(path, content, "application/json", s3.Private)
}

// Remove removes a file from a bucket
func (s S3) Remove(path string) error {
	if err := s.bucket.Del(path); err != nil {
		return err
	}

	return nil
}

// Read reads a file from a bucket
func (s S3) Read(path string) (io.Reader, error) {
	return s.bucket.GetReader(path)
}

// Clone clones the contents of a bucket to target storage
func (s S3) Clone(path string, target Interface) error {
	filePath := path + "/"
	// Limits the response to keys that begin with the specified prefix. You can
	// use prefixes to separate a bucket into different groupings of keys. (You
	// can think of using prefix to make groups in the same way you'd use a
	// folder in a file system.)
	prefix := filePath

	// If you don't specify the prefix parameter, then the substring starts at
	// the beginning of the key
	delim := ""

	// Specifies the key to start with when listing objects in a bucket. Amazon
	// S3 returns object keys in alphabetical order, starting with key after the
	// marker in order.
	marker := ""

	// Sets the maximum number of keys returned in the response body. You can
	// add this to your request if you want to retrieve fewer than the default
	// 1000 keys.
	max := 0

	// read all elements in a bucket, we are gonna have more than 1000 items in
	// that bucket/folder
	result, err := s.bucket.List(prefix, delim, marker, max)
	if err != nil {
		return err
	}

	// write them all to target
	for _, res := range result.Contents {
		newPath := res.Key

		// if bucket is created but doesnt have
		if newPath == filePath {
			continue
		}

		r, err := s.Read(newPath)
		if err != nil {
			return err
		}

		if err := target.Write(newPath, r); err != nil {
			return err
		}
	}

	return nil
}
