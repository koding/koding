package stack

import (
	"context"
	"encoding/json"
	"errors"
	"sort"

	"koding/kites/kloud/credential"
	"koding/kites/kloud/utils/object"

	"github.com/koding/kite"
)

// CredentialDescribeRequest represents a request
// value for "credential.describe" kloud method.
type CredentialDescribeRequest struct {
	Provider string `json:"provider,omitempty"`
	Template []byte `json:"template,omitempty"`
}

// CredentialDescribeResponse represents a response
// value from "credential.describe" kloud method.
type CredentialDescribeResponse struct {
	Description Descriptions `json:"description"`
}

// Description describes Credential and Bootstrap
// types used by a given provider.
type Description struct {
	Provider   string   `json:"provider,omitempty"`
	Credential []Value  `json:"credential"`
	Bootstrap  []Value  `json:"bootstrap,omitempty"`
	UserData   []string `json:"userData,omitempty"`
	CloudInit  bool     `json:"cloudInit"`
}

// Descriptions maps credential description per provider.
type Descriptions map[string]*Description

// Slice converts d to *Description slice.
func (d Descriptions) Slice() []*Description {
	keys := make([]string, 0, len(d))

	for k := range d {
		keys = append(keys, k)
	}

	sort.Strings(keys)

	slice := make([]*Description, 0, len(d))

	for _, key := range keys {
		desc := *d[key]
		desc.Provider = key
		slice = append(slice, &desc)
	}

	return slice
}

// Enumer represents a value, that can have
// a limited set of values.
//
// It is used to create drop-down lists
// or suggest possible value to the user.
type Enumer interface {
	Enums() []Enum
}

// Enum is a description of a single enum value.
type Enum struct {
	Title string      `json:"title,omitempty"`
	Value interface{} `json:"value"`
}

// Enums is an enum list.
type Enums []Enum

// Contains gives true if enums contains the given value.
func (e Enums) Contains(value interface{}) bool {
	for _, e := range e {
		if e.Value == value {
			return true
		}
	}
	return false
}

// Values gives all enums' values.
func (e Enums) Values() []interface{} {
	v := make([]interface{}, len(e))
	for i := range e {
		v[i] = e[i].Value
	}
	return v
}

// Titles gives all enums' titles.
func (e Enums) Titles() []string {
	t := make([]string, len(e))
	for i := range e {
		t[i] = e[i].Title
	}
	return t
}

// Value represents a description of a single
// field within Bootstrap or Credential struct.
type Value struct {
	Name     string `json:"name"`
	Type     string `json:"type"`
	Label    string `json:"label"`
	Secret   bool   `json:"secret"`
	ReadOnly bool   `json:"readOnly"`
	Values   Enums  `json:"values,omitempty"`
}

// CredentialListRequest represents a request
// value for "credential.list" kloud method.
type CredentialListRequest struct {
	Provider string `json:"provider,omitempty"`
	Team     string `json:"team,omitempty"`
	Template []byte `json:"template,omitempty"`

	Impersonate string `json:"impersonate"`
}

// CredentialItem represents a single credential
// metadata.
type CredentialItem struct {
	Identifier string `json:"identifier"`
	Title      string `json:"title"`
	Team       string `json:"team,omitempty"`
	Provider   string `json:"provider,omitempty"`
}

// CredentialListResponse represents a response
// value for "credential.list" kloud method.
type CredentialListResponse struct {
	Credentials Credentials `json:"credentials"`
}

// Credentials represents a collection of user's credentials.
type Credentials map[string][]CredentialItem

// ToSlice converts credentials to a slice sorted by a provider name.
func (c Credentials) ToSlice() []CredentialItem {
	n, providers := 0, make([]string, 0, len(c))

	for provider, creds := range c {
		providers = append(providers, provider)
		n += len(creds)
	}

	sort.Strings(providers)

	creds := make([]CredentialItem, 0, n)

	for _, provider := range providers {
		for _, cred := range c[provider] {
			cred.Provider = provider

			creds = append(creds, cred)
		}
	}

	return creds
}

// ByProvider filters credentials by the given provider.
func (c Credentials) ByProvider(provider string) Credentials {
	if provider == "" {
		return c
	}

	items, ok := c[provider]
	if !ok || len(items) == 0 {
		return nil
	}

	return Credentials{provider: items}
}

// ByTeam filters credentials by the given team.
func (c Credentials) ByTeam(team string) Credentials {
	if team == "" {
		return c
	}

	f := make(Credentials)

	for provider, creds := range c {
		var filtered []CredentialItem

		for _, cred := range creds {
			if cred.Team != "" && cred.Team != team {
				continue
			}

			filtered = append(filtered, cred)
		}

		if len(filtered) != 0 {
			f[provider] = filtered
		}
	}

	return f
}

// Find looks for a credential with the given identifier.
func (c Credentials) Find(identifier string) (cred CredentialItem, ok bool) {
	for provider, creds := range c {
		for _, cred := range creds {
			if cred.Identifier == identifier {
				cred.Provider = provider
				return cred, true
			}
		}
	}

	return
}

// Provider gives a provider name for the given identifier.
//
// If no credential with the given identifier is found,
// an empty string is returned.
func (c *CredentialListResponse) Provider(identifier string) string {
	for provider, credentials := range c.Credentials {
		for _, credential := range credentials {
			if credential.Identifier == identifier {
				return provider
			}
		}
	}

	return ""
}

// CredentialAddRequest represents a request
// value for "credential.add" kloud method.
type CredentialAddRequest struct {
	Provider string          `json:"provider"`
	Team     string          `json:"team,omitempty"`
	Title    string          `json:"title,omitempty"`
	Data     json.RawMessage `json:"data"`

	Impersonate string `json:"impersonate"`
}

// CredentialAddResponse represents a response
// value for "credential.add" kloud method.
type CredentialAddResponse struct {
	Title      string `json:"title"`
	Identifier string `json:"identifier"`
}

// CredentialDescribe is a kite.Handler for "credential.describe" kite method.
func (k *Kloud) CredentialDescribe(r *kite.Request) (interface{}, error) {
	var req CredentialDescribeRequest

	if r.Args != nil {
		if err := r.Args.One().Unmarshal(&req); err != nil {
			return nil, err
		}
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

// CredentialList is a kite.Handler for "credential.list" kite method.
func (k *Kloud) CredentialList(r *kite.Request) (interface{}, error) {
	var req CredentialListRequest

	if r.Args != nil {
		if err := r.Args.One().Unmarshal(&req); err != nil {
			return nil, err
		}
	}

	if IsKloudSecretAuth(r, k.SecretKey) {
		// kloudctl is not authenticated with username, let it overwrite it
		r.Username = req.Impersonate
	}

	f := &credential.Filter{
		Username: r.Username,
		Teamname: req.Team,
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

// CredentialAdd is a kite.Handler for "credential.add" kite method.
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

	if IsKloudSecretAuth(r, k.SecretKey) {
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

	cred := p.NewCredential()
	boot := p.NewBootstrap()

	if boot != nil {
		c.Data = object.Inline(cred, boot)
	} else {
		c.Data = cred
	}

	if err := json.Unmarshal(req.Data, c.Data); err != nil {
		return nil, err
	}

	if v, ok := cred.(Validator); ok {
		if err := v.Valid(); err != nil {
			return nil, err
		}
	}

	if err := k.CredClient.SetCred(r.Username, c); err != nil {
		return nil, err
	}

	teamReq := &TeamRequest{
		Provider:   req.Provider,
		GroupName:  req.Team,
		Identifier: c.Ident,
	}

	kiteReq := &kite.Request{
		Method:   "bootstrap",
		Username: r.Username,
	}

	s, ctx, err := k.newStack(kiteReq, teamReq)
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
