package sneaker

import (
	"bytes"
	"io/ioutil"
	"reflect"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/kms"
	"github.com/aws/aws-sdk-go/service/s3"
)

func TestDownload(t *testing.T) {
	ciphertext, err := encrypt(make([]byte, 32), []byte("this is a test"), []byte("key1"))
	if err != nil {
		t.Fatal(err)
	}
	ciphertext = append([]byte{
		0x00, 0x00, 0x00, 0x0d, 0x65, 0x6e, 0x63, 0x72, 0x79, 0x70, 0x74, 0x65,
		0x64, 0x20, 0x6b, 0x65, 0x79,
	}, ciphertext...)

	fakeS3 := &FakeS3{
		GetOutputs: []s3.GetObjectOutput{
			{
				Body: ioutil.NopCloser(bytes.NewReader(ciphertext)),
			},
		},
	}
	fakeKMS := &FakeKMS{
		DecryptOutputs: []kms.DecryptOutput{
			{
				KeyId:     aws.String("key1"),
				Plaintext: make([]byte, 32),
			},
		},
	}

	man := Manager{
		Objects: fakeS3,
		Envelope: Envelope{
			KMS: fakeKMS,
		},
		Bucket:            "bucket",
		Prefix:            "secrets",
		EncryptionContext: map[string]string{"A": "B"},
	}

	actual, err := man.Download([]string{"secret1.txt"})
	if err != nil {
		t.Fatal(err)
	}

	expected := map[string][]byte{
		"secret1.txt": []byte("this is a test"),
	}

	if !reflect.DeepEqual(actual, expected) {
		t.Errorf("Result was %#v, but expected %#v", actual, expected)
	}

	getReq := fakeS3.GetInputs[0]
	if v, want := *getReq.Bucket, "bucket"; v != want {
		t.Errorf("Bucket was %q, but expected %q", v, want)
	}

	if v, want := *getReq.Key, "secrets/secret1.txt"; v != want {
		t.Errorf("Key was %q, but expected %q", v, want)
	}
}
