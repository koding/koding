package fusetest

import (
	"fmt"
	"github.com/hashicorp/go-multierror"
	"io/ioutil"
	"koding/klient/remote/req"
	"os"
	"path/filepath"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

// Fusetest runs common file & dir operations on already mounted folder
// then checks if local mount and remote VM are synchronized using ssh.
type Fusetest struct {
	Machine  string
	MountDir string
	TestDir  string
	Opts     req.MountFolder

	T *testing.T

	*Remote
}

func NewFusetest(machine string, opts req.MountFolder) (*Fusetest, error) {
	r, err := NewRemote(machine)
	if err != nil {
		return nil, err
	}

	return &Fusetest{
		Machine:  machine,
		MountDir: r.local,
		T:        &testing.T{},
		Remote:   r,
		Opts:     opts,
	}, nil
}

func (f *Fusetest) checkCachePath() bool {
	return f.Opts.CachePath != "" && f.Opts.PrefetchAll
}

func (f *Fusetest) RunAllTests() (testErrs error) {
	fmt.Println("Testing pre-existing mount...")
	if err := f.RunOperationTests(); err != nil {
		testErrs = multierror.Append(testErrs, err)
	}

	// Unmount so we can mount with various settings below.
	if err := NewKD().Unmount(f.Machine); err != nil {
		testErrs = multierror.Append(testErrs, err)
	}

	// Run our various test types
	if err := f.RunPrefetchTests(); err != nil {
		testErrs = multierror.Append(testErrs, err)
	}

	if err := f.RunNoPrefetchTests(); err != nil {
		testErrs = multierror.Append(testErrs, err)
	}

	if err := f.RunPrefetchAllTests(); err != nil {
		testErrs = multierror.Append(testErrs, err)
	}

	// Remount test folder.
	//
	// TODO: Perhaps store the current mount settings, so we can mount after we're
	// done with the same settings?
	err := NewKD().MountWithPrefetchAll(f.Machine, f.Remote.remote, f.MountDir)
	if err != nil {
		testErrs = multierror.Append(testErrs, err)
	}

	return testErrs
}

func (f *Fusetest) RunPrefetchTests() error {
	fmt.Println("Mounting with Prefetch...")

	// TODO: Add the fusetest dir to Fusetest.RemoteDir. I haven't yet, because
	// i want to make it the full abs path, rather than just a local path as seen here.
	err := NewKD().Mount(f.Machine, f.Remote.remote, f.MountDir)
	if err != nil {
		return err
	}

	if err := f.RunOperationTests(); err != nil {
		return err
	}

	// Pausing, because the instant remount is giving me resource is busy every
	// time.
	time.Sleep(5 * time.Second)

	return NewKD().Unmount(f.Machine)
}

func (f *Fusetest) RunNoPrefetchTests() error {
	fmt.Println("Mounting with NoPrefetch...")

	// TODO: Add the fusetest dir to Fusetest.RemoteDir. I haven't yet, because
	// i want to make it the full abs path, rather than just a local path as seen here.
	err := NewKD().Mount(f.Machine, f.Remote.remote, f.MountDir)
	if err != nil {
		return err
	}

	if err := f.RunOperationTests(); err != nil {
		return err
	}

	// Pausing, because the instant remount is giving me resource is busy every
	// time.
	time.Sleep(5 * time.Second)

	return NewKD().Unmount(f.Machine)
}

func (f *Fusetest) RunPrefetchAllTests() error {
	fmt.Println("Mounting with PrefetchAll...")

	// TODO: Add the fusetest dir to Fusetest.RemoteDir. I haven't yet, because
	// i want to make it the full abs path, rather than just a local path as seen here.
	err := NewKD().MountWithPrefetchAll(f.Machine, f.Remote.remote, f.MountDir)
	if err != nil {
		return err
	}

	if err := f.RunOperationTests(); err != nil {
		return err
	}

	// Pausing, because the instant remount is giving me resource is busy every
	// time.
	time.Sleep(5 * time.Second)

	return NewKD().Unmount(f.Machine)
}

func (f *Fusetest) RunOperationTests() error {
	testDir, err := ioutil.TempDir(f.MountDir, "tests")
	if err != nil {
		return err
	}
	f.TestDir = testDir

	// dir ops
	f.TestMkDir()
	f.TestReadDir()
	f.TestRmDir()

	// file ops
	f.TestCreateFile()
	f.TestReadFile()
	f.TestWriteFile()

	// common ops
	f.TestRename()
	f.TestCpOutToIn()

	return os.RemoveAll(f.TestDir)
}

func (f *Fusetest) setupConvey(name string, fn func(string)) {
	Convey(name, f.T, createDir(f.TestDir, name, func(dirPath string) {
		m := filepath.Base(f.MountDir)
		d := filepath.Base(dirPath)

		fn(filepath.Join(m, d))
	}))
}

func (f *Fusetest) checkCacheEntry(name string) (os.FileInfo, error) {
	fi, err := statDirCheck(filepath.Join(f.Opts.CachePath, name))
	if err != nil {
		return nil, err
	}

	if fi.Name() != name {
		return nil, fmt.Errorf("Expected %s, got %s", name, fi.Name())
	}

	return fi, nil
}

func (f *Fusetest) CheckLocalEntryNotExists(dirName string) error {
	check := func(dirPath string) error {
		if _, err := os.Stat(dirPath); err == nil {
			return fmt.Errorf("Expected dir to not exist.")
		}

		return nil
	}

	if f.checkCachePath() {
		return check(f.fullCachePath(dirName))
	}

	return check(f.fullMountPath(dirName))
}

func (f *Fusetest) CheckDirContents(dirName string, names []string) error {
	check := func(dirPath string) error {
		localEntries, err := ioutil.ReadDir(dirPath)
		if err != nil {
			return err
		}

		if len(localEntries) != len(names) {
			return fmt.Errorf("Expected dir length to be %d entries, got %d", len(names), len(localEntries))
		}

		// lexical ordering should ensure dir1 will always return before file1
		if localEntries[0].Name() != names[0] {
			return fmt.Errorf("Expected entry to be %s, got %s", names[0], localEntries[0].Name())
		}

		if localEntries[1].Name() != names[1] {
			return fmt.Errorf("Expected entry to be %s, got %s", names[1], localEntries[1].Name())
		}

		return nil
	}

	if f.checkCachePath() {
		if err := check(f.fullCachePath(dirName)); err != nil {
			return err
		}
	}

	return check(f.fullMountPath(dirName))
}

func (f *Fusetest) CheckLocalEntry(dirName string) error {
	check := func(dirPath string) error {
		fi, err := statDirCheck(dirPath)
		if err != nil {
			return err
		}

		name := filepath.Base(dirPath)
		if fi.Name() != name {
			return fmt.Errorf("Expected %s, got %s", name, fi.Name())
		}

		return nil
	}

	if f.checkCachePath() {
		if err := check(f.fullCachePath(dirName)); err != nil {
			return err
		}
	}

	return check(f.fullMountPath(dirName))
}

func (f *Fusetest) CheckLocalIsFile(fileName string, perms os.FileMode) error {
	if f.checkCachePath() {
		if _, err := statFileCheck(f.fullCachePath(fileName), perms); err != nil {
			return err
		}
	}

	_, err := statFileCheck(f.fullMountPath(fileName), perms)
	return err
}

func (f *Fusetest) CheckLocalEntryIsDir(dirName string, perms os.FileMode) error {
	if f.checkCachePath() {
		if _, err := statDirCheck(f.fullCachePath(dirName)); err != nil {
			return err
		}
	}

	_, err := statDirCheck(f.fullMountPath(dirName))
	return err
}

func (f *Fusetest) CheckLocalFileContents(file, contents string) error {
	if f.checkCachePath() {
		if err := readFile(f.fullCachePath(file), contents); err != nil {
			return err
		}
	}

	return readFile(f.fullMountPath(file), contents)
}

func (f *Fusetest) fullCachePath(entry string) string {
	return filepath.Join(f.Opts.CachePath, entry)
}

func (f *Fusetest) fullMountPath(entry string) string {
	// TODO: this is hack, added by trial and error; fix root cause
	p := filepath.Dir(f.MountDir)
	return filepath.Join(p, entry)
}

func (f *Fusetest) fullRemotePath(entry string) string {
	return filepath.Join(f.Remote.local, entry)
}
