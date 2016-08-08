package sneaker

import (
	"bytes"
	"io/ioutil"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/kms"
	"github.com/aws/aws-sdk-go/service/s3"
)

func TestRotate(t *testing.T) {
	oldKey := func() []byte {
		return make([]byte, 32)
	}

	newKey := func() []byte {
		k := oldKey()
		k[0] = 100
		return k
	}

	oldCiphertext := []byte{
		0x00, 0x00, 0x00, 0x0d, 0x65, 0x6e, 0x63, 0x72, 0x79, 0x70, 0x74, 0x65,
		0x64, 0x20, 0x6b, 0x65, 0x79, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0xba, 0xcf, 0x29, 0x4e, 0x6d, 0x09, 0x18,
		0x4e, 0x66, 0x6e, 0xb1, 0xb6, 0xc9, 0x87, 0x65, 0xcc, 0xe1, 0x06, 0x8c,
		0xbf, 0x7f, 0xdd, 0x5d, 0x70, 0x4e, 0x3d, 0xbf, 0xd5, 0x44, 0xec,
	}

	fakeS3 := &FakeS3{
		ListOutputs: []s3.ListObjectsOutput{
			{
				Contents: []*s3.Object{
					{
						Key:          aws.String("secrets/weeble.txt"),
						ETag:         aws.String(`"etag1"`),
						Size:         aws.Int64(1004),
						LastModified: aws.Time(time.Date(2006, 1, 2, 15, 4, 5, 0, time.UTC)),
					},
				},
			},
		},
		GetOutputs: []s3.GetObjectOutput{
			{
				Body: ioutil.NopCloser(bytes.NewReader(oldCiphertext)),
			},
		},
		PutOutputs: []s3.PutObjectOutput{
			{},
			{},
		},
	}
	fakeKMS := &FakeKMS{
		DecryptOutputs: []kms.DecryptOutput{
			{
				KeyId:     aws.String("key1"),
				Plaintext: oldKey(),
			},
		},
		GenerateOutputs: []kms.GenerateDataKeyOutput{
			{
				CiphertextBlob: []byte("encrypted new key"),
				KeyId:          aws.String("key1"),
				Plaintext:      newKey(),
			},
		},
	}

	man := Manager{
		Objects: fakeS3,
		Envelope: Envelope{
			KMS: fakeKMS,
		},
		KeyId:  "key1",
		Bucket: "bucket",
		Prefix: "secrets",
	}

	if err := man.Rotate("", nil); err != nil {
		t.Fatal(err)
	}

	// KMS request

	genReq := fakeKMS.GenerateInputs[0]
	if v, want := *genReq.KeyId, "key1"; v != want {
		t.Errorf("Key ID was %q, but expected %q", v, want)
	}

	if v, want := *genReq.KeySpec, "AES_256"; v != want {
		t.Errorf("Key spec was %v, but expected %v", v, want)
	}

	putReq := fakeS3.PutInputs[0]
	if v, want := *putReq.Bucket, "bucket"; v != want {
		t.Errorf("Bucket was %q, but expected %q", v, want)
	}

	if v, want := *putReq.Key, "secrets/weeble.txt"; v != want {
		t.Errorf("Key was %q, but expected %q", v, want)
	}

	if v, want := *putReq.ContentLength, int64(63); v != want {
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
	if v := []byte{0x00, 0x00, 0x00, 0x11}; !bytes.Equal(header, v) {
		t.Errorf("Header was %x but expected %x", header, v)
	}

	blob := actual[4 : 17+4]
	if v := []byte("encrypted new key"); !bytes.Equal(blob, v) {
		t.Errorf("Blob was %x but expected %x", blob, v)
	}

	ciphertext := actual[17+4:]
	plaintext, err := decrypt(newKey(), ciphertext, []byte("key1"))
	if err != nil {
		t.Fatal(err)
	}

	if v, want := string(plaintext), "this is a test"; v != want {
		t.Errorf("Plaintext was %x but expected %x", v, want)
	}
}
