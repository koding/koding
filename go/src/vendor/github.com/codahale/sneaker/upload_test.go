package sneaker

import (
	"bytes"
	"io/ioutil"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/kms"
	"github.com/aws/aws-sdk-go/service/s3"
)

func TestUpload(t *testing.T) {
	fakeKMS := &FakeKMS{
		GenerateOutputs: []kms.GenerateDataKeyOutput{
			{
				CiphertextBlob: []byte("encrypted key"),
				KeyId:          aws.String("key1"),
				Plaintext:      make([]byte, 32),
			},
		},
	}

	fakeS3 := &FakeS3{
		PutOutputs: []s3.PutObjectOutput{
			{},
			{},
		},
	}

	man := Manager{
		Objects: fakeS3,
		Envelope: Envelope{
			KMS: fakeKMS,
		},
		KeyId:             "key1",
		EncryptionContext: map[string]string{"A": "B"},
		Bucket:            "bucket",
		Prefix:            "secrets",
	}

	if err := man.Upload("weeble.txt", strings.NewReader("this is a test")); err != nil {
		t.Fatal(err)
	}

	putReq := fakeS3.PutInputs[0]
	if v, want := *putReq.Bucket, "bucket"; v != want {
		t.Errorf("Bucket was %q, but expected %q", v, want)
	}

	if v, want := *putReq.Key, "secrets/weeble.txt"; v != want {
		t.Errorf("Key was %q, but expected %q", v, want)
	}

	if v, want := *putReq.ContentLength, int64(59); v != want {
		t.Errorf("ContentLength was %d, but expected %d", v, want)
	}

	if v, want := *putReq.ContentType, "application/octet-stream"; v != want {
		t.Errorf("ContentType was %q, but expected %q", v, want)
	}

	actual, err := ioutil.ReadAll(putReq.Body)
	if err != nil {
		t.Fatal(err)
	}

	header := actual[:4]
	if v := []byte{0x00, 0x00, 0x00, 0x0d}; !bytes.Equal(header, v) {
		t.Errorf("Header was %x but expected %x", header, v)
	}

	blob := actual[4 : 13+4]
	if v := []byte("encrypted key"); !bytes.Equal(blob, v) {
		t.Errorf("Blob was %x but expected %x", blob, v)
	}

	ciphertext := actual[13+4:]
	plaintext, err := decrypt(make([]byte, 32), ciphertext, []byte("key1"))
	if err != nil {
		t.Fatal(err)
	}

	if v, want := string(plaintext), "this is a test"; v != want {
		t.Errorf("Plaintext was %x but expected %x", v, want)
	}
}
