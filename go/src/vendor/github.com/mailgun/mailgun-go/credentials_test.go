package mailgun

import (
	"fmt"
	"testing"
)

func TestGetCredentials(t *testing.T) {
	domain := reqEnv(t, "MG_DOMAIN")
	apiKey := reqEnv(t, "MG_API_KEY")
	mg := NewMailgun(domain, apiKey, "")
	n, cs, err := mg.GetCredentials(DefaultLimit, DefaultSkip)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Login\tCreated At\t\n")
	for _, c := range cs {
		t.Logf("%s\t%s\t\n", c.Login, c.CreatedAt)
	}
	t.Logf("%d credentials listed out of %d\n", len(cs), n)
}

func TestCreateDeleteCredentials(t *testing.T) {
	domain := reqEnv(t, "MG_DOMAIN")
	apiKey := reqEnv(t, "MG_API_KEY")
	mg := NewMailgun(domain, apiKey, "")
	randomPassword := randomString(16, "pw")
	randomID := randomString(16, "usr")
	randomLogin := fmt.Sprintf("%s@%s", randomID, domain)

	err := mg.CreateCredential(randomLogin, randomPassword)
	if err != nil {
		t.Fatal(err)
	}

	err = mg.ChangeCredentialPassword(randomID, randomString(16, "pw2"))
	if err != nil {
		t.Fatal(err)
	}

	err = mg.DeleteCredential(randomID)
	if err != nil {
		t.Fatal(err)
	}
}
