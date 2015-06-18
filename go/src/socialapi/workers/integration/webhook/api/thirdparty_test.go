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
			w.Header().Set("Content-Type", "application/json")
			if page == "2" {
				fmt.Fprintln(w, `[]`)
				return
			}

			fmt.Fprintln(w, userRepoResponse)
		},
	)

	orgEndpoint := fmt.Sprintf(OrgEndpoint, "canthefason")

	mux.HandleFunc(orgEndpoint,
		func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")

			fmt.Fprintln(w, organizationResponse)
		},
	)

	orgRepoEndpoint := fmt.Sprintf(OrgRepoEndpoint, "koding")
	mux.HandleFunc(orgRepoEndpoint,
		func(w http.ResponseWriter, r *http.Request) {
			page := r.URL.Query().Get("page")
			response := orgRepoResponsePage1
			switch page {
			case "2":
				response = orgRepoResponsePage2
			case "3":
				response = orgRepoResponsePage3
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
			Convey("it should be able to fetch repos owned by the user", func() {
				repos, err := c.fetchRepos("canthefason", "123", UserRepoEndpoint)
				So(err, ShouldBeNil)
				So(len(repos), ShouldEqual, 1)
				So(repos[0], ShouldEqual, "eventexporter")
			})

			Convey("it should be able to fetch user's organizations", func() {
				orgs, err := c.fetchOrganizations("canthefason", "123")
				So(err, ShouldBeNil)
				So(len(orgs), ShouldEqual, 1)
				So(orgs[0].Name, ShouldEqual, "koding")
			})

			Convey("it should be able to fetch all user repositories with organization", func() {
				orgs := []Organization{Organization{Name: "koding"}}
				repos, err := c.fetchUserRepos("canthefason", "123", orgs)
				So(err, ShouldBeNil)
				userRepos, ok := repos["canthefason"]
				So(ok, ShouldBeTrue)
				So(len(userRepos), ShouldEqual, 1)
				So(userRepos[0], ShouldEqual, "eventexporter")

				kodingRepos, ok := repos["koding"]
				So(ok, ShouldBeTrue)
				So(len(kodingRepos), ShouldEqual, 3)
				So(kodingRepos[0], ShouldEqual, "IDE")
				So(kodingRepos[1], ShouldEqual, "kd-react")
				So(kodingRepos[2], ShouldEqual, "terraform")
			})
		})
	})
}
