package mailgun

import (
	"crypto/rand"
	"os"
	"testing"
)

// Many tests require configuration settings unique to the user, passed in via
// environment variables.  If these variables aren't set, we need to fail the test early.
func reqEnv(t *testing.T, variableName string) string {
	value := os.Getenv(variableName)
	if value == "" {
		t.Fatalf("Expected environment variable %s to be set", variableName)
	}
	return value
}

// randomString generates a string of given length, but random content.
// All content will be within the ASCII graphic character set.
// (Implementation from Even Shaw's contribution on
// http://stackoverflow.com/questions/12771930/what-is-the-fastest-way-to-generate-a-long-random-string-in-go).
func randomString(n int, prefix string) string {
	const alphanum = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	var bytes = make([]byte, n)
	rand.Read(bytes)
	for i, b := range bytes {
		bytes[i] = alphanum[b%byte(len(alphanum))]
	}
	return prefix + string(bytes)
}

func spendMoney(t *testing.T, tFunc func()) {
	ok := os.Getenv("MG_SPEND_MONEY")
	if ok != "" {
		tFunc()
	} else {
		t.Log("Money spending not allowed, not running function.")
	}
}
