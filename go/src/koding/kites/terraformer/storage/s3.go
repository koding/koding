package storage

import (
	"bytes"
	"io"
	"io/ioutil"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/koding/logging"
)

var _ Interface = (*S3)(nil)

// S3 provides Storage functionality backed by S3.
type S3 struct {
	bucketName string
	s3         *s3.S3 // bucket `bucketName` holds the plans of terraform
	log        logging.Logger
}

// NewS3 creates a new S3 system.
func NewS3(key, secret, bucketName string, log logging.Logger) (*S3, error) {
	cfg := &aws.Config{
		Credentials: credentials.NewStaticCredentials(key, secret, ""),
		Region:      aws.String("us-east-1"), // we are only using us east
	}

	svc := s3.New(session.New(cfg))

	params := &s3.PutBucketAclInput{
		Bucket: aws.String(bucketName),
		ACL:    aws.String(s3.BucketCannedACLPrivate),
	}
	if _, err := svc.PutBucketAcl(params); err != nil {
		return nil, err
	}

	return &S3{
		bucketName: bucketName,
		s3:         svc,
		log:        log,
	}, nil
}

// BasePath returns bucket name.
func (s *S3) BasePath() (string, error) {
	return s.bucketName, nil
}

// Write writes to a s3 bucket.
func (s *S3) Write(path string, file io.Reader) error {
	params := &s3.PutObjectInput{
		ACL:         aws.String(s3.BucketCannedACLPrivate),
		Bucket:      aws.String(s.bucketName),
		Key:         aws.String(path),
		ContentType: aws.String("application/json"),
	}
	if rs, ok := file.(io.ReadSeeker); ok {
		params.Body = rs
		if size := s.guessSize(file); size > 0 {
			params.ContentLength = aws.Int64(size)
		}
	} else {
		// The file does not support seeking, thus can't be used
		// by the AWS streaming api - read it in-memory instead.
		content, err := ioutil.ReadAll(file)
		if err != nil {
			return err
		}
		params.Body = bytes.NewReader(content)
		params.ContentLength = aws.Int64(int64(len(content)))
	}

	_, err := s.s3.PutObject(params)
	// TODO(rjeczalik): make the write blocking with s3.WaitUntilObjectExists?
	return err
}

// Remove removes a file from a bucket.
func (s *S3) Remove(path string) error {
	params := &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(path),
	}
	_, err := s.s3.DeleteObject(params)
	return err
}

// Read reads a file from a bucket.
//
// Caller is responsible for closing the request body.
func (s *S3) Read(path string) (io.Reader, error) {
	params := &s3.GetObjectInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(path),
	}
	resp, err := s.s3.GetObject(params)
	if err != nil {
		return nil, err
	}
	return resp.Body, nil
}

// Clone clones the contents of a bucket to target storage
func (s *S3) Clone(path string, target Interface) error {
	params := &s3.ListObjectsInput{
		Bucket: aws.String(s.bucketName),
		// Prefix limits the response to keys that begin with the specified prefix.
		// You can use prefixes to separate a bucket into different groupings of keys.
		// (You can think of using prefix to make groups in the same way you'd use a
		// folder in a file system.)
		Prefix: nil,
		// Specifies the key to start with when listing objects in a bucket. Amazon
		// S3 returns object keys in alphabetical order, starting with key after the
		// marker in order.
		Marker: nil,
		// Sets the maximum number of keys returned in the response body. You can
		// add this to your request if you want to retrieve fewer than the default
		// 1000 keys.
		MaxKeys: nil,
	}
	if path != "" {
		// If path was an empty string, ListObject would successfuly return nothing.
		path = path + "/"
		params.Prefix = aws.String(path)
	}
	for {
		// read all elements in a bucket, we are gonna have more than 1000 items in
		// that bucket/folder, so we handle paginated response to copy them all.
		resp, err := s.s3.ListObjects(params)
		if err != nil {
			return err
		}
		// Handle paginated reply - find marker, see inline doc for more details:
		//
		//   https://godoc.org/github.com/aws/aws-sdk-go/service/s3#ListObjectsOutput
		//
		params.Marker = nil
		if aws.BoolValue(resp.IsTruncated) {
			if resp.NextMarker != nil {
				params.Marker = resp.NextMarker
			} else if n := len(resp.Contents); n != 0 {
				params.Marker = resp.Contents[n-1].Key
			}
		}
		for _, obj := range resp.Contents {
			// write them all to target
			newPath := aws.StringValue(obj.Key)

			// if bucket is created but doesnt have any objects
			if newPath == path {
				continue
			}

			r, err := s.Read(newPath)
			if err != nil {
				return err
			}

			err = target.Write(newPath, r)

			// If the reader implements io.Closer interface, close the resource.
			s.ensureClosed(r, newPath)

			if err != nil {
				return err
			}
		}
		// If no marker is set it means full response was read.
		if params.Marker == nil {
			break
		}
	}

	return nil
}

func (s *S3) ensureClosed(r io.Reader, path string) {
	if c, ok := r.(io.Closer); ok {
		if err := c.Close(); err != nil {
			s.log.Warning("failed closing resource path=%q: %s", path, err)
		}
	}
}

func (s *S3) guessSize(r io.Reader) int64 {
	// trying to be smart here:
	//
	//  https://github.com/golang/go/blob/0417872/src/net/http/request.go#L602-L609
	//
	switch v := r.(type) {
	case *bytes.Buffer:
		return int64(v.Len())
	case *bytes.Reader:
		return int64(v.Len())
	case *strings.Reader:
		return int64(v.Len())
	case *os.File:
		if fi, err := v.Stat(); err == nil {
			return fi.Size()
		}
	}
	s.log.Warning("unable to guess body size for %T", r)
	return 0
}
