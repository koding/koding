package sneaker

import (
	"bytes"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/kms"
)

func TestEnvelopeRoundTrip(t *testing.T) {
	fakeKMS := &FakeKMS{
		GenerateOutputs: []kms.GenerateDataKeyOutput{
			{
				CiphertextBlob: []byte("yay"),
				KeyId:          aws.String("key1"),
				Plaintext:      make([]byte, 32),
			},
		},
		DecryptOutputs: []kms.DecryptOutput{
			{
				KeyId:     aws.String("key1"),
				Plaintext: make([]byte, 32),
			},
		},
	}

	envelope := Envelope{
		KMS: fakeKMS,
	}

	ctxt := map[string]string{"A": "B"}
	ciphertext, err := envelope.Seal("yay", ctxt, []byte("this is the plaintext"))
	if err != nil {
		t.Fatal(err)
	}

	plaintext, err := envelope.Open(ctxt, ciphertext)
	if err != nil {
		t.Fatal(err)
	}

	expected := []byte("this is the plaintext")
	if !bytes.Equal(plaintext, expected) {
		t.Errorf("Was %x but expected %x", plaintext, expected)
	}
}
