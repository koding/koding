// Package sendgrid provides a simple interface to interact with the SendGrid API
package sendgrid

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const Version = "2.0.0"

// SGClient will contain the credentials and default values
type SGClient struct {
	apiUser string
	apiPwd  string
	APIMail string
	Client  *http.Client
}

// NewSendGridClient will return a new SGClient. Used for username and password
func NewSendGridClient(apiUser, apiKey string) *SGClient {
	apiMail := "https://api.sendgrid.com/api/mail.send.json?"

	Client := &SGClient{
		apiUser: apiUser,
		apiPwd:  apiKey,
		APIMail: apiMail,
	}

	return Client
}

// NewSendGridClient will return a new SGClient. Used for api key
func NewSendGridClientWithApiKey(apiKey string) *SGClient {
	apiMail := "https://api.sendgrid.com/api/mail.send.json?"

	Client := &SGClient{
		apiPwd:  apiKey,
		APIMail: apiMail,
	}

	return Client
}

func (sg *SGClient) buildURL(m *SGMail) (url.Values, error) {
	values := url.Values{}
	if sg.apiUser != "" {
		values.Set("api_user", sg.apiUser)
		values.Set("api_key", sg.apiPwd)
	}
	values.Set("subject", m.Subject)
	values.Set("html", m.HTML)
	values.Set("text", m.Text)
	values.Set("from", m.From)
	values.Set("replyto", m.ReplyTo)
	apiHeaders, err := m.SMTPAPIHeader.JSONString()
	if err != nil {
		return nil, fmt.Errorf("sendgrid.go: error:%v", err)
	}
	values.Set("x-smtpapi", apiHeaders)
	headers, err := m.HeadersString()
	if err != nil {
		return nil, fmt.Errorf("sendgrid.go: error: %v", err)
	}
	values.Set("headers", headers)
	if len(m.FromName) != 0 {
		values.Set("fromname", m.FromName)
	}
	for i := 0; i < len(m.To); i++ {
		values.Add("to[]", m.To[i])
	}
	for i := 0; i < len(m.Cc); i++ {
		values.Add("cc[]", m.Cc[i])
	}
	for i := 0; i < len(m.Bcc); i++ {
		values.Add("bcc[]", m.Bcc[i])
	}
	for i := 0; i < len(m.ToName); i++ {
		values.Add("toname[]", m.ToName[i])
	}
	for k, v := range m.Files {
		values.Set("files["+k+"]", v)
	}
	for k, v := range m.Content {
		values.Set("content["+k+"]", v)
	}
	return values, nil
}

// Send will send mail using SG web API
func (sg *SGClient) Send(m *SGMail) error {
	if sg.Client == nil {
		sg.Client = &http.Client{
			Transport: http.DefaultTransport,
			Timeout:   5 * time.Second,
		}
	}
	var e error
	values, e := sg.buildURL(m)
	if e != nil {
		return e
	}
	req, e := http.NewRequest("POST", sg.APIMail, strings.NewReader(values.Encode()))
	if e != nil {
		return e
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("User-Agent", "sendgrid/"+Version+";go")

	// Using API key
	if sg.apiUser == "" {
		req.Header.Set("Authorization", "Bearer "+sg.apiPwd)
	}

	res, e := sg.Client.Do(req)
	if e != nil {
		return fmt.Errorf("sendgrid.go: error:%v; response:%v", e, res)
	}

	defer res.Body.Close()

	if res.StatusCode == http.StatusOK {
		return nil
	}

	body, _ := ioutil.ReadAll(res.Body)

	return fmt.Errorf("sendgrid.go: code:%d error:%v body:%s", res.StatusCode, e, body)
}
