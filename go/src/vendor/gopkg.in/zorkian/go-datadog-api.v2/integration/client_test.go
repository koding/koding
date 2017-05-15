package integration

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/zorkian/go-datadog-api"
)

func init() {
	client = initTest()
}

func TestInvalidAuth(t *testing.T) {
	// Override the correct credentials
	c := datadog.NewClient("INVALID", "INVALID")

	valid, err := c.Validate()
	if err != nil {
		t.Fatalf("Testing authentication failed when it shouldn't: %s", err)
	}

	assert.Equal(t, valid, false)
}

func TestValidAuth(t *testing.T) {
	valid, err := client.Validate()

	if err != nil {
		t.Fatalf("Testing authentication failed when it shouldn't: %s", err)
	}

	assert.Equal(t, valid, true)
}
