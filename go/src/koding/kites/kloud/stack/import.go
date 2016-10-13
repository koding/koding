package stack

import "github.com/koding/kite"

type ImportRequest struct {
	Team        string              `json:"team"`
	Credentials map[string][]string `json:"credentials"`
	Template    []byte              `json:"template"`
	Title       string              `json:"title,omitempty"`
	Provider    string              `json:"provider,omitempty"`
}

type StackItem struct {
	ID         string `json:"stackID"`
	Title      string `json:"title"`
	TemplateID string `json:"templateID"`
	Team       string `json:"team"`
	Role       string `json:"role"`
}

type ImportResponse struct {
	EventerID string     `json:"eventerID"`
	Stack     *StackItem `json:"stack"`
}

func (k *Kloud) Import(r *kite.Request) (interface{}, error) {
	return &ImportResponse{}, nil
}
