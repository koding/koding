package transport

import (
	"encoding/json"
	"fmt"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

type fakeTransport struct {
	TripMethodName string
	TripResponse   interface{}
}

func (f *fakeTransport) Trip(methodName string, req interface{}, res interface{}) error {
	if f.TripMethodName != methodName {
		return fmt.Errorf("Expected '%s' as methodName, got '%s'", f.TripMethodName, methodName)
	}

	bytes, err := json.Marshal(f.TripResponse)
	if err != nil {
		return err
	}

	return json.Unmarshal(bytes, &res)
}
func TestFakeTransportStub(t *testing.T) {
	Convey("Given fake transport", t, func() {
		ft := &fakeTransport{
			TripMethodName: "test",
			TripResponse:   struct{ Name string }{"res"},
		}

		Convey("It should return error if method names don't match", func() {
			So(ft.Trip("badmethodname", "", ""), ShouldNotBeNil)
		})

		Convey("It should return unmarshal mock into response", func() {
			res := struct{ Name string }{}

			So(ft.Trip("test", "", &res), ShouldBeNil)
			So(res.Name, ShouldEqual, "res")
		})
	})
}
