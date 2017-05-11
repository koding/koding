package countly

import (
	"encoding/json"
	"net/url"
)

type User struct {
	ID              string        `json:"_id,omitempty"`
	FullName        string        `json:"full_name,omitempty"`
	Username        string        `json:"username,omitempty"`
	Password        string        `json:"password,omitempty"`
	Email           string        `json:"email,omitempty"`
	GlobalAdmin     bool          `json:"global_admin,omitempty"`
	CreatedAt       int           `json:"created_at,omitempty"`
	PasswordChanged int           `json:"password_changed,omitempty"`
	Lang            string        `json:"lang,omitempty"`
	APIKey          string        `json:"api_key,omitempty"`
	Language        string        `json:"lang,omitempty"`
	InUserID        string        `json:"in_user_id,omitempty"`
	InUserHash      string        `json:"in_user_hash,omitempty"`
	Offer           int           `json:"offer,omitempty"`
	LastLogin       int           `json:"last_login,omitempty"`
	AdminOf         []interface{} `json:"admin_of,omitempty"`
	UserOf          []interface{} `json:"user_of,omitempty"`
	Locked          bool          `json:"locked,omitempty"`
	IsCurrentUser   bool          `json:"is_current_user,omitempty"`
}

type Users map[string]User

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

func (c *Client) GetUserMe() (*User, error) {
	values := url.Values{}
	values.Add("api_key", c.token)

	v := new(User)
	err := c.do("GET", "/o/users/me", values, &v)
	if err != nil {
		return nil, err
	}

	return v, nil
}

func (c *Client) CreateUser(info *User) (*User, error) {
	values := url.Values{}
	values.Add("api_key", c.token)
	userData, err := json.Marshal(info)
	if err != nil {
		return nil, err
	}
	rawIn := json.RawMessage(userData)
	data, _ := rawIn.MarshalJSON()
	values.Add("args", string(data))

	v := new(User)
	err = c.do("GET", "/i/users/create", values, &v)
	if err != nil {
		return nil, err
	}

	return v, nil
}
