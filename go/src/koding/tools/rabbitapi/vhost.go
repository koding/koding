package rabbitapi

import (
	"encoding/json"
)

type Vhost struct {
	Name    string
	Tracing bool
}

// GET /api/vhosts
func (r *Rabbit) GetVhosts() ([]Vhost, error) {
	body, err := r.getRequest("/api/vhosts")
	if err != nil {
		return nil, err
	}

	vhosts := make([]Vhost, 0)
	err = json.Unmarshal(body, &vhosts)
	if err != nil {
		return nil, err
	}

	return vhosts, nil
}

// GET /api/vhost/name
func (r *Rabbit) GetVhost(name string) (Vhost, error) {
	if name == "/" {
		name = "%2f"
	}

	body, err := r.getRequest("/api/vhosts/" + name)
	if err != nil {
		return Vhost{}, err
	}

	vhost := Vhost{}
	err = json.Unmarshal(body, &vhost)
	if err != nil {
		return Vhost{}, err
	}

	return vhost, nil

}

// PUT /api/vhost/name
func (r *Rabbit) CreateVhost(name string) {}

// DELETE /api/vhost/name
func (r *Rabbit) DeleteVhost(name string) {}
