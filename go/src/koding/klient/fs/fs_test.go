package fs

import (
	"encoding/base64"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"syscall"
	"testing"
	"time"

	"koding/klient/testutil"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

var (
	fs *kite.Kite

	// remote defines a remote user calling the fs kite
	remote  *kite.Client
	remote2 *kite.Client

	testfile1 = "testdata/testfile1.txt.tmp"
)

func TestMain(m *testing.M) {
	flag.Parse()

	// NOTE(rjeczalik): copy testdata/testfile1.txt so after test execution
	// the file is not modified.
	if err := testutil.FileCopy("testdata/testfile1.txt", testfile1); err != nil {
		panic(err)
	}

	kiteURL := testutil.GenKiteURL()

	fs = kite.New("fs", "0.0.1")
	fs.Config.DisableAuthentication = true
	fs.Config.Port = kiteURL.Port()
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
	fs.HandleFunc("getDiskInfo", GetDiskInfo)

	go fs.Run()
	<-fs.ServerReadyNotify()
	defer fs.Close()

	remoteKite := kite.New("remote", "0.0.1")
	remoteKite.Config.Username = "remote"
	remote = remoteKite.NewClient(kiteURL.String())
	err := remote.Dial()
	if err != nil {
		log.Fatalf("err")
	}
	defer remoteKite.Close()

	remoteKite2 := kite.New("remote2", "0.0.1")
	remoteKite2.Config.Username = "remote2"
	remote2 = remoteKite2.NewClient(kiteURL.String())
	err = remote2.Dial()
	if err != nil {
		log.Fatalf("err")
	}
	defer remoteKite2.Close()

	os.Exit(m.Run())
}

func benchmarkReadDirectory(b *testing.B, numberOfFiles int) {
	testDir, err := ioutil.TempDir("", "klient")
	if err != nil {
		b.Fatal(err)
	}
	defer os.RemoveAll(testDir)

	for i := 0; i < numberOfFiles; i++ {
		_, err := ioutil.TempFile(testDir, "fs")
		if err != nil {
			b.Fatal(err)
		}
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		remote.Tell("readDirectory", struct {
			Path string
		}{
			Path: testDir,
		})
	}
}

func BenchmarkReadDirectory10(b *testing.B) {
	benchmarkReadDirectory(b, 10)
}

func BenchmarkReadDirectory100(b *testing.B) {
	benchmarkReadDirectory(b, 100)
}

func BenchmarkReadDirectory1000(b *testing.B) {
	benchmarkReadDirectory(b, 1000)
}

func BenchmarkReadDirectory10000(b *testing.B) {
	benchmarkReadDirectory(b, 10000)
}

func TestReadDirectory(t *testing.T) {
	testDir := "testdata"

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

func TestReadDirectoryRecursive(t *testing.T) {
	testDir := "testdata"
	nestedDir := filepath.Join(testDir, "exampleDir")

	files, err := ioutil.ReadDir(testDir)
	if err != nil {
		t.Fatal(err)
	}

	currentFiles := make(map[string]struct{}, len(files))
	for _, f := range files {
		currentFiles[f.Name()] = struct{}{}
	}

	nestedFiles, err := ioutil.ReadDir(nestedDir)
	if err != nil {
		t.Fatal(err)
	}

	for _, f := range nestedFiles {
		currentFiles[f.Name()] = struct{}{}
	}

	resp, err := remote.Tell("readDirectory", struct {
		Path      string
		OnChange  dnode.Function
		Recursive bool
	}{
		Path:      testDir,
		OnChange:  dnode.Function{},
		Recursive: true,
	})

	if err != nil {
		t.Fatal(err)
	}

	f, err := resp.Map()
	if err != nil {
		t.Fatal(err)
	}

	entries, err := f["files"].SliceOfLength(len(currentFiles))
	if err != nil {
		t.Fatal(err)
	}

	if len(entries) != len(currentFiles) {
		t.Errorf("Expected results to have %d count, has %d.",
			len(entries), len(currentFiles),
		)
	}

	for _, e := range entries {
		f := &FileEntry{}
		if err := e.Unmarshal(f); err != nil {
			t.Fatal(err)
		}

		if _, ok := currentFiles[f.Name]; !ok {
			t.Fatal(err)
		}
	}
}

func TestWatcher(t *testing.T) {
	testDir := "testdata"

	type change struct {
		action string
		name   string
	}

	onChangeFunc := func(changes *[]change) dnode.Function {
		return dnode.Callback(func(r *dnode.Partial) {
			s := r.MustSlice()
			m := s[0].MustMap()

			e := m["event"].MustString()

			var f = &FileEntry{}
			m["file"].Unmarshal(f)

			*changes = append(*changes, change{
				name:   f.FullPath,
				action: e,
			})
		})
	}

	changes1 := make([]change, 0)
	onChange1 := onChangeFunc(&changes1)

	_, err := remote.Tell("readDirectory", struct {
		Path     string
		OnChange dnode.Function
	}{
		Path:     testDir,
		OnChange: onChange1,
	})
	if err != nil {
		t.Fatal(err)
	}

	changes2 := make([]change, 0)
	onChange2 := onChangeFunc(&changes2)

	_, err = remote2.Tell("readDirectory", struct {
		Path     string
		OnChange dnode.Function
	}{
		Path:     testDir,
		OnChange: onChange2,
	})
	if err != nil {
		t.Fatal(err)
	}

	addFile := "testdata/example3.txt"
	newFile := "testdata/example4.txt"

	t.Logf("Creating file %s", addFile)
	time.Sleep(time.Millisecond * 100)
	ioutil.WriteFile(addFile, []byte("example"), 0755)

	t.Logf("Renaming file from %s to %s", addFile, newFile)
	time.Sleep(time.Millisecond * 100)
	err = os.Rename(addFile, newFile)
	if err != nil {
		t.Error(err)
	}

	t.Logf("Removing file %s", newFile)
	time.Sleep(time.Millisecond * 100)
	err = os.Remove(newFile)
	if err != nil {
		t.Error(err)
	}

	time.Sleep(time.Millisecond * 100)

	var expected = map[string]bool{
		"added_testdata/example3.txt":   true,
		"added_testdata/example4.txt":   true,
		"removed_testdata/example3.txt": true,
		"removed_testdata/example4.txt": true,
	}

	t.Logf("changes1 %+v", changes1)
	t.Logf("changes2 %+v", changes2)

	testChanges := func(changes []change) error {
		for _, change := range changes {
			_, ok := expected[change.action+"_"+change.name]
			if !ok {
				fmt.Errorf("%s_%s does not exist", change.action, change.name)
			}
		}

		return nil
	}

	if err := testChanges(changes1); err != nil {
		t.Errorf("watcher for remote: %s", err)
	}

	if err := testChanges(changes2); err != nil {
		t.Errorf("watcher for remote2: %s", err)
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
	file, err := ioutil.TempFile("", "")
	if err != nil {
		t.Error(err)
	}

	_, err = file.Write([]byte("kite"))
	if err != nil {
		t.Fatal(err)
	}

	readFile := func(offset, blockSize int64) string {
		resp, err := remote.Tell("readFile", struct {
			Path      string
			Offset    int64
			BlockSize int64
		}{
			Path:      testfile1,
			Offset:    offset,
			BlockSize: blockSize,
		})
		if err != nil {
			t.Fatal(err)
		}

		buf := resp.MustMap()["content"].MustString()

		s, err := base64.StdEncoding.DecodeString(buf)
		if err != nil {
			t.Fatal(err)
		}

		return string(s)
	}

	s := readFile(0, 0)
	if string(s) != "kite\n" {
		t.Errorf("got %s, expecting %s", string(s), "kite")
	}

	s = readFile(0, 1)
	if string(s) != "k" {
		t.Errorf("got %s, expecting %s", string(s), "k")
	}

	s = readFile(0, 4)
	if string(s) != "kite" {
		t.Errorf("got %s, expecting %s", string(s), "kite")
	}

	s = readFile(0, 5)
	if string(s) != "kite\n" {
		t.Errorf("got %s, expecting %s", string(s), "kite\n")
	}

	s = readFile(0, 100)
	if string(s) != "kite\n" {
		t.Errorf("got %s, expecting %s", string(s), "kite\n")
	}

	s = readFile(1, 0)
	if string(s) != "ite\n" {
		t.Errorf("got %s, expecting %s", string(s), "ite\n")
	}

	s = readFile(1, 2)
	if string(s) != "it" {
		t.Errorf("got %s, expecting %s", string(s), "it")
	}

	s = readFile(1, 3)
	if string(s) != "ite" {
		t.Errorf("got %s, expecting %s", string(s), "ite")
	}

	s = readFile(1, 4)
	if string(s) != "ite\n" {
		t.Errorf("got %s, expecting %s", string(s), "ite\n")
	}

	s = readFile(1, 100)
	if string(s) != "ite\n" {
		t.Errorf("got %s, expecting %s", string(s), "ite\n")
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

	// Write foo, which has a hash of: acbd18db4cc2f85cedef654fccc4a4d8
	expectedHash := "acbd18db4cc2f85cedef654fccc4a4d8"
	err = ioutil.WriteFile(testFile.Name(), []byte("foo"), 0666)
	if err != nil {
		t.Fatal("Failed to write test file contents")
	}

	t.Log("writeFile try to write with an invalid expectedHash")
	_, err = remote.Tell("writeFile", struct {
		Path            string
		Content         []byte
		LastContentHash string
	}{
		Path:            testFile.Name(),
		Content:         []byte("bar"),
		LastContentHash: "fakehash",
	})

	if err == nil {
		t.Errorf(
			"writeFile accepted a hash of %q for contents %q, where %q should have been required.",
			"fakehash",
			"foo",
			expectedHash,
		)
	}

	t.Log("writeFile try to write with a correct expectedHash")
	_, err = remote.Tell("writeFile", struct {
		Path            string
		Content         []byte
		LastContentHash string
	}{
		Path:            testFile.Name(),
		Content:         []byte("bar"),
		LastContentHash: expectedHash,
	})

	if err != nil {
		t.Errorf(
			"writeFile was given the correct hash of %q but still returned error: %s",
			expectedHash,
			err.Error(),
		)
	}

	buf, err = ioutil.ReadFile(testFile.Name())
	if err != nil {
		t.Fatal(err)
	}

	expectedContents := []byte("bar")
	if !reflect.DeepEqual(buf, expectedContents) {
		t.Errorf(
			"content is wrong. got '%s' expected '%s'",
			string(buf), string(expectedContents),
		)
	}

	t.Log("writeFile try to append with a correct expectedHash")
	// bar is the current content, hash: 37b51d194a7513e45b56f6524f2d51f2
	expectedHash = "37b51d194a7513e45b56f6524f2d51f2"

	_, err = remote.Tell("writeFile", struct {
		Path            string
		Content         []byte
		Append          bool
		LastContentHash string
	}{
		Path:            testFile.Name(),
		Content:         []byte("baz"),
		Append:          true,
		LastContentHash: expectedHash,
	})

	if err != nil {
		t.Errorf(
			"writeFile was given the correct hash of %q but still returned error: %s",
			expectedHash,
			err.Error(),
		)
	}

	buf, err = ioutil.ReadFile(testFile.Name())
	if err != nil {
		t.Fatal(err)
	}

	expectedContents = []byte("barbaz")
	if !reflect.DeepEqual(buf, expectedContents) {
		t.Errorf(
			"content is wrong. got '%s' expected '%s'",
			string(buf), string(expectedContents),
		)
	}

	// Write some test data
	err = ioutil.WriteFile(testFile.Name(), []byte("foobaz"), 0644)
	if err != nil {
		t.Fatal(err)
	}

	_, err = remote.Tell("writeFile", struct {
		Path    string
		Content []byte
		Offset  int64
	}{
		Path:    testFile.Name(),
		Content: []byte("bar"),
		Offset:  3,
	})

	if err != nil {
		t.Errorf(
			"writeFile returned an error with an offset. %s",
			err.Error(),
		)
	}

	buf, err = ioutil.ReadFile(testFile.Name())
	if err != nil {
		t.Fatal(err)
	}

	if string(buf) != "foobar" {
		t.Errorf(
			"writeFile was given an offset, but did not offset the data correctly. wanted:%s, got:%s",
			"foobar",
			string(buf),
		)
	}
}

func TestUniquePath(t *testing.T) {
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
			Path: testfile1,
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
	resp, err := remote.Tell("getInfo", struct {
		Path string
	}{
		Path: testfile1,
	})
	if err != nil {
		t.Fatal(err)
	}

	f := &FileEntry{}
	err = resp.Unmarshal(f)
	if err != nil {
		t.Fatal(err)
	}

	if f.Name != filepath.Base(testfile1) {
		t.Errorf("got %s expecting %s", f.Name, testfile1)
	}

	if !f.Exists {
		t.Errorf("file %s should exists", testfile1)
	}
}

func TestPermissions(t *testing.T) {
	t.Skip("fails in container runtime")

	var files = map[string]struct {
		mode               int
		readable, writable bool
	}{
		"permissions.txt":  {0100, false, false}, // no read and write
		"permissions2.txt": {0400, true, false},  // only read
		"permissions3.txt": {0600, true, true},   // read and write
	}

	for name, file := range files {
		os.Create("testdata/" + name) // if it exists continue
		os.Chmod("testdata/"+name, os.FileMode(file.mode))
	}

	respFiles := make([]*FileEntry, 0)
	for name := range files {
		resp, err := remote.Tell("getInfo", struct {
			Path string
		}{
			Path: "testdata/" + name,
		})
		if err != nil {
			t.Fatal(err)
		}

		f := &FileEntry{}
		err = resp.Unmarshal(f)
		if err != nil {
			t.Fatal(err)
		}

		if strings.HasPrefix(f.Name, "perm") {
			respFiles = append(respFiles, f)
		}
	}

	for _, file := range respFiles {
		f := files[file.Name]

		if f.readable != file.Readable {
			t.Errorf("File %s should have readable flag: %+v but got: %+v", file.Name, file.Readable, f.readable)
		}

		if f.writable != file.Writable {
			t.Errorf("File %s should have writable flag: %+v but got: %+v", file.Name, file.Writable, f.writable)
		}
	}

	// hosts file is owned by root but is readable for all users
	testFile := "/etc/hosts"

	resp, err := remote.Tell("getInfo", struct {
		Path string
	}{
		Path: testFile,
	})
	if err != nil {
		t.Fatal(err)
	}

	h := &FileEntry{}
	err = resp.Unmarshal(h)
	if err != nil {
		t.Fatal(err)
	}

	if !h.Readable {
		t.Error("/etc/hosts file is readable for all users, however GetInfo returns false")
	}
}

func TestSetPermissions(t *testing.T) {
	testPerm := 0755
	resp, err := remote.Tell("setPermissions", struct {
		Path      string
		Mode      os.FileMode
		Recursive bool
	}{
		Path: testfile1,
		Mode: os.FileMode(testPerm),
	})
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("setPermissions should return true")
	}

	f, err := os.Open(testfile1)
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

	testNewPath := filepath.Join(filepath.Dir(testFile.Name()), "kite.txt")
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
	testFile, err := filepath.Abs(testfile1)
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

func TestGetDiskInfo(t *testing.T) {
	resp, err := remote.Tell("getDiskInfo", struct {
		Path string
	}{
		Path: "/",
	})
	if err != nil {
		t.Error(err)
	}

	stfs := syscall.Statfs_t{}
	if err := syscall.Statfs("/", &stfs); err != nil {
		t.Fatal(err)
	}

	var di *DiskInfo
	if err = resp.Unmarshal(&di); err != nil {
		t.Fatal(err)
	}

	if di.BlockSize != uint32(stfs.Bsize) {
		t.Errorf("got %+v, expected %+v", stfs.Bsize, di.BlockSize)
	}

	if di.BlocksTotal != stfs.Blocks {
		t.Errorf("got %+v, expected %+v", stfs.Blocks, di.BlocksTotal)
	}

	if di.BlocksFree == 0 {
		t.Errorf("expected non 0 value")
	}

	if di.BlocksUsed == 0 {
		t.Errorf("expected non 0 value")
	}

	if di.BlocksUsed != (di.BlocksTotal - di.BlocksFree) {
		t.Errorf("blocksUsed != blocksTotal-blocksFree")
	}
}
