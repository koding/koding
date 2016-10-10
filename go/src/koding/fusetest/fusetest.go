package fusetest

import (
	"fmt"
	"io/ioutil"
	"koding/fusetest/internet"
	"os"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	"github.com/hashicorp/go-multierror"

	. "github.com/smartystreets/goconvey/convey"
)

var (
	// A series of timings to use for reconnect testing. Each larger disconnect
	// test is run one after another, so a depth test of 2 will run 0, and 1, and 2.
	ReconnectDepths = map[uint]internet.ReconnectOpts{
		// No reconnect testing. (default)
		0: {},

		// Disabled currently.
		// A momentary disconnect, nothing should really lose connection and/or fail.
		1: {
			PauseAfterDisconnect: 30 * time.Second,
			PauseAfterConnect:    10 * time.Second,
		},

		// A full disconnect, long enough for kite to fully lose connection. Longer time
		// to reconnect as well (due to backoffs/etc).
		2: {
			PauseAfterDisconnect: 8 * time.Minute,
			PauseAfterConnect:    2 * time.Minute,
		},
	}
)

// Fusetest runs common file & dir operations on already mounted folder
// then checks if local mount and remote VM are synchronized using ssh.
type Fusetest struct {
	Machine string

	// The path of the local mount directory on the users system.
	MountDir string

	// The temporary directory within the Mount directory, where test operations
	// are run.
	TestDir string

	Opts FusetestOpts

	OriginalMountOpts MountInfo

	T *testing.T

	*Remote
}

type FusetestOpts struct {
	// TODO: Deprecate this field, in favor of passing the settings into tests.
	// Currently the tests are stateful and this var changes a lot, depending on the
	// tests. Rather brittle.
	MountInfo

	// The main fuse operation tests. If false, no fuseop tests will be run.
	// (useful if you just want to check klient list recovery, etc.)
	FuseOpsTests bool

	// The depth (if any) to run reconnect tests
	ReconnectDepth uint

	// Whether or not to run the op tests on various mount settings.
	MountSettingTests bool

	// General kd tests, outside of mount/unmount. Ie, kd list, kd ssh, etc.
	MiscTests bool

	// General kd tests that require sudo.
	MiscSudoTests bool
}

func NewFusetest(machine string, opts FusetestOpts) (*Fusetest, error) {
	r, err := NewRemote(machine)
	if err != nil {
		return nil, err
	}

	f := &Fusetest{
		Machine:  machine,
		MountDir: r.local,
		T:        &testing.T{},
		Remote:   r,
		Opts:     opts,
	}

	origMountOpts, err := NewKD().GetMountOptions(f.Machine)
	if err != nil {
		fmt.Println("Unable to get your mount settings.")
		return nil, err
	}
	f.OriginalMountOpts = origMountOpts
	f.Opts.MountInfo = origMountOpts

	return f, nil
}

func (f *Fusetest) checkCachePath() bool {
	return f.Opts.CachePath != "" && f.Opts.PrefetchAll
}

func (f *Fusetest) RunTests() (testErrs error) {
	fmt.Println("Testing pre-existing mount...")
	if err := f.RunOperationTests(); err != nil {
		testErrs = multierror.Append(testErrs, err)
	}

	// Run the --reconnect-depth tests on the original mount.
	if err := f.RunReconnectDepths(); err != nil {
		testErrs = multierror.Append(testErrs, err)
	}

	// If any of below test are true, we need to unmount the users mount so that
	// tests can unmount and remount as they need. We'll remount at the
	// end of this func.
	remountUserMount := f.Opts.MountSettingTests || f.Opts.MiscTests || f.Opts.MiscSudoTests
	if remountUserMount {
		if err := NewKD().Unmount(f.Machine); err != nil {
			testErrs = multierror.Append(testErrs, err)
		}
	}

	// Run our --mount-settings tests
	if f.Opts.MountSettingTests {
		if err := f.RunMountSettingTests(); err != nil {
			testErrs = multierror.Append(testErrs, err)
		}
	}

	// Run our --misc tests
	if f.Opts.MiscTests {
		if err := f.RunMiscTests(); err != nil {
			testErrs = multierror.Append(testErrs, err)
		}
	}

	// Run our --misc-sudo
	if f.Opts.MiscSudoTests {
		if err := f.RunMiscSudoTests(); err != nil {
			testErrs = multierror.Append(testErrs, err)
		}
	}

	// If we unmounted the users mount, restore it.
	if remountUserMount {
		// Remount test folder.
		if err := NewKD().MountWithOpts(f.Machine, f.OriginalMountOpts); err != nil {
			testErrs = multierror.Append(testErrs, err)
		}
	}

	return testErrs
}

// Run our --mount-settings tests
func (f *Fusetest) RunMountSettingTests() (testErrs error) {
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

	if err := f.RunOneWaySyncMountTests(); err != nil {
		testErrs = multierror.Append(testErrs, err)
	}

	return testErrs
}

// Run our --misc-sudo tests
func (f *Fusetest) RunMiscSudoTests() error {
	f.TestKDRemount()
	return nil
}

// Run our --misctests
func (f *Fusetest) RunMiscTests() error {
	f.TestKDListMachineStatus()
	return nil
}

func (f *Fusetest) RunPrefetchTests() error {
	fmt.Println("Mounting with Prefetch...")

	// TODO: Add the fusetest dir to Fusetest.RemoteDir. I haven't yet, because
	// i want to make it the full abs path, rather than just a local path as seen here.
	err := NewKD().Mount(f.Machine, f.Remote.remote, f.MountDir)
	if err != nil {
		return err
	}

	// Update our local opts to match our new mount.
	opts, err := NewKD().GetMountOptions(f.Machine)
	if err != nil {
		return err
	}
	f.Opts.MountInfo = opts

	// Run normal ops tests first
	if err := f.RunOperationTests(); err != nil {
		return err
	}

	// Run reconnect depths for reconnect testing on this mount. It will only run
	// if enabled.
	if err := f.RunReconnectDepths(); err != nil {
		return err
	}

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

	// Update our local opts to match our new mount.
	opts, err := NewKD().GetMountOptions(f.Machine)
	if err != nil {
		return err
	}
	f.Opts.MountInfo = opts

	// Run normal ops tests first
	if err := f.RunOperationTests(); err != nil {
		return err
	}

	// Run reconnect depths for reconnect testing on this mount. It will only run
	// if enabled.
	if err := f.RunReconnectDepths(); err != nil {
		return err
	}

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

	// Update our local opts to match our new mount.
	opts, err := NewKD().GetMountOptions(f.Machine)
	if err != nil {
		return err
	}
	f.Opts.MountInfo = opts

	// Run normal ops tests first
	if err := f.RunOperationTests(); err != nil {
		return err
	}

	// Run reconnect depths for reconnect testing on this mount. It will only run
	// if enabled.
	if err := f.RunReconnectDepths(); err != nil {
		return err
	}

	return NewKD().Unmount(f.Machine)
}

func (f *Fusetest) RunOneWaySyncMountTests() error {
	fmt.Println("Mounting with OneWaySync...")

	// TODO: Add the fusetest dir to Fusetest.RemoteDir. I haven't yet, because
	// i want to make it the full abs path, rather than just a local path as seen here.
	err := NewKD().MountWithOneWaySync(f.Machine, f.Remote.remote, f.MountDir)
	if err != nil {
		return err
	}

	// Update our local opts to match our new mount.
	opts, err := NewKD().GetMountOptions(f.Machine)
	if err != nil {
		return err
	}
	f.Opts.MountInfo = opts

	// Run normal ops tests first
	if err := f.RunOperationTests(); err != nil {
		return err
	}

	// Run reconnect depths for reconnect testing on this mount. It will only run
	// if enabled.
	if err := f.RunReconnectDepths(); err != nil {
		return err
	}

	return NewKD().Unmount(f.Machine)
}

func (f *Fusetest) RunReconnectDepths() error {
	// Do not run reconnect depths if reconnect depths are not enabled.
	if f.Opts.ReconnectDepth < 0 {
		return nil
	}

	if runtime.GOOS != "darwin" {
		fmt.Println("Testing internet is disabled for non-darwin currently.")
		return nil
	}

	// Start at the first depth of reconnect testing. 0 is no reconnect, so there's
	// no need in running that.
	var i uint
	for i = 1; i <= f.Opts.ReconnectDepth; i++ {
		reconnectOpts, _ := ReconnectDepths[i]

		if err := f.RunReconnectTests(reconnectOpts); err != nil {
			return err
		}
	}

	return nil
}

// TODO: Add the ability for the Op tests to return errors, so that we can
// programmatically expect them to fail. Ensuring that ops during disconnect
// fail as expected.
func (f *Fusetest) RunReconnectTests(reconnectOpts internet.ReconnectOpts) error {
	if runtime.GOOS != "darwin" {
		fmt.Println("Testing internet is disabled for non-darwin currently.")
		return nil
	}

	fmt.Printf("Testing reconnect, pausing for %s.\n", reconnectOpts.TotalDur())
	if err := internet.ToggleInternet(reconnectOpts); err != nil {
		return err
	}

	return f.RunOperationTests()
}

// Run operation tests based on whatever the mount is - Fuse or OneWay
func (f *Fusetest) RunOperationTests() error {
	if !f.Opts.FuseOpsTests {
		return nil
	}

	if f.Opts.MountInfo.OneWaySyncMount {
		return f.RunOneWayOperationTests()
	}

	return f.RunFuseOperationTests()
}

func (f *Fusetest) RunOneWayOperationTests() error {
	testDir, err := ioutil.TempDir(f.MountDir, "tests")
	if err != nil {
		return err
	}
	f.TestDir = testDir
	defer os.RemoveAll(f.TestDir)

	f.TestSyncInterval()

	return nil
}

func (f *Fusetest) RunFuseOperationTests() error {
	testDir, err := ioutil.TempDir(f.MountDir, "tests")
	if err != nil {
		return err
	}
	f.TestDir = testDir
	defer os.RemoveAll(f.TestDir)

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

	return nil
}

func (f *Fusetest) setupConvey(name string, fn func(string)) {
	Convey(name, f.T, createDir(f.TestDir, name, func(dirPath string) {
		m := filepath.Base(f.TestDir)
		d := filepath.Base(dirPath)

		fn(filepath.Join(m, d))
	}))
}

func (f *Fusetest) setupConveyWithoutDir(name string, fn func()) {
	Convey(name, f.T, fn)
}

func (f *Fusetest) checkCacheEntry(name string) (os.FileInfo, error) {
	fi, err := statDirCheck(f.fullCachePath(name))
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
	p := filepath.Dir(f.TestDir)
	return filepath.Join(p, entry)
}

func (f *Fusetest) fullRemotePath(entry string) string {
	return filepath.Join(f.Remote.local, entry)
}
