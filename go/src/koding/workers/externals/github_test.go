package main

import (
	"fmt"
	. "launchpad.net/gocheck"
	"log"
	"net/http"
)

func init() {
	log.SetPrefix("Externals test: ")
}

func (s *MySuite) TestFailureWhenFetchingUserInfo(c *C) {
	github := githubClientFixture()
	githubMux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, nil)
	})

	_, err := github.FetchUserInfo()
	c.Assert(err, NotNil)
}

func (s *MySuite) TestFetchingUserInfo(c *C) {
	github := githubClientFixture()
	githubMux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, `{"id":164864,"email":"me@sent-hil.com","name":"senthil","login":"sent-hil","public_repos":10,"followers":14,"location":"SF","company":"http://bit.ly/Q6MIib"}`)
	})

	userInfo, err := github.FetchUserInfo()
	c.Assert(err, IsNil)
	c.Assert(userInfo["id"], Equals, "164864")
	c.Assert(userInfo["email"], Equals, "me@sent-hil.com")
}

func (s *MySuite) TestFailureWhenFetchingTags(c *C) {
	github := githubClientFixture()
	githubMux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, nil)
	})

	_, err := github.FetchTags()
	c.Assert(err, NotNil)
}

func (s *MySuite) TestFetchingRelatedTags(c *C) {
	github := githubClientFixture()
	githubMux.HandleFunc("/user/repos", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, `[{"id":7363129,"name":"r"},{"id":10514362,"name":"r2"}]`)
	})

	githubMux.HandleFunc("/repos/l/r/languages", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, `{"Ruby":1, "Go":1}`)
	})

	githubMux.HandleFunc("/repos/l/r2/languages", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, `{"Go":1}`)
	})

	github.UserInfo = strToInf{
		"id":    "10",
		"email": "e",
		"name":  "n",
		"login": "l",
	}

	tags, err := github.FetchTags()
	c.Assert(err, IsNil)

	c.Check(len(tags), Equals, 2)
	c.Check(tags["Ruby"], Equals, 1)
	c.Check(tags["Go"], Equals, 2)
}
