package rabbitapi

import (
	"testing"
)

func TestRabbit_GetVhosts(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	vhosts, err := r.GetVhosts()
	if err != nil {
		t.Error(err)
	} else {
		t.Log("vhosts:", vhosts)
	}

}

func TestRabbit_GetVhost(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")

	vhost, err := r.GetVhost("/")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("vhost '/':", vhost)
	}

}

func TestRabbit_GetUsers(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	users, err := r.GetUsers()
	if err != nil {
		t.Error(err)
	} else {
		t.Log("users:", users)
	}
}

func TestRabbit_GetUser(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	user, err := r.GetUser("guest")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("user 'guest':", user)
	}
}

func TestRabbit_PutUser(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	err := r.PutUser("zeynep", "deneme", "")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("user created successfull")
	}
}

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
