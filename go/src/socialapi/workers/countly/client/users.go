package client

import (
	"errors"
	"net/http"
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
func (c *Client) CreateUser(u *User) (*User, error) {
	if err := u.Valid(); err != nil {
		return nil, err
	}

	// override GlobalAdmin since we dont allow creating global admin via api.
	u.GlobalAdmin = false
	u.Language = "en"

	values := url.Values{}
	values.Add("api_key", c.token)
	values = mustAddArgs(values, u)

	v := new(User)
	if err := c.do(http.MethodGet, "/i/users/create", values, &v); err != nil {
		return nil, err
	}

	return v, nil
}

// Users holds response type for GetAllUsers request.
type Users map[string]User

// GetAllUsers gets all the users that are in Countly.
func (c *Client) GetAllUsers() (Users, error) {
	values := url.Values{}
	values.Add("api_key", c.token)

	v := new(Users)
	err := c.do("GET", "/o/users/all", values, &v)
	if err != nil {
		return nil, err
	}
	return *v, nil
}

// Valid checks if user instance is valid for operations.
func (u *User) Valid() error {
	if u.FullName == "" {
		return errors.New("full_name should be set")
	}
	if u.Username == "" {
		return errors.New("username should be set")
	}
	if u.Password == "" {
		return errors.New("password should be set")
	}
	if u.FullName == "" {
		return errors.New("full_name should be set")
	}
	if u.Email == "" {
		return errors.New("email should be set")
	}
	if len(u.UserOf) == 0 {
		return errors.New("UserOf should be set")
	}
	return nil
}
