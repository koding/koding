package sneaker

import (
	"path"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"
)

// List returns a list of files which match the given pattern, or if the pattern
// is blank, all files.
func (m *Manager) List(pattern string) ([]File, error) {
	resp, err := m.Objects.ListObjects(&s3.ListObjectsInput{
		Bucket: aws.String(m.Bucket),
		Prefix: aws.String(m.Prefix),
	})
	if err != nil {
		return nil, err
	}

	var secrets []File
	for _, obj := range resp.Contents {
		secrets = append(secrets, File{
			Path:         (*obj.Key)[len(m.Prefix):len(*obj.Key)],
			LastModified: obj.LastModified.In(time.UTC),
			Size:         int(*obj.Size) - 224, // header + KMS data key
			ETag:         strings.Replace(*obj.ETag, "\"", "", -1),
		})
	}

	if pattern == "" {
		return secrets, nil
	}

	var matched []File
	for _, f := range secrets {
		ok, err := match(pattern, f.Path)
		if err != nil {
			return nil, err
		}

		if ok {
			matched = append(matched, f)
		}
	}
	return matched, nil
}

func match(pattern, name string) (bool, error) {
	for _, s := range strings.Split(pattern, ",") {
		m, err := path.Match(s, name)
		if err != nil {
			return false, err
		}

		if m {
			return true, nil
		}
	}
	return false, nil
}
