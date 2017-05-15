package integration

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/zorkian/go-datadog-api"
)

func init() {
	client = initTest()
}

func TestUserCreateAndDelete(t *testing.T) {
	handle := "test@example.com"
	name := "tester"

	user, err := client.CreateUser(datadog.String(handle), datadog.String(name))
	if err != nil {
		t.Fatalf("Failed to create user: %s", err)
	}
	if user == nil {
		t.Fatalf("CreateUser did not return an user.")
	}

	defer func() {
		err := client.DeleteUser(handle)
		if err != nil {
			t.Fatalf("Failed to delete user: %s", err)
		}
	}()

	assert.Equal(t, *user.Handle, handle)
	assert.Equal(t, *user.Name, name)

	newUser, err := client.GetUser(handle)
	if err != nil {
		t.Fatalf("Failed to get user: %s", err)
	}

	assert.Equal(t, *newUser.Handle, handle)
	assert.Equal(t, *newUser.Name, name)
}
