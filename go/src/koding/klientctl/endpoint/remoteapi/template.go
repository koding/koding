package remoteapi

import (
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
