package do

import "testing"

func TestCredential_Valid(t *testing.T) {
	cred := &Credential{
		AccessToken: "12345",
	}

	err := cred.Valid()
	if err != nil {
		t.Errorf("credential with a valid access token should not give an error, have: %s", err)
	}
}

func TestCredential_Valid_Empty(t *testing.T) {
	cred := &Credential{
		AccessToken: "",
	}

	err := cred.Valid()
	if err == nil {
		t.Errorf("credential with empty access token should give an error")
	}
}

func TestBootstrap_Valid(t *testing.T) {
	bootstrap := &Bootstrap{
		KeyName:        "my-ssh-key",
		KeyID:          "1234567",
		KeyFingerprint: "aa:bb:cc",
	}

	err := bootstrap.Valid()
	if err != nil {
		t.Errorf("bootstrap with a valid data should not give an error, have: %s", err)
	}
}

func TestBootstrap_Valid_Empty(t *testing.T) {
	bootstrap := &Bootstrap{}

	err := bootstrap.Valid()
	if err == nil {
		t.Errorf("bootstrap with empty data should give an error")
	}
}

func TestBootstrap_Valid_NonintegerID(t *testing.T) {
	bootstrap := &Bootstrap{
		KeyName:        "my-ssh-key",
		KeyID:          "NONINTEGERID123",
		KeyFingerprint: "aa:bb:cc",
	}

	err := bootstrap.Valid()
	if err == nil {
		t.Errorf("bootstrap with a non integer key ID should give an error")
	}
}

func TestMetadata_Valid(t *testing.T) {
	metadata := &Metadata{
		DropletID: 12345,
		Region:    "nyc2",
		Size:      "512",
		Image:     "ubuntu-14.04",
	}

	err := metadata.Valid()
	if err != nil {
		t.Errorf("metadata with a valid data should not give an error, have: %s", err)
	}
}

func TestMetadata_Valid_Empty(t *testing.T) {
	metadata := &Metadata{}
	err := metadata.Valid()
	if err == nil {
		t.Errorf("metadata with empty data should give an error")
	}

}

func TestMetadata_Valid_NotValidRegion(t *testing.T) {
	metadata := &Metadata{
		DropletID: 12345,
		Region:    "new york",
		Size:      "512",
		Image:     "ubuntu-14.04",
	}

	err := metadata.Valid()
	if err == nil {
		t.Errorf("metadata with a non valid region data should give an error")
	}
}
