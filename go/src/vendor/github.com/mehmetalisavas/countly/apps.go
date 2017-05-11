package countly

import "net/url"

type AppInfo struct {
	ID       string `json:"_id,omitempty"`
	Category string `json:"category,omitempty"`
	Country  string `json:"country,omitempty"`
	Key      string `json:"key,omitempty"`
	Name     string `json:"name,omitempty"`
	Timezone string `json:"timezone,omitempty"`
}

type App map[string]AppInfo

type Apps struct {
	AdminOf App `json:"admin_of,omitempty"`
	UserOf  App `json:"user_of,omitempty"`
}

func (c *Client) GetAllApps() (Apps, error) {
	values := url.Values{}
	values.Add("api_key", c.token)

	v := new(Apps)
	err := c.do("GET", "/o/apps/all", values, &v)
	if err != nil {
		return *v, err
	}

	return *v, nil
}

func (c *Client) GetMyApps() (Apps, error) {
	values := url.Values{}
	values.Add("api_key", c.token)

	v := new(Apps)
	err := c.do("GET", "/o/apps/mine", values, &v)
	if err != nil {
		return *v, err
	}

	return *v, nil
}
