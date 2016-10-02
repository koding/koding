package stack

import (
	"encoding/json"

	"github.com/koding/kite"
)

type CredentialDescribeRequest struct {
	Provider string `json:"provider,omitempty"`
	Template []byte `json:"template,omitempty"`
}

type CredentialDescribeResponse struct {
	Descriptions map[string]*Description `json:"descriptions"`
}

type Description struct {
	Provider   string  `json:"provider,omitempty"`
	Credential []Value `json:"credential"`
	Bootstrap  []Value `json:"bootstrap,omitempty"`
}

type EnumValue struct {
	Title string      `json:"title"`
	Value interface{} `json:"value"`
}

type Value struct {
	Type     string      `json:"type"`
	Label    string      `json:"label"`
	Secret   bool        `json:"secret"`
	ReadOnly bool        `json:"readOnly"`
	Values   []EnumValue `json:"values"`
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

func Describe(v interface{}) (*Description, error) {
	return nil, nil
}

func (k *Kloud) CredentialDescribe(r *kite.Request) (interface{}, error) {
	return nil, nil
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
