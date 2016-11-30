package kontrol

var DefaultClient = &Client{}

type Client struct {
}

type AuthOptions struct {
	Username string
	Hash     string
}

func (c *Client) Auth(opts *AuthOptions) error {
	return nil
}

func Auth(opts *AuthOptions) error { return DefaultClient.Auth(opts) }
