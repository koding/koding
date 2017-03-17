package client

import (
	"errors"
	"net/url"
)

// User holds info of a user that is registered to countly server.
type User struct {
	ID              string   `json:"_id,omitempty"`
	FullName        string   `json:"full_name,omitempty"`
	Username        string   `json:"username,omitempty"`
	Password        string   `json:"password,omitempty"`
	Email           string   `json:"email,omitempty"`
	GlobalAdmin     bool     `json:"global_admin,omitempty"`
	CreatedAt       int      `json:"created_at,omitempty"`
	PasswordChanged int      `json:"password_changed,omitempty"`
	Lang            string   `json:"lang,omitempty"`
	APIKey          string   `json:"api_key,omitempty"`
	Language        string   `json:"lang,omitempty"`
	InUserID        string   `json:"in_user_id,omitempty"`
	InUserHash      string   `json:"in_user_hash,omitempty"`
	Offer           int      `json:"offer,omitempty"`
	LastLogin       int      `json:"last_login,omitempty"`
	AdminOf         []string `json:"admin_of,omitempty"`
	UserOf          []string `json:"user_of,omitempty"`
	Locked          bool     `json:"locked,omitempty"`
	IsCurrentUser   bool     `json:"is_current_user,omitempty"`
}

// CreateUser creates a user with admin credentials.
func (c *Client) CreateUser(info *User) (*User, error) {
	if info.FullName == "" {
		return nil, errors.New("full_name should be set")
	}
	if info.Username == "" {
		return nil, errors.New("username should be set")
	}
	if info.Password == "" {
		return nil, errors.New("password should be set")
	}
	if info.FullName == "" {
		return nil, errors.New("full_name should be set")
	}
	if info.Email == "" {
		return nil, errors.New("email should be set")
	}
	if len(info.UserOf) == 0 {
		return nil, errors.New("UserOf should be set")
	}
	// override GlobalAdmin since we dont allow creating global admin via api.
	info.GlobalAdmin = false
	info.Language = "en"

	values := url.Values{}
	values.Add("api_key", c.token)
	values = mustAddArgs(values, info)

	v := new(User)
	if err := c.do("GET", "/i/users/create", values, &v); err != nil {
		return nil, err
	}

	return v, nil
}
