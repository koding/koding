package remoteapi

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"koding/kites/config"
	"koding/remoteapi"
	stacktemplate "koding/remoteapi/client/j_stack_template"
	"koding/remoteapi/models"
)

// Filter is used to request some of the templates,
// basing on the filter value.
//
// TODO(rjeczalik): Fix swagger.json:
//
//   - missing _id field
//   - ensure omitempty
//   - slug field
//
// And use models.JStackTemplate instead.
type Filter struct {
	ID       string `json:"_id,omitempty"`
	Slug     string `json:"slug,omitempty"`
	Provider string `json:"provider,omitempty"`
	Team     string `json:"group,omitempty"`
	OriginID string `json:"originId,omitempty"`
}

// ListTemplates gives all templates filtered with use of the given filter.
func (c *Client) ListTemplates(f *Filter) ([]*models.JStackTemplate, error) {
	c.init()

	params := &stacktemplate.JStackTemplateSomeParams{}

	if f != nil {
		if err := c.buildFilter(f); err != nil {
			return nil, err
		}

		params.Body = f
	}

	params.SetTimeout(c.timeout())

	resp, err := c.client().JStackTemplate.JStackTemplateSome(params, nil)
	if err != nil {
		return nil, err
	}

	var templates []*models.JStackTemplate

	if err := remoteapi.Unmarshal(resp.Payload, &templates); err != nil {
		return nil, err
	}

	if len(templates) == 0 {
		return nil, ErrNotFound
	}

	return templates, nil
}

// DeleteTemplate deletes a template given by the id.
func (c *Client) DeleteTemplate(id string) error {
	c.init()

	params := &stacktemplate.JStackTemplateDeleteParams{
		ID: id,
	}

	params.SetTimeout(c.timeout())

	resp, err := c.client().JStackTemplate.JStackTemplateDelete(params, nil)
	if err != nil {
		return err
	}

	return remoteapi.Unmarshal(&resp.Payload.DefaultResponse, nil)
}

// SampleTemplate returns a content of a sample stack template
// for the given provider.
func (c *Client) SampleTemplate(provider string) (string, map[string]interface{}, error) {
	c.init()

	params := &stacktemplate.JStackTemplateSamplesParams{
		Body: stacktemplate.JStackTemplateSamplesBody{
			Provider:    &provider,
			UseDefaults: false,
		},
	}

	params.SetTimeout(c.timeout())

	resp, err := c.client().JStackTemplate.JStackTemplateSamples(params, nil)
	if err != nil {
		return "", nil, err
	}

	var v struct {
		JSON     string `json:"json"`
		Defaults struct {
			UserInputs map[string]interface{} `json:"userInputs,omitempty"`
		} `json:"defaults"`
	}

	if err := remoteapi.Unmarshal(resp.Payload, &v); err != nil {
		return "", nil, err
	}

	if err := json.Unmarshal([]byte(v.JSON), &json.RawMessage{}); err != nil {
		return "", nil, errors.New("invalid template sample: " + err.Error())
	}

	return v.JSON, v.Defaults.UserInputs, nil
}

func (c *Client) buildFilter(f *Filter) error {
	if f.Slug != "" {
		fields := strings.Split(f.Slug, "/")
		switch len(fields) {
		case 1:
			fields = []string{config.CurrentUser.Username, fields[0]}
		case 2:
			// ok
		default:
			return errors.New(`invalid slug format - expected "user/template"`)
		}

		if fields[0] != "" {
			account, err := c.AccountByUsername(fields[0])
			if err != nil {
				return fmt.Errorf("unable to look up user %q: %s", fields[0], err)
			}

			f.OriginID = account.ID
		}

		f.Slug = fields[1]
	}

	return nil
}

// SampleTemplate returns a content of a sample stack template
// for the given provider.
//
// The functions uses DefaultClient.
func SampleTemplate(provider string) (string, map[string]interface{}, error) {
	return DefaultClient.SampleTemplate(provider)
}

// ListTemplates gives all templates filtered with use of the given filter.
//
// The functions uses DefaultClient.
func ListTemplates(f *Filter) ([]*models.JStackTemplate, error) {
	return DefaultClient.ListTemplates(f)
}

// DeleteTemplate deletes a template given by the id.
//
// The functions uses DefaultClient.
func DeleteTemplate(id string) error {
	return DefaultClient.DeleteTemplate(id)
}
