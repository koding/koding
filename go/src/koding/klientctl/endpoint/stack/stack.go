package stack

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"

	"koding/kites/kloud/stack"
	kloudstack "koding/kites/kloud/stack"
	"koding/kites/kloud/utils/object"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/team"

	"github.com/hashicorp/hcl"
	yaml "gopkg.in/yaml.v2"
)

type CreateOptions struct {
	Team        string
	Title       string
	Credentials []string
	Template    []byte
}

func (opts *CreateOptions) Valid() error {
	if opts == nil {
		return errors.New("stack: arguments are missing")
	}

	if len(opts.Template) == 0 {
		return errors.New("stack: template data is missing")
	}

	return nil
}

var DefaultClient = &Client{}

type Client struct {
	Kloud      *kloud.Client
	Credential *credential.Client
}

func (c *Client) Create(opts *CreateOptions) (*stack.ImportResponse, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	data, err := c.jsonReencode(opts.Template)
	if err != nil {
		return nil, fmt.Errorf("stack: template encoding error: %s", err)
	}

	providers, err := kloudstack.ReadProviders(data)
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

	if req.Team == "" {
		req.Team = team.Used().Name
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

	if err := c.kloud().Call("import", req, &resp); err != nil {
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
	var jsonv interface{}

	if err := json.Unmarshal(data, &jsonv); err == nil {
		return jsonMarshal(jsonv)
	}

	var hclv interface{}

	if err := hcl.Unmarshal(data, &hclv); err == nil {
		object.FixHCL(hclv)

		return jsonMarshal(hclv)
	}

	var ymlv interface{}

	if err := yaml.Unmarshal(data, &ymlv); err == nil {
		return jsonMarshal(object.FixYAML(ymlv))
	}

	return nil, errors.New("unknown encoding")
}

func Create(opts *CreateOptions) (*stack.ImportResponse, error) {
	return DefaultClient.Create(opts)
}

func jsonMarshal(v interface{}) ([]byte, error) {
	var buf bytes.Buffer

	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)

	if err := enc.Encode(v); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}
