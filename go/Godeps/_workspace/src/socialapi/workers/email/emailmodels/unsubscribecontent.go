package emailmodels

type UnsubscribeContent struct {
	Token       string
	ContentType string
	ShowLink    bool
	Recipient   string
}
