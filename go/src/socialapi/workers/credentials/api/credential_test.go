package api

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"io/ioutil"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

var (
	ErrEmptyPath       = errors.New("path is empty")
	ErrEmptyValueFound = errors.New("either Name or Key is not found")
)

// CR struct is created for testing dowload from S3
type CR struct {
	Name string
	Key  string
}

func TestStoreCredentials(t *testing.T) {
	Convey("While storing credentials", t, func() {
		Convey("storing should be successful", func() {
			c := &CR{
				Name: "test-Name",
				Key:  "test-Key",
			}

			byt, err := json.Marshal(c)
			So(err, ShouldBeNil)

			aa := bytes.NewReader(byt)

			So(uploadHandler("pathName", aa), ShouldBeNil)
		})

	})
}

func TestDownloadCredentials(t *testing.T) {
	Convey("While downloading credentials", t, func() {
		Convey("download should be done successfully", func() {
			pathName := "mehmetali"
			b, err := downloadHandler(pathName)
			So(err, ShouldBeNil)
			So(b, ShouldNotBeNil)
			c := &CR{}

			byt := bytes.NewReader(b[pathName])

			err = json.NewDecoder(byt).Decode(c)
			So(err, ShouldBeNil)
			So(c, ShouldNotBeNil)
		})

	})
}

// Actually, this is not a handler function
// Aim of this function is controlling the credentials if there exists or not
func uploadHandler(path string, r io.Reader) error {
	if path == "" {
		return ErrEmptyPath
	}

	plaintext, err := ioutil.ReadAll(r)
	if err != nil {
		return err
	}

	x := &CR{}

	downx := bytes.NewReader(plaintext)
	if err := json.NewDecoder(downx).Decode(x); err != nil {
		return err
	}

	if x.Name == "" || x.Key == "" {
		return ErrEmptyValueFound
	}

	return nil
}

// downloadHandler gives us data created by us before.
// its same with the download from S3 ideally.
func downloadHandler(path string) (map[string][]byte, error) {
	if path == "" {
		return nil, ErrEmptyPath
	}

	pathDownload := make(map[string][]byte, 0)
	pathDownload["mehmetali"] = []byte{123, 34, 78, 97, 109, 101, 34, 58, 34, 109, 101, 104, 109, 101, 116, 97, 108, 105, 115, 97, 118, 97, 115, 34, 44, 34, 75, 101, 121, 34, 58, 34, 97, 103, 57, 56, 52, 119, 115, 104, 118, 105, 97, 115, 118, 57, 121, 55, 121, 101, 118, 111, 121, 79, 92, 117, 48, 48, 50, 54, 65, 89, 102, 92, 117, 48, 48, 50, 54, 89, 70, 86, 79, 89, 101, 111, 118, 111, 102, 101, 34, 125}

	return pathDownload, nil
}
