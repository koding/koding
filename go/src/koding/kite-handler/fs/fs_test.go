package fs

import (
	"encoding/base64"
	"io/ioutil"
	"log"
	"os"
	"reflect"
	"testing"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

var (
	fs     *kite.Kite
	remote *kite.Client
)

func init() {
	fs = kite.New("fs", "0.0.1")
	fs.Config.DisableAuthentication = true
	fs.Config.Port = 3636
	fs.HandleFunc("readDirectory", ReadDirectory)
	fs.HandleFunc("glob", Glob)
	fs.HandleFunc("readFile", ReadFile)
	fs.HandleFunc("writeFile", WriteFile)
	fs.HandleFunc("uniquePath", UniquePath)
	fs.HandleFunc("getInfo", GetInfo)
	fs.HandleFunc("setPermissions", SetPermissions)
	fs.HandleFunc("remove", Remove)
	fs.HandleFunc("rename", Rename)
	fs.HandleFunc("createDirectory", CreateDirectory)
	fs.HandleFunc("move", Move)
	fs.HandleFunc("copy", Copy)

	go fs.Run()
	<-fs.ServerReadyNotify()

	client := kite.New("client", "0.0.1")
	client.Config.DisableAuthentication = true
	remote = client.NewClientString("ws://127.0.0.1:3636")
	err := remote.Dial()
	if err != nil {
		log.Fatal("err")
	}
}

func TestReadDirectory(t *testing.T) {
	testDir := "."

	files, err := ioutil.ReadDir(testDir)
	if err != nil {
		t.Fatal(err)
	}

	currentFiles := make([]string, len(files))
	for i, f := range files {
		currentFiles[i] = f.Name()
	}

	resp, err := remote.Tell("readDirectory", struct {
		Path     string
		OnChange dnode.Function
	}{
		Path:     testDir,
		OnChange: dnode.Function{},
	})

	if err != nil {
		t.Fatal(err)
	}

	f, err := resp.Map()
	if err != nil {
		t.Fatal(err)
	}

	entries, err := f["files"].SliceOfLength(len(files))
	if err != nil {
		t.Fatal(err)
	}

	respFiles := make([]string, len(files))
	for i, e := range entries {
		f := &FileEntry{}
		err := e.Unmarshal(f)
		if err != nil {
			t.Fatal(err)
		}

		respFiles[i] = f.Name
	}

	if !reflect.DeepEqual(respFiles, currentFiles) {
		t.Error("got %+v, expected %+v", respFiles, currentFiles)
	}
}

func TestGlob(t *testing.T) {
	testGlob := "*"

	files, err := glob(testGlob)
	if err != nil {
		t.Fatal(err)
	}

	resp, err := remote.Tell("glob", struct {
		Pattern string
	}{
		Pattern: testGlob,
	})
	if err != nil {
		t.Fatal(err)
	}

	var r []string
	err = resp.Unmarshal(&r)
	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(r, files) {
		t.Errorf("got %+v, expected %+v", r, files)
	}
}

func TestReadFile(t *testing.T) {
	testFile := "testdata/testfile1.txt"

	content, err := ioutil.ReadFile(testFile)
	if err != nil {
		t.Error(err)
	}

	resp, err := remote.Tell("readFile", struct {
		Path string
	}{
		Path: testFile,
	})
	if err != nil {
		t.Fatal(err)
	}

	buf := resp.MustMap()["content"].MustString()

	s, err := base64.StdEncoding.DecodeString(buf)
	if err != nil {
		t.Error(err)
	}

	if string(s) != string(content) {
		t.Errorf("got %s, expecting %s", string(s), string(content))
	}

}

func TestWriteFile(t *testing.T) {
	testFile, err := ioutil.TempFile("", "")
	if err != nil {
		t.Fatal(err)
	}
	defer os.Remove(testFile.Name())

	content := []byte("hello kite")

	t.Log("writeFile write to a  file")
	resp, err := remote.Tell("writeFile", struct {
		Path           string
		Content        []byte
		DoNotOverwrite bool
		Append         bool
	}{
		Path:    testFile.Name(),
		Content: content,
	})
	if err != nil {
		t.Fatal(err)
	}

	if int(resp.MustFloat64()) != len(content) {
		t.Errorf("content len is wrong. got %d expected %d", int(resp.MustFloat64()), len(content))
	}

	buf, err := ioutil.ReadFile(testFile.Name())
	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(buf, content) {
		t.Errorf("content is wrong. got '%s' expected '%s'", string(buf), string(content))
	}

	t.Log("writeFile try to write if DoNotOverwrite is enabled")
	resp, err = remote.Tell("writeFile", struct {
		Path           string
		Content        []byte
		DoNotOverwrite bool
		Append         bool
	}{
		Path:           testFile.Name(),
		Content:        content,
		DoNotOverwrite: true,
	})
	if err == nil {
		t.Fatal("DoNotOverwrite is enabled, it shouldn't open the file", err)
	}

	t.Log("writeFile append to an existing file")
	resp, err = remote.Tell("writeFile", struct {
		Path           string
		Content        []byte
		DoNotOverwrite bool
		Append         bool
	}{
		Path:    testFile.Name(),
		Content: content,
		Append:  true,
	})
	if err != nil {
		t.Fatal(err)
	}

	buf, err = ioutil.ReadFile(testFile.Name())
	if err != nil {
		t.Fatal(err)
	}

	ap := string(content) + string(content)
	if !reflect.DeepEqual(buf, []byte(ap)) {
		t.Errorf("content is wrong. got '%s' expected '%s'", string(buf), ap)
	}
}

func TestUniquePath(t *testing.T) {
	testFile := "testdata/testfile1.txt"
	tempFiles := []string{}

	defer func() {
		for _, f := range tempFiles {
			os.Remove(f)
		}
	}()

	uniqueFile := func() string {
		resp, err := remote.Tell("uniquePath", struct {
			Path string
		}{
			Path: testFile,
		})
		if err != nil {
			t.Fatal(err)
		}

		s := resp.MustString()

		tempFiles = append(tempFiles, s) // add to remove them later

		// create the file now, the next call to uniquePath should generate a
		// different name when this files exits.
		err = ioutil.WriteFile(s, []byte("test111"), 0755)
		if err != nil {
			t.Fatal(err)
		}

		return s
	}

	file1 := uniqueFile()
	file2 := uniqueFile()

	if file1 == file2 {
		t.Error("files should be different, got the same %s", file1)
	}
}

func TestGetInfo(t *testing.T)         {}
func TestSetPermissions(t *testing.T)  {}
func TestRemove(t *testing.T)          {}
func TestRename(t *testing.T)          {}
func TestCreateDirectory(t *testing.T) {}
func TestMove(t *testing.T)            {}
func TestCopy(t *testing.T)            {}
