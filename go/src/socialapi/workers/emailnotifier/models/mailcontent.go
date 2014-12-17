package models

import (
	"html/template"
)

type MailContent struct {
	CurrentDate string
	FirstName   string
	Description string
	Uri         string
	ContentLink string
	Content     template.HTML
	Unsubscribe *UnsubscribeContent
}
