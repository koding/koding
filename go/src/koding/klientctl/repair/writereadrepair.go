package repair

import (
	"errors"
	"fmt"
	"io/ioutil"
	"koding/klient/command"
	"koding/klient/remote/req"
	"koding/klientctl/util"
	"os"
	"path/filepath"

	"github.com/koding/logging"
)

const (
	tmpDirPrefix    = ".kd.repairtest"
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
		RemoteExec(string, string) (command.Output, error)
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
	tmpDir, err := ioutil.TempDir(mountPath, tmpDirPrefix)
	if err != nil {
		r.Log.Warning("Failed to create directory. Status is not-okay. err:%s", err)
		return false, nil
	}

	// Because of the nature of Status, removing the testdir may fail, but that is okay.
	defer os.RemoveAll(tmpDir)

	testFile := filepath.Join(tmpDir, testFileName)
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
			"Unexpected local file contents. Status is not-okay. wanted:%s, got:%s",
			testFileContent, s,
		)
		return false, nil
	}

	// We have to get the testDirName, because our testDir is the full path - created
	// by ioutil.
	_, tmpDirName := filepath.Split(tmpDir)
	remoteFile := filepath.Join(info.RemotePath, tmpDirName, testFileName)
	output, err := r.Klient.RemoteExec(r.MountName, fmt.Sprintf("cat %s", remoteFile))

	// If there is an error from exec, we couldn't successfully make the kite request.
	// Cat failing will not return an error.
	if err != nil {
		return false, err
	}

	// if cat exits with non-zero, we were unable to get the file contents. Likely
	// doesn't exist.
	if output.ExitStatus != 0 {
		r.Log.Warning(
			"The contents of the remote file %q could not be read. Status not-okay. exitStatus:%d",
			remoteFile, output.ExitStatus,
		)
		return false, nil
	}

	// If the content does not match on remote, we're not okay.
	if output.Stdout != testFileContent {
		r.Log.Warning(
			"Remote file contents did not match. Status not-okay. wanted:%s, got:%s",
			testFileContent, output.Stdout,
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
