package remoteapi

import (
	"koding/remoteapi"
	stacktemplate "koding/remoteapi/client/j_stack_template"
	"koding/remoteapi/models"
)

// TemplateFilter is used to request some of the templates,
// basing on the filter value.
//
// TODO(rjeczalik): Fix swagger.json:
//
//   - missing _id field
//   - ensure omitempty
//   - slug field
//
// And use models.JStackTemplate instead.
type TemplateFilter struct {
	ID       string `json:"_id,omitempty"`
	Slug     string `json:"slug,omitempty"`
	Provider string `json:"provider,omitempty"`
}

// ListTemplates gives all templates filtered with use of the given filter.
func (c *Client) ListTemplates(tf *TemplateFilter) ([]*models.JStackTemplate, error) {
	params := &stacktemplate.PostRemoteAPIJStackTemplateSomeParams{}

	if tf != nil {
		params.Body = tf
	}

	params.SetTimeout(c.timeout())

	resp, err := c.client().JStackTemplate.PostRemoteAPIJStackTemplateSome(params)
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

// DeleteTemplate deletes a tempalte given by the id.
func (c *Client) DeleteTemplate(id string) error {
	params := &stacktemplate.PostRemoteAPIJStackTemplateDeleteIDParams{
		ID: id,
	}

	resp, err := c.client().JStackTemplate.PostRemoteAPIJStackTemplateDeleteID(params)
	if err != nil {
		return err
	}

	return remoteapi.Unmarshal(&resp.Payload.DefaultResponse, nil)
}

// ListTemplates gives all templates filtered with use of the given filter.
//
// The functions uses DefaultClient.
func ListTemplates(tf *TemplateFilter) ([]*models.JStackTemplate, error) {
	return DefaultClient.ListTemplates(tf)
}

// DeleteTemplate deletes a tempalte given by the id.
//
// The functions uses DefaultClient.
func DeleteTemplate(id string) error {
	return DefaultClient.DeleteTemplate(id)
}
