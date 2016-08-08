package mailgun

// GetWebhooks returns the complete set of webhooks configured for your domain.
// Note that a zero-length mapping is not an error.
func (mg *MailgunImpl) GetWebhooks() (map[string]string, error) {
	r := newHTTPRequest(generateDomainApiUrl(mg, webhooksEndpoint))
	r.setClient(mg.Client())
	r.setBasicAuth(basicAuthUser, mg.ApiKey())
	var envelope struct {
		Webhooks map[string]interface{} `json:"webhooks"`
	}
	err := getResponseFromJSON(r, &envelope)
	hooks := make(map[string]string, 0)
	if err != nil {
		return hooks, err
	}
	for k, v := range envelope.Webhooks {
		object := v.(map[string]interface{})
		url := object["url"]
		hooks[k] = url.(string)
	}
	return hooks, nil
}

// CreateWebhook installs a new webhook for your domain.
func (mg *MailgunImpl) CreateWebhook(t, u string) error {
	r := newHTTPRequest(generateDomainApiUrl(mg, webhooksEndpoint))
	r.setClient(mg.Client())
	r.setBasicAuth(basicAuthUser, mg.ApiKey())
	p := newUrlEncodedPayload()
	p.addValue("id", t)
	p.addValue("url", u)
	_, err := makePostRequest(r, p)
	return err
}

// DeleteWebhook removes the specified webhook from your domain's configuration.
func (mg *MailgunImpl) DeleteWebhook(t string) error {
	r := newHTTPRequest(generateDomainApiUrl(mg, webhooksEndpoint) + "/" + t)
	r.setClient(mg.Client())
	r.setBasicAuth(basicAuthUser, mg.ApiKey())
	_, err := makeDeleteRequest(r)
	return err
}

// GetWebhookByType retrieves the currently assigned webhook URL associated with the provided type of webhook.
func (mg *MailgunImpl) GetWebhookByType(t string) (string, error) {
	r := newHTTPRequest(generateDomainApiUrl(mg, webhooksEndpoint) + "/" + t)
	r.setClient(mg.Client())
	r.setBasicAuth(basicAuthUser, mg.ApiKey())
	var envelope struct {
		Webhook struct {
			Url string `json:"url"`
		} `json:"webhook"`
	}
	err := getResponseFromJSON(r, &envelope)
	return envelope.Webhook.Url, err
}

// UpdateWebhook replaces one webhook setting for another.
func (mg *MailgunImpl) UpdateWebhook(t, u string) error {
	r := newHTTPRequest(generateDomainApiUrl(mg, webhooksEndpoint) + "/" + t)
	r.setClient(mg.Client())
	r.setBasicAuth(basicAuthUser, mg.ApiKey())
	p := newUrlEncodedPayload()
	p.addValue("url", u)
	_, err := makePutRequest(r, p)
	return err
}
