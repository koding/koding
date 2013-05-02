package rabbitapi

import (
	"encoding/json"
)

type User struct {
	Name         string
	PasswordHash string `json:"password_hash"`
	Tags         string
}

type UserCreate struct {
	Password string `json:"password"`
	Tags     string `json:"tags"`
}

// GET /api/users
func (r *Rabbit) GetUsers() ([]User, error) {
	body, err := r.getRequest("/api/users")
	if err != nil {
		return nil, err
	}

	users := make([]User, 0)
	err = json.Unmarshal(body, &users)
	if err != nil {
		return nil, err
	}

	return users, nil

}

// GET /api/users/name
func (r *Rabbit) GetUser(name string) (User, error) {
	body, err := r.getRequest("/api/users/" + name)
	if err != nil {
		return User{}, err
	}

	user := User{}
	err = json.Unmarshal(body, &user)
	if err != nil {
		return User{}, err
	}

	return user, nil
}

// PUT /api/users/name password=secret tags=""
func (r *Rabbit) CreateUser(name, password string, tags string) error {
	user := &UserCreate{
		Password: password,
		Tags:     tags,
	}

	data, err := json.Marshal(user)
	if err != nil {
		return err
	}

	err = r.putRequest("/api/users/"+name, data)
	if err != nil {
		return err
	}

	return nil
}

// DELETE /api/users/name
func (r *Rabbit) DeleteUser(name string) error {
	err := r.deleteRequest("/api/users/" + name)
	if err != nil {
		return err
	}

	return nil
}

// GET /api/users/name/permissions
func (r *Rabbit) GetUserPermissions(name string) ([]Permission, error) {
	body, err := r.getRequest("/api/users/" + name + "/permissions")
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
