package fuseklient

import (
	"encoding/json"
	"fmt"
	"net/http/httptest"
	"os"
	"testing"

	"koding/fuseklient/transport"
	klientfs "koding/klient/fs"

	"github.com/koding/kite"

	"github.com/jacobsa/fuse"

	. "github.com/smartystreets/goconvey/convey"
)

// fakeTransport implements Transport; is used in testing Transport requests
// and mocking responses.
type fakeTransport struct {
	TripResponses map[string]interface{}
}

// newKlient creates a kite, populates it with Klient methods, and returns
// a dialed kite Client. Mocking an actively running Klient, but still using the real
// klient methods.
func newKlientClient() (*kite.Client, error) {
	k := kite.New("kiteServ", "0.0.0")
	k.Config.DisableAuthentication = true

	k.HandleFunc("fs.readDirectory", klientfs.ReadDirectory)
	k.HandleFunc("fs.glob", klientfs.Glob)
	k.HandleFunc("fs.readFile", klientfs.ReadFile)
	k.HandleFunc("fs.writeFile", klientfs.WriteFile)
	k.HandleFunc("fs.uniquePath", klientfs.UniquePath)
	k.HandleFunc("fs.getInfo", klientfs.GetInfo)
	k.HandleFunc("fs.setPermissions", klientfs.SetPermissions)
	k.HandleFunc("fs.remove", klientfs.Remove)
	k.HandleFunc("fs.rename", klientfs.Rename)
	k.HandleFunc("fs.createDirectory", klientfs.CreateDirectory)
	k.HandleFunc("fs.move", klientfs.Move)
	k.HandleFunc("fs.copy", klientfs.Copy)
	k.HandleFunc("fs.getDiskInfo", klientfs.GetDiskInfo)

	testServ := httptest.NewServer(k)
	kiteClient := kite.New("testClient", "0.0.0").NewClient(fmt.Sprintf("%s/kite", testServ.URL))

	err := kiteClient.Dial()
	if err != nil {
		return nil, err
	}

	return kiteClient, nil
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

func (f *fakeTransport) CreateDir(path string, mode os.FileMode) error {
	return nil
}

func (f *fakeTransport) ReadDir(path string, r bool) (*transport.ReadDirRes, error) {
	var res *transport.ReadDirRes
	return res, f.Trip("fs.readDirectory", nil, &res)
}

func (f *fakeTransport) Rename(oldPath, newPath string) error {
	return f.Trip("fs.rename", nil, nil)
}

func (f *fakeTransport) Remove(path string) error {
	return f.Trip("fs.remove", nil, nil)
}

func (f *fakeTransport) WriteFile(path string, content []byte) error {
	return f.Trip("fs.writeFile", nil, nil)
}

func (f *fakeTransport) ReadFile(path string) (*transport.ReadFileRes, error) {
	var res *transport.ReadFileRes
	return res, f.Trip("fs.readFile", nil, &res)
}

func (f *fakeTransport) Exec(path string) (*transport.ExecRes, error) {
	var res *transport.ExecRes
	return res, f.Trip("exec", nil, &res)
}

func (f *fakeTransport) GetDiskInfo(path string) (*transport.GetDiskInfoRes, error) {
	var res *transport.GetDiskInfoRes
	return res, f.Trip("fs.getDiskInfo", nil, &res)
}

func (f *fakeTransport) GetInfo(path string) (*transport.GetInfoRes, error) {
	var res *transport.GetInfoRes
	return res, f.Trip("fs.getInfo", nil, &res)
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

///// errorTransport

type errorTransport struct {
	*fakeTransport
	ErrorResponses map[string]error
}

func (e *errorTransport) Trip(methodName string, req interface{}, res interface{}) error {
	if err, ok := e.ErrorResponses[methodName]; ok {
		return err
	}

	return e.fakeTransport.Trip(methodName, req, res)
}

func (e *errorTransport) WriteFile(path string, content []byte) error {
	return e.Trip("fs.writeFile", nil, nil)
}

func TestErrorTransport(t *testing.T) {
	Convey("errorTransport", t, func() {
		Convey("It should implement Transport interface", func() {
			var _ transport.Transport = (*errorTransport)(nil)
		})

		Convey("It should return error if called method has error", func() {
			e := newWriteErrTransport()

			err := e.WriteFile("", nil)
			So(err, ShouldEqual, fuse.EIO)
		})
	})
}
