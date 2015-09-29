package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestDownloadRemoteToLocal(t *testing.T) {
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "binary contents")
	})

	server := httptest.NewServer(mux)
	defer server.Close()

	Convey("It should download remote file to local", t, func() {
		tempDir, err := ioutil.TempDir("", "")
		So(err, ShouldBeNil)

		binaryPath := filepath.Join(tempDir, "kd")

		err = downloadRemoteToLocal(server.URL, binaryPath)
		So(err, ShouldBeNil)

		contents, err := ioutil.ReadFile(binaryPath)
		So(err, ShouldBeNil)

		So(string(contents), ShouldEqual, "binary contents")

		Convey("It should overwrite binary if it already exists", func() {
			mux := http.NewServeMux()
			mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
				fmt.Fprintf(w, "overwritten contents")
			})

			server := httptest.NewServer(mux)
			defer server.Close()

			err = downloadRemoteToLocal(server.URL, binaryPath)
			So(err, ShouldBeNil)

			contents, err := ioutil.ReadFile(binaryPath)
			So(err, ShouldBeNil)

			So(string(contents), ShouldEqual, "overwritten contents")
		})
	})

	Convey("It should create destination directory unless it exists", t, func() {
		tempDir, err := ioutil.TempDir("", "")
		So(err, ShouldBeNil)

		secondaryDir := filepath.Join(tempDir, "secondaryDir")
		binaryPath := filepath.Join(secondaryDir, "kd")

		err = downloadRemoteToLocal(server.URL, binaryPath)
		So(err, ShouldBeNil)

		fi, err := os.Stat(secondaryDir)
		So(err, ShouldBeNil)
		So(fi.IsDir(), ShouldBeTrue)

		contents, err := ioutil.ReadFile(binaryPath)
		So(err, ShouldBeNil)

		So(string(contents), ShouldEqual, "binary contents")
	})
}
