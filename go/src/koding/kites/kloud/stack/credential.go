package stack

import (
	"context"
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

	Impersonate string `json:"impersonate"`
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

	Impersonate string `json:"impersonate"`
}

type CredentialAddResponse struct {
	Title      string `json:"title"`
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

	if IsKloudctlAuth(r, k.SecretKey) {
		// kloudctl is not authenticated with username, let it overwrite it
		r.Username = req.Impersonate
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

	if len(req.Data) == 0 {
		return nil, NewError(ErrCredentialIsMissing)
	}

	if IsKloudctlAuth(r, k.SecretKey) {
		r.Username = req.Impersonate
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

	if v, ok := cred.(Validator); ok {
		if err := v.Valid(); err != nil {
			return nil, err
		}
	}

	if v, ok := boot.(Validator); ok {
		if err := v.Valid(); err != nil {
			return nil, err
		}
	}

	if err := k.CredClient.SetCred(r.Username, c); err != nil {
		return nil, err
	}

	if err := k.CredClient.Lock(c); err != nil {
		return nil, err
	}

	defer k.CredClient.Unlock(c)

	teamReq := &TeamRequest{
		Provider:   req.Provider,
		GroupName:  req.Team,
		Identifier: c.Ident,
	}

	kiteReq := &kite.Request{
		Method:   "bootstrap",
		Username: r.Username,
	}

	s, ctx, err := k.NewStack(p, kiteReq, teamReq)
	if err != nil {
		return nil, err
	}

	bootReq := &BootstrapRequest{
		Provider:    req.Provider,
		Identifiers: []string{c.Ident},
		GroupName:   req.Team,
	}

	ctx = context.WithValue(ctx, BootstrapRequestKey, bootReq)

	credential := &Credential{
		Provider:   c.Provider,
		Title:      c.Title,
		Identifier: c.Ident,
		Credential: cred,
		Bootstrap:  boot,
	}

	if err := s.VerifyCredential(credential); err != nil {
		return nil, err
	}

	if _, err := s.HandleBootstrap(ctx); err != nil {
		return nil, err
	}

	return &CredentialAddResponse{
		Title:      c.Title,
		Identifier: c.Ident,
	}, nil
}
