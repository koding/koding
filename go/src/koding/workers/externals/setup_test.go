package main

import (
	"encoding/json"
	"errors"
	githubExternal "github.com/google/go-github/github"
	"io/ioutil"
	. "launchpad.net/gocheck"
	"log"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
)

// SETUP GOCHECK

func Test(t *testing.T) { TestingT(t) }

type MySuite struct{}

var (
	_                = Suite(&MySuite{})
	client           *githubExternal.Client
	githubMux        *http.ServeMux
	githubTestServer *httptest.Server
	neoMux           *http.ServeMux
	neoTestServer    *httptest.Server
)

func (s *MySuite) SetUpSuite(c *C) {
	resetMongoToDefaultTestMongo()
}

// SETUP MOCKS

func setupExternalGithubClient() *githubExternal.Client {
	githubMux = http.NewServeMux()
	githubTestServer = httptest.NewServer(githubMux)
	client = githubExternal.NewClient(nil)
	client.BaseURL, _ = url.Parse(githubTestServer.URL)

	return client
}

func setupNeoMock() {
	neoMux = http.NewServeMux()
	neoTestServer = httptest.NewServer(neoMux)

	NEO_CONN_URL = neoTestServer.URL
}

func tearDownNeoMock() {
	neoTestServer.Close()
}

// FIXTURES

func githubClientFixture() GithubClient {
	githubToken := githubTokenFixture()
	externalClient := setupExternalGithubClient()
	githubClient := &GithubClient{githubToken, externalClient, strToInf{}}

	return *githubClient
}

func githubTokenFixture() Token {
	return Token{
		ServiceName: "github",
		Value:       "github_access_token",
		UserId:      "4f14f9d8519ab4c62e000033",
	}
}

// Replica of input from RabbitMQ.
func githubTokenDataFixture(c *C) Token {
	githubToken := githubTokenFixture()
	return githubToken
}

// SWITCH CLIENTS

func resetMongoToDefaultTestMongo() {
	mongo = &FakeMongo{}
}

func setupFakeGithubClient() {
	clients["github"] = NewGithubFakeClient
}

func setupFakeFailGithubClient() {
	clients["github"] = NewFailGithubFakeClient
}

// SUCCESS CLIENT MOCKS

type FakeMongo struct{}

func (n *FakeMongo) GetUser(userId string) (strToInf, bool) {
	return map[string]interface{}{"_id": userId, "id": userId, "name": "JAccount"}, true
}

func (n *FakeMongo) GetTagByName(name, provider string) (strToInf, bool) {
	fakeId := "4f701455d54b226031000201"
	return map[string]interface{}{
		"_id":   fakeId,
		"id":    fakeId,
		"group": "koding",
		"name":  "JTag",
		"slug":  "koding",
		"title": name,
	}, true
}

func (n *FakeMongo) GetUserByProviderId(id, provider string) (strToInf, bool) {
	return map[string]interface{}{
		"_id":  "1",
		"id":   "1",
		"name": "JAccount",
		"foreignAuth": map[string]interface{}{
			"github": map[string]interface{}{
				"foreignId": "2",
			},
		},
	}, true
}

type GithubFakeClient struct {
	Token
	client GithubClient
}

func NewGithubFakeClient(token Token) Client {
	fakeClient := githubClientFixture()

	return &GithubFakeClient{token, fakeClient}
}

func (g *GithubFakeClient) FetchUserInfo() (strToInf, error) {
	info := strToInf{
		"id":    "164864",
		"email": "me@sent-hil.com",
		"name":  "sent hil",
		"login": "sent-hil",
	}

	return info, nil
}

func (g *GithubFakeClient) FetchTags() (strToInf, error) {
	return strToInf{"Ruby": 1}, nil
}

func (g *GithubFakeClient) FetchFriends() (strToInf, error) {
	return strToInf{"email": true}, nil
}

// FAIL CLIENT MOCKS

type EmptyUserFakeMongo struct{}

func (n *EmptyUserFakeMongo) GetUser(userId string) (strToInf, bool) {
	return map[string]interface{}{}, false
}

func (n *EmptyUserFakeMongo) GetTagByName(userId, provider string) (strToInf, bool) {
	return map[string]interface{}{}, false
}

func (n *EmptyUserFakeMongo) GetUserByProviderId(username, provider string) (strToInf, bool) {
	return map[string]interface{}{}, false
}

type FailGithubFakeClient struct {
	Token
	client GithubClient
}

func NewFailGithubFakeClient(token Token) Client {
	fakeClient := githubClientFixture()

	return &FailGithubFakeClient{token, fakeClient}
}

func (f *FailGithubFakeClient) FetchUserInfo() (strToInf, error) {
	return nil, errors.New("does not exist")
}

func (f *FailGithubFakeClient) FetchTags() (strToInf, error) {
	return nil, errors.New("...")
}

func (f *FailGithubFakeClient) FetchFriends() (strToInf, error) {
	return nil, errors.New("...")
}

// HTTP HELPERS

func outputBody(r *http.Request) {
	req := parseBody(r)

	log.Println()
	for _, mp := range req {
		for k, v := range mp {
			log.Printf("%v => %v", k, v)
		}
		log.Println()
	}
}

func parseBody(r *http.Request) []strToInf {
	body, _ := ioutil.ReadAll(r.Body)
	var req []strToInf
	json.Unmarshal(body, &req)

	return req
}
