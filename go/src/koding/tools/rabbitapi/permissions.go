package rabbitapi

import (
	"encoding/json"
)

type Permission struct {
	Configure string `json:"configure"`
	Read      string `json:"read"`
	User      string `json:"user"`
	Vhost     string `json:"vhost"`
	Write     string `json:"write"`
}

// GET /api/permissions
func (r *Rabbit) GetPermissions() ([]Permission, error) {
	body, err := r.getRequest("/api/permissions")
	if err != nil {
		return nil, err
	}

	list := make([]Permission, 0)
	err = json.Unmarshal(body, &list)
	if err != nil {
		return nil, err
	}

	return list, nil

}

// GET /api/permissions/vhost/user
func (r *Rabbit) GetPermission(vhost, user string) (Permission, error) {
	if vhost == "/" {
		vhost = "%2f"
	}

	body, err := r.getRequest("/api/permissions/" + vhost + "/" + user)
	if err != nil {
		return Permission{}, err
	}

	permission := Permission{}
	err = json.Unmarshal(body, &permission)
	if err != nil {
		return Permission{}, err
	}

	return permission, nil

}

// PUT /api/permissions/vhost/user configure="" read="" write=""
func (r *Rabbit) CreatePermission(vhost, user, configure, write, read string) error {
	if vhost == "/" {
		vhost = "%2f"
	}

	permission := &Permission{
		Configure: configure,
		Write:     write,
		Read:      read,
	}

	data, err := json.Marshal(permission)
	if err != nil {
		return err
	}

	err = r.putRequest("/api/permissions/"+vhost+"/"+user, data)
	if err != nil {
		return err
	}

	return nil
}

// DELETE /api/permissions/vhost/user
func (r *Rabbit) DeletePermission(vhost, user string) error {
	if vhost == "/" {
		vhost = "%2f"
	}

	err := r.deleteRequest("/api/permissions/" + vhost + "/" + user)
	if err != nil {
		return err
	}

	return nil

}
