package stack

import (
	"encoding/json"
	"errors"
	"fmt"

	"github.com/koding/kite"
)

// ImportRequest represents a request struct for "stack.import"
// kloud's kite method.
type ImportRequest struct {
	Credentials map[string][]string `json:"credentials"`
	Template    []byte              `json:"template"`
	Provider    string              `json:"provider"`
	Team        string              `json:"team"`
	Title       string              `json:"title,omitempty"`
}

// Valid implements the Validator interface.
func (r *ImportRequest) Valid() error {
	if len(r.Credentials) == 0 {
		return errors.New("empty credentials")
	}

	if len(r.Template) == 0 {
		return errors.New("empty template")
	}

	if r.Team == "" {
		return errors.New("empty team")
	}

	var raw json.RawMessage

	if err := json.Unmarshal(r.Template, &raw); err != nil {
		return fmt.Errorf("template is not a valid JSON: %s", err)
	}

	return nil
}

// ImportResponse represents a response struct for "stack.import"
// kloud's kite method.
type ImportResponse struct {
	TemplateID string `json:"templateId"`
	StackID    string `json:"stackId"`
	Title      string `json:"title"`
	EventID    string `json:"eventId"`
}

func (k *Kloud) Import(r *kite.Request) (interface{}, error) {
	return &ControlResult{
		EventId: "",
	}, nil
}
