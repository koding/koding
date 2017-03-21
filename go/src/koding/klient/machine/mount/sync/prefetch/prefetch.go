package prefetch

import (
	"errors"
	"fmt"
	"os/exec"

	"bytes"
	"koding/klient/machine/index"
)

var DefaultStrategy = Strategy{
	"git": Git{},
	"all": All{},
}

type Strategy map[string]Prefetcher

func (s Strategy) Available() (available []string) {
	for name, pref := range s {
		if pref.Available() {
			available = append(available, name)
		}
	}

	return available
}

func (s Strategy) Select(available []string, idx index.Index) Prefetch {
	return Prefetch{}
}

type Prefetch struct{}

// Prefetcher defines a set of methods that are needed to safely prefetch
// remote files.
type Prefetcher interface {
	// Available checks if it's possible to apply provided prefetcher since
	// some of them may need external commands which may not be present on host.
	Available() bool

	// Weight returns prefetch weight. More desired prefetchers should have
	// higher value of the weight.
	Weight() int

	// Scan scans provided index checking if provided prefetched can be applied.
	// If, yes path suffix, file count and size will be returned. This function
	// returns non-nil error when prefetch can be applied on provided index.
	Scan(idx *index.Index) (suffix string, count, diskSize int64, err error)

	// PostRun should be called after prefetching in order to ensure that it
	// succeeded or/and make additional file operations.
	PostRun(wd string) error
}

// All prefetcher always downloads all files stored in index.
type All struct{}

// Available always returns true since All prefetcher doesn't need any
// additional third-party tools.
func (All) Available() bool { return true }

// Weight returns All prefetcher weight.
func (All) Weight() int { return 0 }

// Scan gets size and number of prefetched files.
func (All) Scan(idx *index.Index) (suffix string, count, diskSize int64, err error) {
	count, diskSize = int64(idx.CountAll(-1)), idx.DiskSizeAll(-1)
	return
}

// PostRun is a no-op for All prefetcher.
func (All) PostRun(_ string) error { return nil }

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
func (Git) Scan(idx *index.Index) (suffix string, count, diskSize int64, err error) {
	n, ok := idx.LookupAll(".git")
	if !ok || !n.IsDir() {
		return "", 0, 0, errors.New("remote directory is not a git repository")
	}

	return ".git/", int64(n.CountAll(-1)), n.DiskSizeAll(-1), nil
}

// PostRun runs git executable in order to restore downloaded state in working
// directory.
func (Git) PostRun(wd string) error {
	var (
		buf = bytes.Buffer{}
		cmd = exec.Command("git", "reset", "--hard")
	)

	cmd.Dir, cmd.Stderr = wd, &buf
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("git command exited with error: %v (%q)", err, buf.String())
	}

	return nil
}

/*
// FetchCmd creates a strategy with prefetch command to run.
func (s *Sync) FetchCmd() (count, diskSize int64, cmd *rsync.Command, err error) {
	spv := client.NewSupervised(s.opts.ClientFunc, 30*time.Second)
	// Get remote username.
	username, err := spv.CurrentUser()
	if err != nil {
		return 0, 0, nil, err
	}

	// Get remote host and port.
	host, port, err := s.opts.SSHFunc()
	if err != nil {
		return 0, 0, nil, err
	}

	cmd = &rsync.Command{
		Download:        true,
		SourcePath:      s.m.RemotePath + "/",
		DestinationPath: s.CacheDir() + "/",
		Username:        username,
		Host:            host,
		SSHPort:         port,
	}

	// Look for git VCS.
	if n, ok := s.idx.LookupAll(".git"); ok && n.IsDir() {
		// Download only git data.
		cmd.SourcePath += ".git/"
		cmd.DestinationPath += ".git/"

		count = int64(n.CountAll(-1))
		diskSize = n.DiskSizeAll(-1)
	} else {
		count = int64(s.idx.CountAll(-1))
		diskSize = s.idx.DiskSizeAll(-1)
	}

	return count, diskSize, cmd, nil
}

func drawProgress(w io.Writer, nAll, sizeAll int64) func(n, size, speed int64, err error) {
	const noop = 0

	maxLength, speedLast := 0, int64(0)
	return func(n, size, speed int64, err error) {
		if err == io.EOF {
			n, size, speed = nAll, sizeAll, speedLast
		}

		drawFunc := ioprogress.DrawTerminalf(w, func(_, _ int64) string {
			line := fmt.Sprintf("Prefetching files: %.1f%% (%d/%d), %s/%s | %s/s",
				float64(size)/float64(sizeAll)*100.0, // percentage status.
				n,    // number of downloaded files.
				nAll, // number of all files being downloaded.
				humanize.IBytes(uint64(size)),    // size of downloaded files.
				humanize.IBytes(uint64(sizeAll)), // total size.
				humanize.IBytes(uint64(speed)),   // current downloading speed.
			)

			if len(line) < maxLength {
				line = fmt.Sprintf("%s%s", line, strings.Repeat(" ", maxLength-len(line)))
			}
			maxLength, speedLast = len(line), speed

			return line
		})

		drawFunc(noop, noop) // We are not using default values.
		if err != nil {
			drawFunc(-1, -1) // Finish drawing.
		}
	}
}
*/
