package sneaker

import (
	"bytes"
	"io"
	"io/ioutil"
)

// Unpack decrypts the secrets using KMS and the given context, returning an
// io.Reader containing a TAR file with all the secrets.
func (m *Manager) Unpack(ctxt map[string]string, r io.Reader) (io.Reader, error) {
	ciphertext, err := ioutil.ReadAll(r)
	if err != nil {
		return nil, err
	}

	plaintext, err := m.Envelope.Open(ctxt, ciphertext)
	if err != nil {
		return nil, err
	}

	return bytes.NewReader(plaintext), nil
}
