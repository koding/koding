package stack

import (
	"encoding/json"
	"errors"
	"fmt"
	"sort"

	yaml "gopkg.in/yaml.v2"

	"koding/kites/kloud/stack"
	"koding/klientctl/kloud"
	"koding/klientctl/kloud/credential"

	"github.com/hashicorp/hcl"
)

// CreateOptions
type CreateOptions struct {
	Team        string
	Title       string
	Credentials []string
	Data        []byte
}

// Valid
func (opts *CreateOptions) Valid() error {
	if opts == nil {
		return errors.New("stack: arguments are missing")
	}

	if len(opts.Data) == 0 {
		return errors.New("stack: template data is missing")
	}

	return nil
}

// Client
type Client struct {
	Kloud      *kloud.Client
	Credential *credential.Client
}

// Create
func (c *Client) Create(opts *CreateOptions) (*stack.ImportResponse, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	data, err := c.jsonReencode(opts.Data)
	if err != nil {
		return nil, fmt.Errorf("stack: ")
	}

	providers, err := c.readProviders(data)
	if err != nil {
		return nil, fmt.Errorf("stack: unable to read providers: %s", err)
	}

	if len(providers) == 0 {
		return nil, errors.New("stack: unable to read providers")
	}

	req := &stack.ImportRequest{
		Template:    data,
		Team:        opts.Team,
		Title:       opts.Title,
		Credentials: make(map[string][]string),
	}

	var resp stack.ImportResponse

	for _, identifier := range opts.Credentials {
		provider, err := c.credential().Provider(identifier)
		if err != nil {
			return nil, fmt.Errorf("stack: unable to read provider of %q: %s", identifier, err)
		}

		req.Credentials[provider] = append(req.Credentials[provider], identifier)
	}

	used := c.credential().Used()

	for _, provider := range providers {
		if _, ok := req.Credentials[provider]; ok {
			continue
		}

		identifier, ok := used[provider]
		if !ok || identifier == "" {
			return nil, fmt.Errorf("stack: missing credential for %q provider", provider)
		}

		req.Credentials[provider] = []string{identifier}
	}

	if err := c.kloud().Tell("import", req, &resp); err != nil {
		return nil, fmt.Errorf("stack: unable to communicate with Kloud: %s", err)
	}

	return &resp, nil
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}

	return kloud.DefaultClient
}

func (c *Client) credential() *credential.Client {
	if c.Credential != nil {
		return c.Credential
	}

	return credential.DefaultClient
}

func (c *Client) jsonReencode(data []byte) ([]byte, error) {
	var raw json.RawMessage

	if err := json.Unmarshal(data, &raw); err == nil {
		return data, nil
	}

	var ymlv interface{}

	if err := yaml.Unmarshal(data, &ymlv); err == nil {
		return json.Marshal(ymlv)
	}

	var hclv interface{}

	if err := hcl.Unmarshal(data, &hclv); err == nil {
		fixHCL(hclv)

		return json.Marshal(hclv)
	}

	return nil, errors.New("unknown encoding")
}

func (c *Client) readProviders(data []byte) ([]string, error) {
	var v struct {
		Provider map[string]struct{} `json:"provider"`
	}

	if err := json.Unmarshal(data, &v); err != nil {
		return nil, err
	}

	providers := make([]string, len(v.Provider))

	for p := range v.Provider {
		providers = append(providers, p)
	}

	sort.Strings(providers)

	return providers, nil
}

// fixHCL is a best-effort method to "fix" value representation of
// HCL-encoded value, so it can be marshaled to a valid JSON.
//
// hcl.Unmarshal encodes each object as []map[string]interface{},
// and kloud expects JSON objects to not be wrapped in a 1-element
// slice.
//
// This function converts []map[string]interface{} to map[string]interface{}
// if length of the slice is 1.
//
// BUG(rjeczalik): This is going to break templates, which have legit
// 1-element []map[string]interface{} values.
func fixHCL(v interface{}) {
	cur, ok := v.(map[string]interface{})
	if !ok {
		return
	}

	stack := []map[string]interface{}{cur}

	for len(stack) != 0 {
		cur, stack = stack[0], stack[1:]

		for key, val := range cur {
			switch val := val.(type) {
			case []map[string]interface{}:
				if len(val) == 1 {
					cur[key] = val[0]
				}

				for _, val := range val {
					stack = append(stack, val)
				}
			case []interface{}:
				if len(val) == 1 {
					if vval, ok := val[0].(map[string]interface{}); ok {
						cur[key] = vval
					}
				}

				for _, val := range val {
					if vval, ok := val.(map[string]interface{}); ok {
						stack = append(stack, vval)
					}
				}

			case map[string]interface{}:
				stack = append(stack, val)
			}
		}
	}
}
