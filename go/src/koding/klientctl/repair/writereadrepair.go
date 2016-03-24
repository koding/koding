package repair

import (
	"errors"
	"io/ioutil"
	"koding/klient/remote/req"
	"koding/klientctl/util"
	"os"
	"path/filepath"

	"github.com/koding/logging"
)

const (
	testDirName     = ".kd.repairtest"
	testFileName    = "write-test"
	testFileContent = "content"
)

// WriteReadRepair writes to a temporary file within the given directory, and if
// anything goes wrong in the process, calls for klient to remount.
type WriteReadRepair struct {
	Log logging.Logger

	Stdout *util.Fprint

	MountName string

	// The klient we will be communicating with.
	Klient interface {
		RemoteMountInfo(string) (req.MountInfoResponse, error)
		RemoteRemount(string) error
	}
}

func (r *WriteReadRepair) String() string {
	return "WriteReadRepair"
}

func (r *WriteReadRepair) Status() (bool, error) {
	info, err := r.Klient.RemoteMountInfo(r.MountName)
	// If we can't even get info from klient, we can't assert status.
	if err != nil {
		return false, err
	}

	mountPath := info.LocalPath
	testDir, err := ioutil.TempDir(mountPath, ".kd.repairtest")
	if err != nil {
		r.Log.Warning("Failed to create directory. Status is not-okay. err:%s", err)
		return false, nil
	}

	// Because of the nature of Status, removing the testdir may fail, but that is okay.
	defer os.RemoveAll(testDir)

	testFile := filepath.Join(testDir, testFileName)
	if err := ioutil.WriteFile(testFile, []byte(testFileContent), 0644); err != nil {
		r.Log.Warning(
			"Failed to create and write file. Status is not-okay. err:%s", err,
		)
		return false, nil
	}

	b, err := ioutil.ReadFile(testFile)
	if err != nil {
		r.Log.Warning("Failed to read file. Status is not-okay. err:%s", err)
		return false, nil
	}

	s := string(b)
	if s != testFileContent {
		r.Log.Warning(
			"Unexpected file contents. Status is not-okay. wanted:%s, got:%s",
			testFileContent, s,
		)
		return false, nil
	}

	return true, nil
}

func (r *WriteReadRepair) Repair() error {
	r.Stdout.Printlnf("Mount is unable to Read or Write, remounting...")

	if err := r.Klient.RemoteRemount(r.MountName); err != nil {
		r.Stdout.Printlnf("Unable to remount %s", r.MountName)
		return err
	}

	if ok, err := r.Status(); !ok || err != nil {
		r.Stdout.Printlnf("Unable to repair mount issue.")
		if err == nil {
			err = errors.New("Status returned not-okay after Repair")
		}
		return err
	}

	r.Stdout.Printlnf("Read and Write now succeeds.")

	return nil
}
