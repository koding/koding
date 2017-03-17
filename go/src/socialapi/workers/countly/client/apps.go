package client

import (
	"errors"
	"net/url"
)

// App holds info of an app.
type App struct {
	ID        string `json:"_id,omitempty"`
	Category  string `json:"category,omitempty"`
	Country   string `json:"country,omitempty"`
	Key       string `json:"key,omitempty"`
	Name      string `json:"name,omitempty"`
	Timezone  string `json:"timezone,omitempty"`
	Type      string `json:"type,omitempty"`
	CreatedAt int    `json:"created_at,omitempty"`
	EditedAt  int    `json:"edited_at,omitempty"`
	Owner     string `json:"owner,omitempty"`
}

type Apps map[string]App

type AppsResponse struct {
	AdminOf Apps `json:"admin_of,omitempty"`
	UserOf  Apps `json:"user_of,omitempty"`
}

// CreateApp creates an app with admin key.
func (c *Client) CreateApp(app *App) (*App, error) {
	if app.Name == "" {
		return nil, errors.New("app name should be set")
	}
	if app.Key != "" {
		return nil, errors.New("key should not be set")
	}
	if app.Country == "" {
		app.Country = "US"
	}
	if app.Category == "" {
		app.Category = "6"
	}
	if app.Timezone == "" {
		app.Timezone = "Etc/GMT"
	}
	if app.Type == "" {
		app.Type = "web"
	}

	values := url.Values{}
	values.Add("api_key", c.token)
	values = mustAddArgs(values, app)

	v := new(App)
	err := c.do("GET", "/i/apps/create", values, &v)
	if err != nil {
		return nil, err
	}

	return v, nil
}
