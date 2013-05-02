// Implementation of RabbitMq Management HTTP Api in Go
// http://hg.rabbitmq.com/rabbitmq-management/raw-file/rabbitmq_v3_1_0/priv/www/api/index.html
package rabbitapi

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"strings"
)

type Rabbit struct {
	Username string
	Password string
	Url      string
}

// To create a new rabbit struct instance
func Auth(username, password, url string) *Rabbit {
	return &Rabbit{
		Username: username,
		Password: password,
		Url:      url,
	}
}

func (r *Rabbit) getRequest(endpoint string) ([]byte, error) {
	req, err := r.newRequest("GET", endpoint, nil)
	if err != nil {
		log.Println(err)
	}
	req.SetBasicAuth(r.Username, r.Password)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Println(err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf(resp.Status)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	return body, nil
}

func (r *Rabbit) putRequest(endpoint string, body []byte) error {
	reader := bytes.NewBuffer(body)
	req, err := r.newRequest("PUT", endpoint, reader)
	if err != nil {
		log.Println(err)
	}
	req.SetBasicAuth(r.Username, r.Password)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Println(err)
	}
	defer resp.Body.Close()

	// io.Copy(os.Stdout, resp.Body)

	if resp.StatusCode != 204 {
		return fmt.Errorf(resp.Status)
	}

	return nil
}

func (r *Rabbit) deleteRequest(endpoint string) error {
	req, err := r.newRequest("DELETE", endpoint, nil)
	if err != nil {
		log.Println(err)
	}
	req.SetBasicAuth(r.Username, r.Password)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Println(err)
	}
	defer resp.Body.Close()

	// io.Copy(os.Stdout, resp.Body)

	if resp.StatusCode != 204 {
		return fmt.Errorf(resp.Status)
	}

	return nil
}

// modified version of http.NewRequest to not escape %2f paths. unfortunaley
// rabbitmq uses a RESTful api and "/" is a resource for a lot of api calls
func (r *Rabbit) newRequest(method, endpoint string, body io.Reader) (*http.Request, error) {
	requestUrl := r.Url + endpoint
	u, err := url.Parse(requestUrl)
	if err != nil {
		return nil, err
	}

	u.Opaque = endpoint // get around the path encoding bug
	rc, ok := body.(io.ReadCloser)
	if !ok && body != nil {
		rc = ioutil.NopCloser(body)
	}

	req := &http.Request{
		Method:     method,
		URL:        u,
		Proto:      "HTTP/1.1",
		ProtoMajor: 1,
		ProtoMinor: 1,
		Header:     make(http.Header),
		Body:       rc,
		Host:       u.Host,
	}

	if body != nil {
		switch v := body.(type) {
		case *strings.Reader:
			req.ContentLength = int64(v.Len())
		case *bytes.Buffer:
			req.ContentLength = int64(v.Len())
		}
	}

	return req, nil
}
