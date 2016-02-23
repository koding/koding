// Package sneaker provides an integrated system for securely storing sensitive
// information using Amazon's Simple Storage Service (S3) and Key Management
// Service (KMS).
package sneaker

import (
	"fmt"
	fpath "path"
	"time"

	"github.com/aws/aws-sdk-go/service/kms"
	"github.com/aws/aws-sdk-go/service/s3"
)

// ObjectStorage is a sub-set of the capabilities of the S3 client.
type ObjectStorage interface {
	ListObjects(*s3.ListObjectsInput) (*s3.ListObjectsOutput, error)
	DeleteObject(*s3.DeleteObjectInput) (*s3.DeleteObjectOutput, error)
	PutObject(*s3.PutObjectInput) (*s3.PutObjectOutput, error)
	GetObject(*s3.GetObjectInput) (*s3.GetObjectOutput, error)
}

// KeyManagement is a sub-set of the capabilities of the KMS client.
type KeyManagement interface {
	GenerateDataKey(*kms.GenerateDataKeyInput) (*kms.GenerateDataKeyOutput, error)
	Decrypt(*kms.DecryptInput) (*kms.DecryptOutput, error)
}

// A File is an encrypted secret, stored in S3.
type File struct {
	Path         string
	LastModified time.Time
	Size         int
	ETag         string
}

// A Manager allows you to manage files.
type Manager struct {
	Objects           ObjectStorage
	Envelope          Envelope
	KeyId             string
	EncryptionContext map[string]string
	Bucket, Prefix    string
}

func (m *Manager) context(path string) map[string]string {
	ctxt := make(map[string]string, len(m.EncryptionContext)+1)
	for k, v := range m.EncryptionContext {
		ctxt[k] = v
	}
	ctxt["Path"] = fmt.Sprintf("s3://%s/%s", m.Bucket, fpath.Join(m.Prefix, path))
	return ctxt
}
