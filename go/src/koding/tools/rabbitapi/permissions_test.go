package rabbitapi

import (
	"testing"
)

func TestRabbit_GetPermissions(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	permissions, err := r.GetPermissions()
	if err != nil {
		t.Error(err)
	} else {
		t.Log("Permissions:", permissions)
	}
}

func TestRabbit_GetPermission(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	permission, err := r.GetPermission("/", "guest")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("permission for vhost '/' and user 'guest':", permission)
	}
}

func TestRabbit_CreatePermission(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")

	// Needed for creating permissions
	err := r.CreateUser("zeynep", "deneme", "")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("user 'zeynep created successfull")
	}

	err = r.CreatePermission("/", "zeynep", ".*", ".*", ".*")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("permission for user 'zeynep' is created successfull")
	}
}

func TestRabbit_DeletePermission(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")

	err := r.DeletePermission("/", "zeynep")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("permission for user 'zeynep' is deleted successfull")
	}
}
