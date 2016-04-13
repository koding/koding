package api_test

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"

	"github.com/CenturyLinkCloud/clc-sdk/api"
	"github.com/stretchr/testify/assert"
)

func TestEnvConfig(t *testing.T) {
	assert := assert.New(t)

	os.Setenv("CLC_USERNAME", "user")
	os.Setenv("CLC_PASSWORD", "pass")
	os.Setenv("CLC_ALIAS", "alias")
	os.Setenv("CLC_USER_AGENT", "clc-sdk")

	c, err := api.EnvConfig()

	assert.Nil(err)
	assert.Equal("user", c.User.Username)
	assert.Equal("pass", c.User.Password)
	assert.Equal("alias", c.Alias)
	assert.Equal("clc-sdk", c.UserAgent)
}

func clearEnvVars() {
	os.Setenv("CLC_USERNAME", "")
	os.Setenv("CLC_PASSWORD", "")
	os.Setenv("CLC_ALIAS", "")
	os.Setenv("CLC_BASE_URL", "")
	os.Setenv("CLC_USER_AGENT", "")
}

func TestInvalidEnvConfig(t *testing.T) {
	assert := assert.New(t)

	clearEnvVars()
	os.Setenv("CLC_USERNAME", "user")
	os.Setenv("CLC_PASSWORD", "")

	_, err := api.EnvConfig()

	assert.NotNil(err)
}

func TestNewConfigWithNoUrl(t *testing.T) {
	assert := assert.New(t)

	clearEnvVars()
	c, err := api.NewConfig("user", "pass")

	u, _ := url.Parse("https://api.ctl.io/v2")

	assert.Nil(err)
	assert.Equal("user", c.User.Username)
	assert.Equal("pass", c.User.Password)
	assert.Equal("", c.Alias)
	assert.Equal(u, c.BaseURL)
}

func TestNewConfigWithUrl(t *testing.T) {
	assert := assert.New(t)

	clearEnvVars()

	alt := "https://api.other.io/v2"
	os.Setenv("CLC_BASE_URL", alt)

	c, err := api.NewConfig("user", "pass")

	u, _ := url.Parse(alt)

	assert.Nil(err)
	assert.Equal("user", c.User.Username)
	assert.Equal("pass", c.User.Password)
	assert.Equal("", c.Alias) // not set until Auth()
	assert.Equal(u, c.BaseURL)
}

func TestFileConfig(t *testing.T) {
	assert := assert.New(t)

	file, err := ioutil.TempFile("", "tmp")
	assert.Nil(err)

	clearEnvVars()
	os.Setenv("CLC_ALIAS", "alias")
	os.Setenv("CLC_USER_AGENT", "some-sdk-client")
	conf, err := api.NewConfig("user", "pass")

	assert.Nil(err)
	b, _ := json.Marshal(conf)

	assert.Nil(ioutil.WriteFile(file.Name(), b, 755))

	c, err := api.FileConfig(file.Name())

	assert.Nil(err)
	assert.Equal("user", c.User.Username)
	assert.Equal("pass", c.User.Password)
	assert.Equal("alias", c.Alias)
	assert.Equal("some-sdk-client", c.UserAgent)

	file.Close()
	os.Remove(file.Name())
}

func TestNewClient(t *testing.T) {
	assert := assert.New(t)

	config := api.Config{
		User: api.User{Username: "user", Password: "password"},
	}
	client := api.New(config)

	assert.NotNil(client)
	assert.Equal(config.User, client.Config().User)
}

func TestAuth(t *testing.T) {
	assert := assert.New(t)

	actualUser := &api.User{}
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			http.Error(w, "no", http.StatusMethodNotAllowed)
			return
		}

		json.NewDecoder(r.Body).Decode(actualUser)

		fmt.Fprintf(w, `{"userName":"user@email.com","accountAlias":"ALIAS","locationAlias":"DC1","roles":["AccountAdmin","ServerAdmin"],"bearerToken":"[LONG TOKEN VALUE]"}`)
	}))
	defer ts.Close()

	config := genConfig(ts)
	client := api.New(config)
	err := client.Auth()

	assert.Nil(err)
	assert.Equal(config.User.Username, actualUser.Username)
	assert.Equal(config.User.Password, actualUser.Password)
	assert.Equal("ALIAS", client.Config().Alias)
}

func TestAuthAlaias(t *testing.T) {
	assert := assert.New(t)

	actualUser := &api.User{}
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			http.Error(w, "no", http.StatusMethodNotAllowed)
			return
		}

		json.NewDecoder(r.Body).Decode(actualUser)

		fmt.Fprintf(w, `{"userName":"user@email.com","accountAlias":"ALIAS","locationAlias":"DC1","roles":["AccountAdmin","ServerAdmin"],"bearerToken":"[LONG TOKEN VALUE]"}`)
	}))
	defer ts.Close()

	config := genConfig(ts)
	// override alias should be preserved regardless of auth response
	config.Alias = "ABCD"
	client := api.New(config)
	err := client.Auth()

	assert.Nil(err)
	assert.Equal("ABCD", client.Config().Alias)
}

func TestDoWithAuth(t *testing.T) {
	assert := assert.New(t)

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == "POST" && strings.HasSuffix(r.URL.RequestURI(), "login") {
			fmt.Fprintf(w, `{"userName":"user@email.com","accountAlias":"ALIAS","locationAlias":"DC1","roles":["AccountAdmin","ServerAdmin"],"bearerToken":"[LONG TOKEN VALUE]"}`)
		}
	}))
	defer ts.Close()

	config := genConfig(ts)
	client := api.New(config)
	err := client.DoWithAuth("GET", ts.URL, nil, nil)

	assert.Nil(err)
	assert.Equal("ALIAS", client.Config().Alias)
}

func TestAuth_SerializationErr(t *testing.T) {
	assert := assert.New(t)

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "nope", http.StatusInternalServerError)
	}))
	defer ts.Close()

	config := genConfig(ts)
	client := api.New(config)
	err := client.Auth()

	assert.NotNil(err)
}

func TestGet(t *testing.T) {
	assert := assert.New(t)

	status := "ok"
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Accept") != "application/json" {
			http.Error(w, "accept missing", http.StatusBadRequest)
			return
		}

		if r.Header.Get("Content-Type") != "" {
			http.Error(w, "content-type should not be present", http.StatusBadRequest)
			return
		}

		if r.Header.Get("User-Agent") != "sdk-client" {
			http.Error(w, "user-agent mismatch", http.StatusBadRequest)
			return
		}

		if r.Method != "GET" {
			http.Error(w, "no", http.StatusMethodNotAllowed)
			return
		}

		fmt.Fprintf(w, `{"status": "%s"}`, status)
	}))
	defer ts.Close()

	client := api.New(mockConfig())
	client.Token = api.Token{Token: "valid"}

	resp := &Response{}
	err := client.Get(ts.URL, resp)

	assert.Nil(err)
	assert.Equal(status, resp.Status)
}

func TestPost(t *testing.T) {
	assert := assert.New(t)

	status := "ok"
	actualReq := &Request{}
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Accept") != "application/json" {
			http.Error(w, "accept missing", http.StatusBadRequest)
			return
		}

		if r.Header.Get("Content-Type") != "application/json" {
			http.Error(w, "content-type missing", http.StatusBadRequest)
			return
		}
		if r.Method != "POST" {
			http.Error(w, "no", http.StatusMethodNotAllowed)
			return
		}

		json.NewDecoder(r.Body).Decode(actualReq)

		fmt.Fprintf(w, `{"status": "%s"}`, status)
	}))
	defer ts.Close()

	client := api.New(mockConfig())
	client.Token = api.Token{Token: "valid"}

	req := &Request{Status: "do stuff"}
	resp := &Response{}
	err := client.Post(ts.URL, req, resp)

	assert.Nil(err)
	assert.Equal(req, actualReq)
	assert.Equal(status, resp.Status)
}

func TestPut(t *testing.T) {
	assert := assert.New(t)

	status := "ok"
	actualReq := &Request{}
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Accept") != "application/json" {
			http.Error(w, "accept missing", http.StatusBadRequest)
			return
		}

		if r.Header.Get("Content-Type") != "application/json" {
			http.Error(w, "content-type missing", http.StatusBadRequest)
			return
		}

		if r.Header.Get("User-Agent") != "sdk-client" {
			http.Error(w, "user-agent mismatch", http.StatusBadRequest)
			return
		}

		if r.Method != "PUT" {
			http.Error(w, "no", http.StatusMethodNotAllowed)
			return
		}

		json.NewDecoder(r.Body).Decode(actualReq)

		fmt.Fprintf(w, `{"status": "%s"}`, status)
	}))
	defer ts.Close()

	client := api.New(mockConfig())
	client.Token = api.Token{Token: "valid"}

	req := &Request{Status: "do stuff"}
	resp := &Response{}
	err := client.Put(ts.URL, req, resp)

	assert.Nil(err)
	assert.Equal(req, actualReq)
	assert.Equal(status, resp.Status)
}

func TestPatch(t *testing.T) {
	assert := assert.New(t)

	status := "ok"
	actualReq := &Request{}
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Accept") != "application/json" {
			http.Error(w, "accept missing", http.StatusBadRequest)
			return
		}

		if r.Header.Get("Content-Type") != "application/json" {
			http.Error(w, "content-type missing", http.StatusBadRequest)
			return
		}

		if r.Header.Get("User-Agent") != "sdk-client" {
			http.Error(w, "user-agent mismatch", http.StatusBadRequest)
			return
		}

		if r.Method != "PATCH" {
			http.Error(w, "no", http.StatusMethodNotAllowed)
			return
		}

		json.NewDecoder(r.Body).Decode(actualReq)

		fmt.Fprintf(w, `{"status": "%s"}`, status)
	}))
	defer ts.Close()

	client := api.New(mockConfig())
	client.Token = api.Token{Token: "valid"}

	req := &Request{Status: "do stuff"}
	resp := &Response{}
	err := client.Patch(ts.URL, req, resp)

	assert.Nil(err)
	assert.Equal(req, actualReq)
	assert.Equal(status, resp.Status)
}

func TestDelete(t *testing.T) {
	assert := assert.New(t)

	status := "ok"
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Accept") != "application/json" {
			http.Error(w, "accept missing", http.StatusBadRequest)
			return
		}

		if r.Header.Get("Content-Type") != "" {
			http.Error(w, "content-type should not be present", http.StatusBadRequest)
			return
		}

		if r.Header.Get("User-Agent") != "sdk-client" {
			http.Error(w, "user-agent mismatch", http.StatusBadRequest)
			return
		}

		if r.Method != "DELETE" {
			http.Error(w, "no", http.StatusMethodNotAllowed)
			return
		}

		fmt.Fprintf(w, `{"status": "%s"}`, status)
	}))
	defer ts.Close()

	client := api.New(mockConfig())
	client.Token = api.Token{Token: "valid"}

	resp := &Response{}
	err := client.Delete(ts.URL, resp)

	assert.Nil(err)
	assert.Equal(status, resp.Status)
}

func genConfig(ts *httptest.Server) api.Config {
	u, _ := url.Parse(ts.URL)
	config := api.Config{
		User: api.User{
			Username: "user.name",
			Password: "password",
		},
		BaseURL: u,
	}
	return config
}

func mockConfig() api.Config {
	return api.Config{
		User: api.User{
			Username: "user.name",
			Password: "password",
		},
		Alias:     "t3bk",
		UserAgent: "sdk-client",
	}
}

type Response struct {
	Status string `json:"status"`
}

type Request struct {
	Status string `json:"status"`
}
