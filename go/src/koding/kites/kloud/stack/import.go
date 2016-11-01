package stack

import "github.com/koding/kite"

type ImportRequest struct {
	Credentials map[string][]string `json:"credentials"`
	Template    []byte              `json:"template"`
}

func (k *Kloud) Import(r *kite.Request) (interface{}, error) {
	return &ControlResult{
		EventId: "",
	}, nil
}
