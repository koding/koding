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
