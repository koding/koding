package mount_test

import (
	"fmt"
	"io/ioutil"
	"os"
	"testing"
	"time"

	"koding/klient/machine/index"
	"koding/klient/machine/mount"
)

func TestIdxUpdateFlush(t *testing.T) {
	path, err := createTmpFile()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.Remove(path)

	var (
		idx = index.NewIndex()
		iu  = mount.NewIdxUpdate(path, idx, 100*time.Millisecond, nil)
		c   = index.NewChange("not/important", index.PriorityHigh, index.ChangeMetaAdd)
	)
	defer iu.Close()

	iu.Update(os.TempDir(), c)
	if err := waitForZeroChanges(iu, 2*time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
}

func createTmpFile() (string, error) {
	f, err := ioutil.TempFile("", "sync.update.index")
	if err != nil {
		return "", err
	}
	if err := f.Close(); err != nil {
		return "", err
	}

	return f.Name(), nil
}

func waitForZeroChanges(iu *mount.IdxUpdate, timeout time.Duration) error {
	var (
		ticker   = time.NewTicker(5 * time.Millisecond)
		timeoutC = time.After(timeout)
	)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			if cN := iu.ChangeN(); cN == 0 {
				return nil
			}
		case <-timeoutC:
			return fmt.Errorf("timed out after %s", timeout)
		}
	}
}
