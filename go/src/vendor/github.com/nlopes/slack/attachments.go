package slack

// AttachmentField contains information for an attachment field
// An Attachment can contain multiple of these
type AttachmentField struct {
	Title string `json:"title"`
	Value string `json:"value"`
	Short bool   `json:"short"`
}

// AttachmentAction is a button to be included in the attachment. Required when
// using message buttons and otherwise not useful. A maximum of 5 actions may be
// provided per attachment.
type AttachmentAction struct {
	Name    string              `json:"name"`              // Required.
	Text    string              `json:"text"`              // Required.
	Style   string              `json:"style,omitempty"`   // Optional. Allowed values: "default", "primary", "danger"
	Type    string              `json:"type"`              // Required. Must be set to "button"
	Value   string              `json:"value,omitempty"`   // Optional.
	Confirm []ConfirmationField `json:"confirm,omitempty"` // Optional.
}

// AttachmentActionCallback is sent from Slack when a user clicks a button in an interactive message (aka AttachmentAction)
type AttachmentActionCallback struct {
	Actions    []AttachmentAction `json:"actions"`
	CallbackID string             `json:"callback_id"`
	Team       Team               `json:"team"`
	Channel    Channel            `json:"channel"`
	User       User               `json:"user"`

	OriginalMessage Message `json:"original_message"`

	ActionTs     string `json:"action_ts"`
	MessageTs    string `json:"message_ts"`
	AttachmentID string `json:"attachment_id"`
	Token        string `json:"token"`
	ResponseURL  string `json:"response_url"`
}

// ConfirmationField are used to ask users to confirm actions
type ConfirmationField struct {
	Title       string `json:"title,omitempty"`        // Optional.
	Text        string `json:"text"`                   // Required.
	OkText      string `json:"ok_text,omitempty"`      // Optional. Defaults to "Okay"
	DismissText string `json:"dismiss_text,omitempty"` // Optional. Defaults to "Cancel"
}

// Attachment contains all the information for an attachment
type Attachment struct {
	Color    string `json:"color,omitempty"`
	Fallback string `json:"fallback"`

	CallbackID string `json:"callback_id,omitempty"`

	AuthorName    string `json:"author_name,omitempty"`
	AuthorSubname string `json:"author_subname,omitempty"`
	AuthorLink    string `json:"author_link,omitempty"`
	AuthorIcon    string `json:"author_icon,omitempty"`

	Title     string `json:"title,omitempty"`
	TitleLink string `json:"title_link,omitempty"`
	Pretext   string `json:"pretext,omitempty"`
	Text      string `json:"text"`

	ImageURL string `json:"image_url,omitempty"`
	ThumbURL string `json:"thumb_url,omitempty"`

	Fields     []AttachmentField  `json:"fields,omitempty"`
	Actions    []AttachmentAction `json:"actions,omitempty"`
	MarkdownIn []string           `json:"mrkdwn_in,omitempty"`

	Footer     string `json:"footer,omitempty"`
	FooterIcon string `json:"footer_icon,omitempty"`

	Ts int64 `json:"ts,omitempty"`
}
