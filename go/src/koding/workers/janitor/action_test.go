package main

import (
	"encoding/json"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestDeleteUser(t *testing.T) {
	testHelper := func() {}

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		testHelper()
		var ur usernameReq

		if err := json.NewDecoder(req.Body).Decode(&ur); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		var c *http.Cookie
		for _, cookie := range req.Cookies() {
			if cookie.Name == "clientId" {
				c = cookie
				break
			}
		}

		if c == nil {
			http.Error(w, "client id cookie is nil", http.StatusBadRequest)
			return
		}

		ses, err := modelhelper.GetSessionById(c.Value)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		if ses == nil {
			http.Error(w, "couldnt find session", http.StatusBadRequest)
			return
		}

		if ses.Username != ur.Username {
			http.Error(w, "usernames did not match", http.StatusBadRequest)
			return
		}

	}))
	defer server.Close()

	deleterFn := newDeleteUserFunc(server.URL)

	Convey("Given a fake delete endpoint", t, func() {

		Convey("Should return OK when everything is fine", func() {
			err := deleterFn(&models.User{Name: "my-test-username"}, "")
			So(err, ShouldBeNil)

			err = deleterFn(&models.User{Name: ""}, "")
			So(err, ShouldNotBeNil)
		})

		Convey("Should return timeout error, if execeeds timeout value", func() {
			testHelperCache := testHelper
			timeoutCache := defClient.Timeout
			defClient.Timeout = time.Millisecond * 100

			testHelper = func() {
				time.Sleep(defClient.Timeout * 2)
			}

			defer func() {
				testHelper = testHelperCache
				defClient.Timeout = timeoutCache
			}()

			err := deleterFn(&models.User{Name: "my-test-username"}, "")
			So(err, ShouldNotBeNil)
		})
	})

	deleterFn = newDeleteUserFunc("http://localhost:" + freePort())

	Convey("Given an invalid fake delete endpoint", t, func() {
		Convey("Should return error immediately", func() {
			err := deleterFn(&models.User{Name: "my-test-username"}, "")
			So(err, ShouldNotBeNil)
		})
	})

}

// Ask the kernel for a free open port that is ready to use
func freePort() string {
	addr, err := net.ResolveTCPAddr("tcp", "localhost:0")
	if err != nil {
		panic(err)
	}

	l, err := net.ListenTCP("tcp", addr)
	if err != nil {
		panic(err)
	}
	defer l.Close()

	return strconv.Itoa(l.Addr().(*net.TCPAddr).Port)
}
