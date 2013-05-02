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

func TestRabbit_CreateVhost(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	err := r.CreateVhost("fatih")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("vhost 'fatih' created successfull")
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

	vhost, err = r.GetVhost("fatih")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("vhost 'fatih':", vhost)
	}

}

func TestRabbit_DeleteVhost(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")
	err := r.DeleteVhost("fatih")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("vhost 'fatih' deleted successfull")
	}
}

func TestRabbit_GetVhostPermissions(t *testing.T) {
	r := Auth("guest", "guest", "http://localhost:15672")

	permissions, err := r.GetVhostPermissions("/")
	if err != nil {
		t.Error(err)
	} else {
		t.Log("permissions for vhost '/':", permissions)
	}
}
