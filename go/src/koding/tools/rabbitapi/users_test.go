package rabbitapi

import (
	"testing"
)

func TestRabbit_GetUsers(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	users, err := r.GetUsers()
	if err != nil {
		t.Error(err)
	} else {
		t.Log("users:", users)
	}
}

func TestRabbit_CreateUser(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	err := r.CreateUser("zeynep", "deneme", "")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("user 'zeynep' created successfull")
	}
}

func TestRabbit_GetUser(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	user, err := r.GetUser("zeynep")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("user 'zeynep':", user)
	}
}

func TestRabbit_DeleteUser(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	err := r.DeleteUser("zeynep")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("user 'zeynep' deleted successfull")
	}
}

func TestRabbit_GetUserPermissions(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	permissions, err := r.GetUserPermissions("guest")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("permissions for user 'guest'", permissions)
	}
}
