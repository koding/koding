package osin

import (
	"net/http"
	"net/url"
	"testing"
)

func TestAccessAuthorizationCode(t *testing.T) {
	sconfig := NewServerConfig()
	sconfig.AllowedAccessTypes = AllowedAccessType{AUTHORIZATION_CODE}
	server := NewServer(sconfig, NewTestingStorage())
	server.AccessTokenGen = &TestingAccessTokenGen{}
	resp := server.NewResponse()

	req, err := http.NewRequest("POST", "http://localhost:14000/appauth", nil)
	if err != nil {
		t.Fatal(err)
	}
	req.SetBasicAuth("1234", "aabbccdd")

	req.Form = make(url.Values)
	req.Form.Set("grant_type", string(AUTHORIZATION_CODE))
	req.Form.Set("code", "9999")
	req.Form.Set("state", "a")
	req.PostForm = make(url.Values)

	if ar := server.HandleAccessRequest(resp, req); ar != nil {
		ar.Authorized = true
		server.FinishAccessRequest(resp, req, ar)
	}

	//fmt.Printf("%+v", resp)

	if resp.IsError && resp.InternalError != nil {
		t.Fatalf("Error in response: %s", resp.InternalError)
	}

	if resp.IsError {
		t.Fatalf("Should not be an error")
	}

	if resp.Type != DATA {
		t.Fatalf("Response should be data")
	}

	if d := resp.Output["access_token"]; d != "1" {
		t.Fatalf("Unexpected access token: %s", d)
	}

	if d := resp.Output["refresh_token"]; d != "r1" {
		t.Fatalf("Unexpected refresh token: %s", d)
	}
}

func TestAccessRefreshToken(t *testing.T) {
	sconfig := NewServerConfig()
	sconfig.AllowedAccessTypes = AllowedAccessType{REFRESH_TOKEN}
	server := NewServer(sconfig, NewTestingStorage())
	server.AccessTokenGen = &TestingAccessTokenGen{}
	resp := server.NewResponse()

	req, err := http.NewRequest("POST", "http://localhost:14000/appauth", nil)
	if err != nil {
		t.Fatal(err)
	}
	req.SetBasicAuth("1234", "aabbccdd")

	req.Form = make(url.Values)
	req.Form.Set("grant_type", string(REFRESH_TOKEN))
	req.Form.Set("refresh_token", "r9999")
	req.Form.Set("state", "a")
	req.PostForm = make(url.Values)

	if ar := server.HandleAccessRequest(resp, req); ar != nil {
		ar.Authorized = true
		server.FinishAccessRequest(resp, req, ar)
	}

	//fmt.Printf("%+v", resp)

	if resp.IsError && resp.InternalError != nil {
		t.Fatalf("Error in response: %s", resp.InternalError)
	}

	if resp.IsError {
		t.Fatalf("Should not be an error")
	}

	if resp.Type != DATA {
		t.Fatalf("Response should be data")
	}

	if d := resp.Output["access_token"]; d != "1" {
		t.Fatalf("Unexpected access token: %s", d)
	}

	if d := resp.Output["refresh_token"]; d != "r1" {
		t.Fatalf("Unexpected refresh token: %s", d)
	}
}

func TestAccessPassword(t *testing.T) {
	sconfig := NewServerConfig()
	sconfig.AllowedAccessTypes = AllowedAccessType{PASSWORD}
	server := NewServer(sconfig, NewTestingStorage())
	server.AccessTokenGen = &TestingAccessTokenGen{}
	resp := server.NewResponse()

	req, err := http.NewRequest("POST", "http://localhost:14000/appauth", nil)
	if err != nil {
		t.Fatal(err)
	}
	req.SetBasicAuth("1234", "aabbccdd")

	req.Form = make(url.Values)
	req.Form.Set("grant_type", string(PASSWORD))
	req.Form.Set("username", "testing")
	req.Form.Set("password", "testing")
	req.Form.Set("state", "a")
	req.PostForm = make(url.Values)

	if ar := server.HandleAccessRequest(resp, req); ar != nil {
		ar.Authorized = ar.Username == "testing" && ar.Password == "testing"
		server.FinishAccessRequest(resp, req, ar)
	}

	//fmt.Printf("%+v", resp)

	if resp.IsError && resp.InternalError != nil {
		t.Fatalf("Error in response: %s", resp.InternalError)
	}

	if resp.IsError {
		t.Fatalf("Should not be an error")
	}

	if resp.Type != DATA {
		t.Fatalf("Response should be data")
	}

	if d := resp.Output["access_token"]; d != "1" {
		t.Fatalf("Unexpected access token: %s", d)
	}

	if d := resp.Output["refresh_token"]; d != "r1" {
		t.Fatalf("Unexpected refresh token: %s", d)
	}
}

func TestAccessClientCredentials(t *testing.T) {
	sconfig := NewServerConfig()
	sconfig.AllowedAccessTypes = AllowedAccessType{CLIENT_CREDENTIALS}
	server := NewServer(sconfig, NewTestingStorage())
	server.AccessTokenGen = &TestingAccessTokenGen{}
	resp := server.NewResponse()

	req, err := http.NewRequest("POST", "http://localhost:14000/appauth", nil)
	if err != nil {
		t.Fatal(err)
	}
	req.SetBasicAuth("1234", "aabbccdd")

	req.Form = make(url.Values)
	req.Form.Set("grant_type", string(CLIENT_CREDENTIALS))
	req.Form.Set("state", "a")
	req.PostForm = make(url.Values)

	if ar := server.HandleAccessRequest(resp, req); ar != nil {
		ar.Authorized = true
		server.FinishAccessRequest(resp, req, ar)
	}

	//fmt.Printf("%+v", resp)

	if resp.IsError && resp.InternalError != nil {
		t.Fatalf("Error in response: %s", resp.InternalError)
	}

	if resp.IsError {
		t.Fatalf("Should not be an error")
	}

	if resp.Type != DATA {
		t.Fatalf("Response should be data")
	}

	if d := resp.Output["access_token"]; d != "1" {
		t.Fatalf("Unexpected access token: %s", d)
	}

	if d, dok := resp.Output["refresh_token"]; dok {
		t.Fatalf("Refresh token should not be generated: %s", d)
	}
}

func TestExtraScopes(t *testing.T) {
	if extraScopes("", "") == true {
		t.Fatalf("extraScopes returned true with empty scopes")
	}

	if extraScopes("a", "") == true {
		t.Fatalf("extraScopes returned true with less scopes")
	}

	if extraScopes("a,b", "b,a") == true {
		t.Fatalf("extraScopes returned true with matching scopes")
	}

	if extraScopes("a,b", "b,a,c") == false {
		t.Fatalf("extraScopes returned false with extra scopes")
	}

	if extraScopes("", "a") == false {
		t.Fatalf("extraScopes returned false with extra scopes")
	}

}

// clientWithoutMatcher just implements the base Client interface
type clientWithoutMatcher struct {
	Id          string
	Secret      string
	RedirectUri string
}

func (c *clientWithoutMatcher) GetId() string            { return c.Id }
func (c *clientWithoutMatcher) GetSecret() string        { return c.Secret }
func (c *clientWithoutMatcher) GetRedirectUri() string   { return c.RedirectUri }
func (c *clientWithoutMatcher) GetUserData() interface{} { return nil }

func TestGetClientWithoutMatcher(t *testing.T) {
	myclient := &clientWithoutMatcher{
		Id:          "myclient",
		Secret:      "myclientsecret",
		RedirectUri: "http://www.example.com",
	}
	storage := &TestingStorage{clients: map[string]Client{myclient.Id: myclient}}

	// Ensure bad secret fails
	{
		auth := &BasicAuth{
			Username: "myclient",
			Password: "invalidsecret",
		}
		w := &Response{}
		client := getClient(auth, storage, w)
		if client != nil {
			t.Errorf("Expected error, got client: %v", client)
		}
	}

	// Ensure good secret works
	{
		auth := &BasicAuth{
			Username: "myclient",
			Password: "myclientsecret",
		}
		w := &Response{}
		client := getClient(auth, storage, w)
		if client != myclient {
			t.Errorf("Expected client, got nil with response: %v", w)
		}
	}
}

// clientWithMatcher implements the base Client interface and the ClientSecretMatcher interface
type clientWithMatcher struct {
	Id          string
	Secret      string
	RedirectUri string
}

func (c *clientWithMatcher) GetId() string            { return c.Id }
func (c *clientWithMatcher) GetSecret() string        { panic("called GetSecret"); return "" }
func (c *clientWithMatcher) GetRedirectUri() string   { return c.RedirectUri }
func (c *clientWithMatcher) GetUserData() interface{} { return nil }
func (c *clientWithMatcher) ClientSecretMatches(secret string) bool {
	return secret == c.Secret
}

func TestGetClientSecretMatcher(t *testing.T) {
	myclient := &clientWithMatcher{
		Id:          "myclient",
		Secret:      "myclientsecret",
		RedirectUri: "http://www.example.com",
	}
	storage := &TestingStorage{clients: map[string]Client{myclient.Id: myclient}}

	// Ensure bad secret fails, but does not panic (doesn't call GetSecret)
	{
		auth := &BasicAuth{
			Username: "myclient",
			Password: "invalidsecret",
		}
		w := &Response{}
		client := getClient(auth, storage, w)
		if client != nil {
			t.Errorf("Expected error, got client: %v", client)
		}
	}

	// Ensure good secret works, but does not panic (doesn't call GetSecret)
	{
		auth := &BasicAuth{
			Username: "myclient",
			Password: "myclientsecret",
		}
		w := &Response{}
		client := getClient(auth, storage, w)
		if client != myclient {
			t.Errorf("Expected client, got nil with response: %v", w)
		}
	}
}
