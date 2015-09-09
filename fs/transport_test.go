package fs

import (
	"encoding/json"
	"fmt"
	"testing"

	"github.com/koding/fuseklient/transport"
	. "github.com/smartystreets/goconvey/convey"
)

// fakeTransport implements Transport; is used in testing Transport requests
// and mocking responses.
type fakeTransport struct {
	TripResponses map[string]interface{}
}

func (f *fakeTransport) Trip(methodName string, req interface{}, res interface{}) error {
	r, ok := f.TripResponses[methodName]
	if !ok {
		return fmt.Errorf("Expected '%s' to be in list of mocked responses.", methodName)
	}

	bytes, err := json.Marshal(r)
	if err != nil {
		return err
	}

	return json.Unmarshal(bytes, &res)
}

func TestFakeTransport(t *testing.T) {
	Convey("Given fake transport", t, func() {
		ft := &fakeTransport{
			TripResponses: map[string]interface{}{"indiana": struct{ Name string }{"jones"}},
		}

		Convey("It implements Transport", func() {
			var _ transport.Transport = (*fakeTransport)(nil)
		})

		Convey("It should return error if method don't exist", func() {
			So(ft.Trip("random", "", ""), ShouldNotBeNil)
		})

		Convey("It should return unmarshal mock into response for method", func() {
			res := struct{ Name string }{}

			So(ft.Trip("indiana", "", &res), ShouldBeNil)
			So(res.Name, ShouldEqual, "jones")
		})
	})
}
