package api

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func setup(t *testing.T, f func(client *Client)) {
	mux := http.NewServeMux()
	server := httptest.NewServer(mux)

	mux.HandleFunc(UserRepoEndpoint,
		func(w http.ResponseWriter, r *http.Request) {
			page := r.URL.Query().Get("page")
			response := userRepoResponsePage1
			switch page {
			case "2":
				response = userRepoResponsePage2
			case "3":
				response = userRepoResponsePage3
			case "4":
				response = `[]`
			}

			w.Header().Set("Content-Type", "application/json")

			fmt.Fprintln(w, response)
		},
	)
	defer server.Close()

	// Make an API client and inject
	client := &Client{
		client:  new(http.Client),
		baseUrl: server.URL,
	}

	f(client)
}

func TestFetchUserRepos(t *testing.T) {
	setup(t, func(c *Client) {
		Convey("while testing user repository fetcher", t, func() {
			Convey("it should be able to fetch all user repositories from different organizations", func() {
				repos, err := c.fetchRepos("canthefason", "123")
				So(err, ShouldBeNil)
				So(len(repos), ShouldEqual, 3)

				So(repos[0], ShouldEqual, "koding/IDE")
				So(repos[1], ShouldEqual, "koding/kd-react")
				So(repos[2], ShouldEqual, "koding/terraform")
			})
		})
	})
}
