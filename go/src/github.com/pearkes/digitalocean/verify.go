package digitalocean

import (
	"fmt"
)

// VerifyAuthentication makes a simple request to verify
// the provided authentication is working and returns
// an error if it is not.
func (c *Client) VerifyAuthentication() error {
	req, err := c.NewRequest(map[string]string{}, "GET", "/droplets")

	if err != nil {
		return err
	}

	resp, err := checkResp(c.Http.Do(req))

	if err != nil {
		return fmt.Errorf("Error verfiying authentication: %s", parseErr(resp))
	}

	// The request was successful
	return nil
}
