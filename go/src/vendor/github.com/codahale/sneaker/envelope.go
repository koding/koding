package sneaker

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/binary"
	"fmt"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/kms"
)

// An Envelope encrypts and decrypts secrets with single-use KMS data keys using
// AES-256-GCM.
type Envelope struct {
	KMS KeyManagement
}

// Seal generates a 256-bit data key using KMS and encrypts the given plaintext
// with AES-256-GCM using a random nonce. The ciphertext is appended to the
// nonce, which is in turn appended to the KMS data key ciphertext and returned.
func (e *Envelope) Seal(keyID string, ctxt map[string]string, plaintext []byte) ([]byte, error) {
	key, err := e.KMS.GenerateDataKey(&kms.GenerateDataKeyInput{
		EncryptionContext: e.context(ctxt),
		KeySpec:           aws.String("AES_256"),
		KeyId:             &keyID,
	})
	if err != nil {
		return nil, err
	}

	ciphertext, err := encrypt(key.Plaintext, plaintext, []byte(*key.KeyId))
	if err != nil {
		return nil, err
	}

	return join(key.CiphertextBlob, ciphertext), nil
}

// Open takes the output of Seal and decrypts it. If any part of the ciphertext
// or context is modified, Seal will return an error instead of the decrypted
// data.
func (e *Envelope) Open(ctxt map[string]string, ciphertext []byte) ([]byte, error) {
	key, ciphertext := split(ciphertext)

	d, err := e.KMS.Decrypt(&kms.DecryptInput{
		CiphertextBlob:    key,
		EncryptionContext: e.context(ctxt),
	})
	if err != nil {
		if apiErr, ok := err.(awserr.Error); ok {
			if apiErr.Code() == "InvalidCiphertextException" {
				return nil, fmt.Errorf("unable to decrypt data key")
			}
		}
		return nil, err
	}

	return decrypt(d.Plaintext, ciphertext, []byte(*d.KeyId))
}

func (e *Envelope) context(c map[string]string) map[string]*string {
	ctxt := make(map[string]*string)
	for k, v := range c {
		ctxt[k] = aws.String(v)
	}
	return ctxt
}

func decrypt(key, ciphertext, data []byte) ([]byte, error) {
	defer zero(key)

	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	nonce, ciphertext := ciphertext[:gcm.NonceSize()], ciphertext[gcm.NonceSize():]

	return gcm.Open(nil, nonce, ciphertext, data)
}

func encrypt(key, plaintext, data []byte) ([]byte, error) {
	defer zero(key)

	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return nil, err
	}

	return gcm.Seal(nonce, nonce, plaintext, data), nil
}

func join(a, b []byte) []byte {
	res := make([]byte, len(a)+len(b)+4)
	binary.BigEndian.PutUint32(res, uint32(len(a)))
	copy(res[4:], a)
	copy(res[len(a)+4:], b)
	return res
}

func split(v []byte) ([]byte, []byte) {
	l := binary.BigEndian.Uint32(v)
	return v[4 : 4+l], v[4+l:]
}

func zero(b []byte) {
	for i := range b {
		b[i] = 0
	}
}
