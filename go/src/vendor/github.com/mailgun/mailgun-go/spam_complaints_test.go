package mailgun

import (
	"testing"
)

func TestGetComplaints(t *testing.T) {
	domain := reqEnv(t, "MG_DOMAIN")
	apiKey := reqEnv(t, "MG_API_KEY")
	publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
	mg := NewMailgun(domain, apiKey, publicApiKey)
	n, complaints, err := mg.GetComplaints(-1, -1)
	if err != nil {
		t.Fatal(err)
	}
	if len(complaints) != n {
		t.Fatalf("Expected %d complaints; got %d", n, len(complaints))
	}
}

func TestGetComplaintFromRandomNoComplaint(t *testing.T) {
	domain := reqEnv(t, "MG_DOMAIN")
	apiKey := reqEnv(t, "MG_API_KEY")
	publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
	mg := NewMailgun(domain, apiKey, publicApiKey)
	_, err := mg.GetSingleComplaint(randomString(64, "") + "@example.com")
	if err == nil {
		t.Fatal("Expected not-found error for missing complaint")
	}
	ure, ok := err.(*UnexpectedResponseError)
	if !ok {
		t.Fatal("Expected UnexpectedResponseError")
	}
	if ure.Actual != 404 {
		t.Fatalf("Expected 404 response code; got %d", ure.Actual)
	}
}

func TestCreateDeleteComplaint(t *testing.T) {
	domain := reqEnv(t, "MG_DOMAIN")
	apiKey := reqEnv(t, "MG_API_KEY")
	mg := NewMailgun(domain, apiKey, "")
	var check = func(count int) int {
		c, _, err := mg.GetComplaints(DefaultLimit, DefaultSkip)
		if err != nil {
			t.Fatal(err)
		}
		if count != -1 && c != count {
			t.Fatalf("Expected baz@example.com to have %d complaints; got %d", count, c)
		}

		return c
	}

	randomMail := randomString(64, "") + "@example.com"

	origCount := check(-1)
	err := mg.CreateComplaint(randomMail)
	if err != nil {
		t.Fatal(err)
	}

	newCount := check(origCount + 1)

	err = mg.DeleteComplaint(randomMail)
	if err != nil {
		t.Fatal(err)
	}

	check(newCount - 1)
}
