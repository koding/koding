package atlas

import (
	"net/http"
	"net/url"
	"reflect"
	"strings"
	"testing"
)

func TestDefaultClient_url(t *testing.T) {
	client := DefaultClient()

	if client.URL.String() != atlasURL {
		t.Fatalf("expected %q to be %q", client.URL.String(), atlasURL)
	}
}

func TestNewClient_badURL(t *testing.T) {
	_, err := NewClient("")
	if err == nil {
		t.Fatal("expected error, but nothing was returned")
	}

	expected := "client: missing url"
	if !strings.Contains(err.Error(), expected) {
		t.Fatalf("expected %q to contain %q", err.Error(), expected)
	}
}

func TestNewClient_parsesURL(t *testing.T) {
	client, err := NewClient("https://example.com/foo/bar")
	if err != nil {
		t.Fatal(err)
	}

	expected := &url.URL{
		Scheme: "https",
		Host:   "example.com",
		Path:   "/foo/bar",
	}
	if !reflect.DeepEqual(client.URL, expected) {
		t.Fatalf("expected %q to equal %q", client.URL, expected)
	}
}

func TestNewClient_setsDefaultHTTPClient(t *testing.T) {
	client, err := NewClient("https://example.com/foo/bar")
	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(client.HTTPClient, http.DefaultClient) {
		t.Fatalf("expected %#v to equal %#v", client.HTTPClient, http.DefaultClient)
	}
}

func TestLogin_missingUsername(t *testing.T) {
	client, err := NewClient("https://example.com/foo/bar")
	if err != nil {
		t.Fatal(err)
	}

	_, err = client.Login("", "")
	if err == nil {
		t.Fatal("expected error, but nothing was returned")
	}

	expected := "client: missing username"
	if !strings.Contains(err.Error(), expected) {
		t.Fatalf("expected %q to contain %q", err.Error(), expected)
	}
}

func TestLogin_missingPassword(t *testing.T) {
	client, err := NewClient("https://example.com/foo/bar")
	if err != nil {
		t.Fatal(err)
	}

	_, err = client.Login("username", "")
	if err == nil {
		t.Fatal("expected error, but nothing was returned")
	}

	expected := "client: missing password"
	if !strings.Contains(err.Error(), expected) {
		t.Fatalf("expected %q to contain %q", err.Error(), expected)
	}
}

func TestLogin_serverErrorMessage(t *testing.T) {
	server := newTestAtlasServer(t)
	defer server.Stop()

	client, err := NewClient(server.URL.String())
	if err != nil {
		t.Fatal(err)
	}

	_, err = client.Login("username", "password")
	if err == nil {
		t.Fatal("expected error, but nothing was returned")
	}

	if err != ErrAuth {
		t.Fatalf("bad: %s", err)
	}
}

func TestLogin_success(t *testing.T) {
	server := newTestAtlasServer(t)
	defer server.Stop()

	client, err := NewClient(server.URL.String())
	if err != nil {
		t.Fatal(err)
	}

	token, err := client.Login("sethloves", "bacon")
	if err != nil {
		t.Fatal(err)
	}

	if client.Token == "" {
		t.Fatal("expected client token to be set")
	}

	if token == "" {
		t.Fatal("expected token to be returned")
	}
}

func TestRequest_getsData(t *testing.T) {
	server := newTestAtlasServer(t)
	defer server.Stop()

	client, err := NewClient(server.URL.String())
	if err != nil {
		t.Fatal(err)
	}

	request, err := client.Request("GET", "/_status/200", nil)
	if err != nil {
		t.Fatal(err)
	}

	if _, err := checkResp(client.HTTPClient.Do(request)); err != nil {
		t.Fatal(err)
	}
}

func TestRequest_railsError(t *testing.T) {
	server := newTestAtlasServer(t)
	defer server.Stop()

	client, err := NewClient(server.URL.String())
	if err != nil {
		t.Fatal(err)
	}

	request, err := client.Request("GET", "/_rails-error", nil)
	if err != nil {
		t.Fatal(err)
	}

	_, err = checkResp(client.HTTPClient.Do(request))
	if err == nil {
		t.Fatal("expected error, but nothing was returned")
	}

	expected := &RailsError{
		Errors: []string{
			"this is an error",
			"this is another error",
		},
	}

	if !reflect.DeepEqual(err, expected) {
		t.Fatalf("expected %+v to be %+v", err, expected)
	}
}

func TestRequest_notFoundError(t *testing.T) {
	server := newTestAtlasServer(t)
	defer server.Stop()

	client, err := NewClient(server.URL.String())
	if err != nil {
		t.Fatal(err)
	}

	request, err := client.Request("GET", "/_status/404", nil)
	if err != nil {
		t.Fatal(err)
	}

	_, err = checkResp(client.HTTPClient.Do(request))
	if err == nil {
		t.Fatal("expected error, but nothing was returned")
	}

	if err != ErrNotFound {
		t.Fatalf("bad error: %#v", err)
	}
}

func TestRequestJSON_decodesData(t *testing.T) {
	server := newTestAtlasServer(t)
	defer server.Stop()

	client, err := NewClient(server.URL.String())
	if err != nil {
		t.Fatal(err)
	}

	request, err := client.Request("GET", "/_json", nil)
	if err != nil {
		t.Fatal(err)
	}

	response, err := checkResp(client.HTTPClient.Do(request))
	if err != nil {
		t.Fatal(err)
	}

	var decoded struct{ Ok bool }
	if err := decodeJSON(response, &decoded); err != nil {
		t.Fatal(err)
	}

	if !decoded.Ok {
		t.Fatal("expected decoded response to be Ok, but was not")
	}
}
