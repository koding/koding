package os

import (
	"fmt"
	"net/http/httptest"
	"os/user"
	"testing"

	"github.com/koding/kite"

	. "github.com/smartystreets/goconvey/convey"
)

func TestHome(t *testing.T) {
	Convey("Given Home is called", t, func() {
		s := kite.New("s", "0.0.0")
		s.Config.DisableAuthentication = true
		s.HandleFunc("os.home", Home)
		ts := httptest.NewServer(s)
		c := kite.New("c", "0.0.0").NewClient(fmt.Sprintf("%s/kite", ts.URL))

		So(c.Dial(), ShouldBeNil)

		Convey("It should require username field", func() {
			_, err := c.Tell("os.home")
			So(err, ShouldNotBeNil)

			_, err = c.Tell("os.home", struct {
				NotUsername string
			}{
				NotUsername: "foo",
			})
			So(err, ShouldNotBeNil)
		})

		Convey("Given a username that exists", func() {
			userLookup = func(string) (*user.User, error) {
				return &user.User{
					HomeDir: "/home/foo",
				}, nil
			}

			Convey("It should return that users home", func() {
				res, err := c.Tell("os.home", struct {
					Username string
				}{
					Username: "foo",
				})
				So(err, ShouldBeNil)

				var home string
				So(res.Unmarshal(&home), ShouldBeNil)
				So(home, ShouldEqual, "/home/foo")
			})
		})
	})
}
