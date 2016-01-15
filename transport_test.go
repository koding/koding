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

func (f *fakeTransport) CreateDirectory(path string) error {
	return nil
}

func (f *fakeTransport) ReadDirectory(path string, i []string) (transport.FsReadDirectoryRes, error) {
	var res transport.FsReadDirectoryRes
	return res, f.Trip("fs.readDirectory", nil, &res)
}

func (f *fakeTransport) Rename(oldPath, newPath string) error {
	return nil
}

func (f *fakeTransport) Remove(path string) error {
	return nil
}

func (f *fakeTransport) WriteFile(path string, content []byte) error {
	return nil
}

func (f *fakeTransport) ReadFile(path string) (transport.FsReadFileRes, error) {
	var res transport.FsReadFileRes
	return res, f.Trip("fs.readFile", nil, &res)
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
