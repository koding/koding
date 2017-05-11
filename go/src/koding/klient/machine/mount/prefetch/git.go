package prefetch

import (
	"bytes"
	"errors"
	"fmt"
	"os/exec"

	"koding/klient/machine/index"
	"koding/klient/machine/index/node"
)

// Git prefetcher uses git to reduce the amount of prefetched data. The strategy
// it uses is:
//
//  - download contnt of .git directory from remote.
//  - run `git reset --hard`
//  - any upstaged changes on remote will be detected and synced later by mount
//    synchronization mechanisms.
//
type Git struct{}

// Available checks if git executable binary is available in user PATH.
func (Git) Available() bool {
	_, err := exec.LookPath("git")
	return err == nil
}

// Weight returns Git prefetcher weight.
func (Git) Weight() int { return 100 }

// Scan gets size and number of prefetched files.
func (Git) Scan(idx *index.Index) (string, int64, int64, error) {
	var isGit bool
	idx.Tree().DoPath(".git", func(_ node.Guard, n *node.Node) bool {
		isGit = !n.IsShadowed() && n.Entry.File.Mode.IsDir()

		return !n.IsShadowed()
	})

	if !isGit {
		return "", 0, 0, errors.New("remote directory is not a git repository")
	}

	count, diskSize := 0, int64(0)
	idx.Tree().DoPath(".git", node.Count(&count))
	idx.Tree().DoPath(".git", node.DiskSize(&diskSize))

	return ".git/", int64(count), diskSize, nil
}

// PostRun runs git executable in order to restore downloaded state in working
// directory.
func (Git) PostRun(wd string) error {
	var (
		buf bytes.Buffer
		cmd = exec.Command("git", "reset", "--hard")
	)

	cmd.Dir, cmd.Stderr = wd, &buf
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("git command exited with error: %v (%q)", err, buf.String())
	}

	return nil
}
