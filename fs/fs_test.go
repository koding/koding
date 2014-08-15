package fs

import (
	"encoding/base64"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"reflect"
	"testing"
	"time"

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

	remote = fs.NewClient("http://127.0.0.1:3636/kite")
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

func TestWatcher(t *testing.T) {
	testDir := "testdata"
	addfile := "testdata/example1.txt"

	defer os.Remove(addfile)

	done := make(chan struct{}, 1)

	onChange := dnode.Callback(func(r *dnode.Partial) {
		s := r.MustSlice()
		m := s[0].MustMap()

		e := m["event"].MustString()

		var f = &FileEntry{}
		m["file"].Unmarshal(f)

		if e == "added" && f.Name == "example1.txt" {
			done <- struct{}{}
		}
	})

	_, err := remote.Tell("readDirectory", struct {
		Path     string
		OnChange dnode.Function
	}{
		Path:     testDir,
		OnChange: onChange,
	})
	if err != nil {
		t.Fatal(err)
	}

	ioutil.WriteFile(addfile, []byte("example"), 0755)

	select {
	case <-done:
	case <-time.After(time.Second * 2):
		t.Fatal("timeout watcher after two seconds")
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

func TestGetInfo(t *testing.T) {
	testFile := "testdata/testfile1.txt"

	resp, err := remote.Tell("getInfo", struct {
		Path string
	}{
		Path: testFile,
	})
	if err != nil {
		t.Fatal(err)
	}

	f := &FileEntry{}
	err = resp.Unmarshal(f)
	if err != nil {
		t.Fatal(err)
	}

	if f.Name != filepath.Base(testFile) {
		t.Errorf("got %s expecting %s", f.Name, testFile)
	}

	if !f.Exists {
		t.Errorf("file %s should exists", testFile)
	}
}

func TestSetPermissions(t *testing.T) {
	testFile := "testdata/testfile1.txt"

	testPerm := 0755
	resp, err := remote.Tell("setPermissions", struct {
		Path      string
		Mode      os.FileMode
		Recursive bool
	}{
		Path: testFile,
		Mode: os.FileMode(testPerm),
	})
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("setPermissions should return true")
	}

	f, err := os.Open(testFile)
	if err != nil {
		t.Fatal(err)
	}
	fi, err := f.Stat()
	if err != nil {
		t.Fatal(err)
	}

	if fi.Mode() != os.FileMode(testPerm) {
		t.Errorf("got %v expecting %v", fi.Mode(), testPerm)
	}

}

func TestRemove(t *testing.T) {
	testFile, err := ioutil.TempFile("", "")
	if err != nil {
		t.Fatal(err)
	}

	resp, err := remote.Tell("remove", struct {
		Path string
	}{
		Path: testFile.Name(),
	})
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("removing should return true")
	}

	ok, err := exists(testFile.Name())
	if err != nil {
		t.Error(err)
	}

	if ok {
		t.Fatalf("file still does exists %s", testFile.Name())
	}

}

func TestRename(t *testing.T) {
	testFile, err := ioutil.TempFile("", "")
	if err != nil {
		t.Fatal(err)
	}

	testNewPath := "kite.txt"
	defer os.Remove(testNewPath)

	resp, err := remote.Tell("rename", struct {
		OldPath string
		NewPath string
	}{
		OldPath: testFile.Name(),
		NewPath: testNewPath,
	})
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("renaming should return true")
	}

	ok, err := exists(testFile.Name())
	if err != nil {
		t.Error(err)
	}

	if ok {
		t.Fatalf("file still does exists %s", testFile.Name())
	}

	ok, err = exists(testNewPath)
	if err != nil {
		t.Error(err)
	}

	if !ok {
		t.Fatalf("file does not exists %s", testNewPath)
	}
}

func TestCreateDirectory(t *testing.T) {
	testDir := "testdata/anotherDir"
	testRecursiveDir := "testdata/exampleDir/inception"
	defer os.Remove(testDir)
	defer os.RemoveAll(testRecursiveDir)

	resp, err := remote.Tell("createDirectory", struct {
		Path      string
		Recursive bool
	}{
		Path: testDir,
	})
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("createDirectory should return true")
	}

	ok, err := exists(testDir)
	if err != nil {
		t.Error(err)
	}

	if !ok {
		t.Fatalf("dir does not exists %s", testDir)
	}

	resp, err = remote.Tell("createDirectory", struct {
		Path      string
		Recursive bool
	}{
		Path:      testRecursiveDir,
		Recursive: true,
	})
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("createDirectory recursive should return true")
	}

	ok, err = exists(testRecursiveDir)
	if err != nil {
		t.Error(err)
	}

	if !ok {
		t.Fatalf("dir does not exists %s", testRecursiveDir)
	}
}

func TestMove(t *testing.T) {
	TestRename(t)
}

func TestCopy(t *testing.T) {
	testFile, err := filepath.Abs("testdata/testfile1.txt")
	if err != nil {
		t.Fatal(err)
	}

	newFile, err := filepath.Abs("testdata/testfile2.txt")
	if err != nil {
		t.Fatal(err)
	}

	defer os.Remove(newFile)

	resp, err := remote.Tell("copy", struct {
		SrcPath string
		DstPath string
	}{
		SrcPath: testFile,
		DstPath: newFile,
	})
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("copy should return true")
	}

	ok, err := exists(newFile)
	if err != nil {
		t.Error(err)
	}

	if !ok {
		t.Fatalf("file does not exists %s", newFile)
	}

	testContent, err := ioutil.ReadFile(testFile)
	if err != nil {
		t.Error(err)
	}

	newContent, err := ioutil.ReadFile(newFile)
	if err != nil {
		t.Error(err)
	}

	if string(testContent) != string(newContent) {
		t.Errorf("got %+v, expected %+v", string(testContent), string(newContent))
	}
}

func exists(file string) (bool, error) {
	_, err := os.Stat(file)
	if err == nil {
		return true, nil // file exist
	}

	if os.IsNotExist(err) {
		return false, nil // file does not exist
	}

	return false, err
}
