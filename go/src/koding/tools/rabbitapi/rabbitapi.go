// Implementation of RabbitMq Management HTTP Api in Go
// http://hg.rabbitmq.com/rabbitmq-management/raw-file/rabbitmq_v3_1_0/priv/www/api/index.html
package rabbitapi

import (
	"bytes"
	"encoding/json"
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

type Vhost struct {
	Name    string
	Tracing bool
}

type User struct {
	Name         string
	PasswordHash string `json:"password_hash"`
	Tags         string
}

type UserPut struct {
	Password string `json:"password"`
	Tags     string `json:"tags"`
}

type Permission struct {
	Configure string `json:"configure"`
	Read      string `json:"read"`
	User      string `json:"user"`
	Vhost     string `json:"vhost"`
	Write     string `json:"write"`
}

// To create a new rabbit struct instance
func Auth(username, password, url string) *Rabbit {
	return &Rabbit{
		Username: username,
		Password: password,
		Url:      url,
	}
}

// /api/vhosts
// /api/vhosts/name GET, PUT, DELETE
func (r *Rabbit) GetVhosts() ([]Vhost, error) {
	body, err := r.getRequest("/api/vhosts")
	if err != nil {
		return nil, err
	}

	vhosts := make([]Vhost, 0)
	err = json.Unmarshal(body, &vhosts)
	if err != nil {
		return nil, err
	}

	return vhosts, nil
}

func (r *Rabbit) GetVhost(name string) (Vhost, error) {
	if name == "/" {
		name = "%2f"
	}

	body, err := r.getRequest("/api/vhosts/" + name)
	if err != nil {
		return Vhost{}, err
	}

	vhost := Vhost{}
	err = json.Unmarshal(body, &vhost)
	if err != nil {
		return Vhost{}, err
	}

	return vhost, nil

}
func (r *Rabbit) PutVhost(name string)    {}
func (r *Rabbit) DeleteVhost(name string) {}

// GET /api/users
func (r *Rabbit) GetUsers() ([]User, error) {
	body, err := r.getRequest("/api/users")
	if err != nil {
		return nil, err
	}

	users := make([]User, 0)
	err = json.Unmarshal(body, &users)
	if err != nil {
		return nil, err
	}

	return users, nil

}

// GET /api/users/name
func (r *Rabbit) GetUser(name string) (User, error) {
	body, err := r.getRequest("/api/users/" + name)
	if err != nil {
		return User{}, err
	}

	user := User{}
	err = json.Unmarshal(body, &user)
	if err != nil {
		log.Println(err)
	}

	return user, nil

}

// PUT /api/users/name password=secret tags=""
func (r *Rabbit) PutUser(name, password string, tags string) error {
	user := &UserPut{
		Password: password,
		Tags:     tags,
	}

	data, err := json.Marshal(user)
	if err != nil {
		return err
	}

	err = r.putRequest("/api/users/"+name, data)
	if err != nil {
		return err
	}

	return nil
}

// DELETE /api/users/name
func (r *Rabbit) DeleteUser(name string) error {
	err := r.deleteRequest("/api/users/" + name)
	if err != nil {
		return err
	}

	return nil
}

// /api/permissions
// /api/permissions/name GET, PUT, DELETE
func (r *Rabbit) GetPermissions() ([]Permission, error) {
	body, err := r.getRequest("/api/permissions")
	if err != nil {
		return nil, err
	}

	list := make([]Permission, 0)
	err = json.Unmarshal(body, &list)
	if err != nil {
		return nil, err
	}

	return list, nil

}
func (r *Rabbit) GetPermission(vhost, user string) (Permission, error) {
	if vhost == "/" {
		vhost = "%2f"
	}

	body, err := r.getRequest("/api/permissions/" + vhost + "/" + user)
	if err != nil {
		return Permission{}, err
	}

	permission := Permission{}
	err = json.Unmarshal(body, &permission)
	if err != nil {
		return Permission{}, err
	}

	return permission, nil

}
func (r *Rabbit) PutPermission(vhost, user, configure, write, read string) error {
	if vhost == "/" {
		vhost = "%2f"
	}

	permission := &Permission{
		Configure: configure,
		Write:     write,
		Read:      read,
	}

	data, err := json.Marshal(permission)
	if err != nil {
		return err
	}

	// debug fmt.Println(string(data))
	err = r.putRequest("/api/permissions/"+vhost+"/"+user, data)
	if err != nil {
		return err
	}

	return nil

}
func (r *Rabbit) DeletePermission(name string) {

}

// /api/whoami
func (r *Rabbit) GetWhoami() {}

/**********************************

		Util functions

***********************************/

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
