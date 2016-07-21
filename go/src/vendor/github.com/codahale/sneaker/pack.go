package sneaker

import (
	"archive/tar"
	"bytes"
	"io"
	"path"
	"time"
)

// Pack puts the given secrets into a TAR file and encrypts that with a new KMS
// data key with the context. The result is written into the given writer.
func (m *Manager) Pack(secrets map[string][]byte, ctxt map[string]string, keyID string, w io.Writer) error {
	if keyID == "" {
		keyID = m.KeyId
	}

	buf := bytes.NewBuffer(nil)
	tw := tar.NewWriter(buf)
	for filename, data := range secrets {
		if err := tw.WriteHeader(&tar.Header{
			Size:       int64(len(data)),
			Uname:      "root",
			Gname:      "root",
			Name:       path.Join(".", filename),
			Mode:       0400,
			ModTime:    time.Now(),
			AccessTime: time.Now(),
			ChangeTime: time.Now(),
		}); err != nil {
			return err
		}

		if _, err := tw.Write(data); err != nil {
			return err
		}
	}

	if err := tw.Close(); err != nil {
		return err
	}

	ciphertext, err := m.Envelope.Seal(keyID, ctxt, buf.Bytes())
	if err != nil {
		return err
	}

	_, err = w.Write(ciphertext)
	return err
}
