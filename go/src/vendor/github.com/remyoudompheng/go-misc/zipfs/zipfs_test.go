package zipfs

import (
	"archive/zip"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestServeZip(t *testing.T) {
	z, err := zip.OpenReader("testdata/alpm.zip")
	if err != nil {
		t.Fatal(err)
	}
	defer z.Close()
	h := http.StripPrefix("/zip", http.FileServer(NewZipFS(&z.Reader)))
	srv := httptest.NewServer(h)
	defer srv.Close()

	url := srv.URL + "/zip/alpm.go"
	t.Log(url)
	resp, err := http.Get(url)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%q", data[:64])
}
