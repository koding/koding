// Package sendgrid provides a simple interface to interact with the SendGrid API
package sendgrid

import (
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"time"
)

func timeoutHandler(network, address string) (net.Conn, error) {
	return net.DialTimeout(network, address, time.Duration(5*time.Second))
}

// SGClient will contain the credentials and default values
type SGClient struct {
	apiUser string
	apiPwd  string
	APIMail string
	Client  *http.Client
}

// NewSendGridClient will return a new SGClient.
func NewSendGridClient(apiUser, apiPwd string) *SGClient {
	apiMail := "https://api.sendgrid.com/api/mail.send.json?"
	return &SGClient{
		apiUser: apiUser,
		apiPwd:  apiPwd,
		APIMail: apiMail,
	}
}

func (sg *SGClient) buildURL(m *SGMail) (url.Values, error) {
	values := url.Values{}
	values.Set("api_user", sg.apiUser)
	values.Set("api_key", sg.apiPwd)
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
		transport := http.Transport{
			Dial: timeoutHandler,
		}
		sg.Client = &http.Client{
			Transport: &transport,
		}
	}
	var e error
	values, e := sg.buildURL(m)
	if e != nil {
		return e
	}
	r, e := sg.Client.PostForm(sg.APIMail, values)
	if e != nil {
		return fmt.Errorf("sendgrid.go: error:%v; response:%v", e, r)
	}
	if r.StatusCode == http.StatusOK {
		return nil
	}
	body, _ := ioutil.ReadAll(r.Body)
	r.Body.Close()
	return fmt.Errorf("sendgrid.go: code:%d error:%v body:%s", r.StatusCode, e, body)
}
