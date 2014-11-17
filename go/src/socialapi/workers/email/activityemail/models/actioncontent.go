package models

import (
	"bytes"
	"socialapi/workers/email/activityemail/templates"
	"text/template"
)

type ActionContent struct {
	Action     string
	Hostname   string
	ObjectType string
	Slug       string
}

func (ac *ActionContent) Render() string {
	ct := template.Must(template.New("contentlink").Parse(templates.ContentLink))

	buf := bytes.NewBuffer([]byte{})

	ct.ExecuteTemplate(buf, "contentlink", ac)

	return buf.String()
}
