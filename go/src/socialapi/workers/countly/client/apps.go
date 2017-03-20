package client

import (
	"errors"
	"net/http"
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

// Apps holds map[appName]App. This is how Countly responds.
type Apps map[string]App

// AppsResponse is the collection of Admin and User apps of the current token.
type AppsResponse struct {
	AdminOf Apps `json:"admin_of,omitempty"`
	UserOf  Apps `json:"user_of,omitempty"`
}

// Valid checks if app instance is valid for operations.
func (a *App) Valid() error {
	if a.Name == "" {
		return errors.New("app name should be set")
	}
	if a.Key != "" {
		return errors.New("key should not be set")
	}
	if a.Country == "" {
		a.Country = "US"
	}
	if a.Category == "" {
		a.Category = "6"
	}
	if a.Timezone == "" {
		a.Timezone = "Etc/GMT"
	}
	if a.Type == "" {
		a.Type = "web"
	}
	return nil
}

// CreateApp creates an app with admin key.
func (c *Client) CreateApp(app *App) (*App, error) {
	if err := app.Valid(); err != nil {
		return nil, err
	}

	values := url.Values{}
	values.Add("api_key", c.token)
	values = mustAddArgs(values, app)

	v := new(App)
	err := c.do(http.MethodGet, "/i/apps/create", values, &v)
	if err != nil {
		return nil, err
	}

	return v, nil
}
