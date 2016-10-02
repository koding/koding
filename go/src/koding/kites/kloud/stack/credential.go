package stack

import (
	"encoding/json"
	"errors"

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
	Template []byte `json:"template,omitempty"`
}

type CredentialItem struct {
	Title      string `json:"title"`
	Identifier string `json:"identifier"`
}

type CredentialListResponse struct {
	Credentials map[string][]CredentialItem
}

type CredentialAddRequest struct {
	Provider string          `json:"provider"`
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
	return nil, nil
}

func (k *Kloud) CredentialAdd(r *kite.Request) (interface{}, error) {
	return nil, nil
}

func (k *Kloud) CredentialRemove(r *kite.Request) (interface{}, error) {
	return nil, nil
}
