package stack

import (
	"encoding/json"
	"errors"

	"koding/kites/kloud/credential"
	"koding/kites/kloud/utils/object"

	"github.com/koding/kite"
)

type CredentialDescribeRequest struct {
	Provider string `json:"provider,omitempty"`
	Template []byte `json:"template,omitempty"`
}

type CredentialDescribeResponse struct {
	Description map[string]*Description `json:"description"`
}

type Description struct {
	Provider   string  `json:"provider,omitempty"`
	Credential []Value `json:"credential"`
	Bootstrap  []Value `json:"bootstrap,omitempty"`
}

type Enumer interface {
	Enum() []*Enum
}

type EnumTitler interface {
	Title() string
}

type Enum struct {
	Title string      `json:"title"`
	Value interface{} `json:"value"`
}

type Value struct {
	Name     string `json:"name"`
	Type     string `json:"type"`
	Label    string `json:"label"`
	Secret   bool   `json:"secret"`
	ReadOnly bool   `json:"readOnly"`
	Values   []Enum `json:"values"`
}

type CredentialListRequest struct {
	Provider string `json:"provider,omitempty"`
	Team     string `json:"team,omitempty"`
	Template []byte `json:"template,omitempty"`
}

type CredentialItem struct {
	Title      string `json:"title"`
	Team       string `json:"team,omitempty"`
	Identifier string `json:"identifier"`
}

type CredentialListResponse struct {
	Credentials map[string][]CredentialItem
}

type CredentialAddRequest struct {
	Provider string          `json:"provider"`
	Team     string          `json:"team,omitempty"`
	Title    string          `json:"title,omitempty"`
	Data     json.RawMessage `json:"data"`
}

type CredentialAddResponse struct {
	Title      string `json:"title"`
	Identifier string `json:"identifier"`
}

type CredentialRemoveRequest struct {
	Provider   string `json:"provider"`
	Identifier string `json:"identifier"`
}

func (k *Kloud) CredentialDescribe(r *kite.Request) (interface{}, error) {
	var req CredentialDescribeRequest

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	// TODO: add support for reading the provider names by parsing
	// the req.Template.

	desc := k.DescribeFunc(req.Provider)

	if len(desc) == 0 {
		return nil, errors.New("no provider found")
	}

	return &CredentialDescribeResponse{
		Description: desc,
	}, nil
}

func (k *Kloud) CredentialList(r *kite.Request) (interface{}, error) {
	var req CredentialListRequest

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	f := &credential.Filter{
		User:     r.Username,
		Team:     req.Team,
		Provider: req.Provider,
	}

	creds, err := k.CredClient.Creds(f)
	if err != nil {
		return nil, err
	}

	resp := &CredentialListResponse{
		Credentials: make(map[string][]CredentialItem),
	}

	for _, cred := range creds {
		c := resp.Credentials[cred.Provider]

		c = append(c, CredentialItem{
			Title:      cred.Title,
			Team:       cred.Team,
			Identifier: cred.Ident,
		})

		resp.Credentials[cred.Provider] = c
	}

	return resp, nil
}

func (k *Kloud) CredentialAdd(r *kite.Request) (interface{}, error) {
	var req CredentialAddRequest

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	if req.Provider == "" {
		return nil, NewError(ErrProviderIsMissing)
	}

	p, ok := k.providers[req.Provider]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	c := &credential.Cred{
		Provider: req.Provider,
		Title:    req.Title,
		Team:     req.Team,
	}

	if len(req.Data) != 0 {
		var data interface{}

		cred := p.NewCredential()
		boot := p.NewBootstrap()

		if boot != nil {
			data = object.Inline(cred, boot)
		} else {
			data = cred
		}

		if err := json.Unmarshal(req.Data, data); err != nil {
			return nil, err
		}
	}

	if err := k.CredClient.SetCred(r.Username, c); err != nil {
		return nil, err
	}

	return &CredentialAddResponse{
		Title:      c.Title,
		Identifier: c.Ident,
	}, nil
}
