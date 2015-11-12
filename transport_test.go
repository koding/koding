package fuseklient

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
		panic(fmt.Sprintf("Expected '%s' to be in list of mocked responses.", methodName))
	}

	bytes, err := json.Marshal(r)
	if err != nil {
		panic(err.Error())
	}

	return json.Unmarshal(bytes, &res)
}

func TestFakeTransport(t *testing.T) {
	Convey("fakeTransport", t, func() {
		ft := &fakeTransport{
			TripResponses: map[string]interface{}{"indiana": struct{ Name string }{"jones"}},
		}

		Convey("It should implement Transport interface", func() {
			var _ transport.Transport = (*fakeTransport)(nil)
		})

		Convey("It should return unmarshal mock into response for Trip", func() {
			res := struct{ Name string }{}

			So(ft.Trip("indiana", "", &res), ShouldBeNil)
			So(res.Name, ShouldEqual, "jones")
		})
	})
}
