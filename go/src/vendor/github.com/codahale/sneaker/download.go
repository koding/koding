package sneaker

import (
	"io/ioutil"
	fpath "path"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"
)

// Download fetches and decrypts the given secrets.
func (m *Manager) Download(paths []string) (map[string][]byte, error) {
	secrets := make(map[string][]byte, len(paths))
	for _, path := range paths {
		resp, err := m.Objects.GetObject(&s3.GetObjectInput{
			Bucket: aws.String(m.Bucket),
			Key:    aws.String(fpath.Join(m.Prefix, path)),
		})
		if err != nil {
			return nil, err
		}
		defer resp.Body.Close()

		ciphertext, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, err
		}

		plaintext, err := m.Envelope.Open(m.context(path), ciphertext)
		if err != nil {
			return nil, err
		}

		secrets[path] = plaintext
	}
	return secrets, nil
}
