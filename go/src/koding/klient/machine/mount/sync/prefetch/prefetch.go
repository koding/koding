package prefetch

import (
	"koding/klient/machine/index"
)

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

// Options defines a set of options needed to select and build Prefetch object.
type Options struct {
	// SourcePath defines source path from which file(s) will be pulled.
	SourcePath string `json:"sourcePath"`

	// DestinationPath defines destination path to which file(s) will be pushed.
	DestinationPath string `json:"destinationPath"`

	// Username defines remote machine user name.
	Username string `json:"username"`

	// Host defines the remote machine address.
	Host string `json:"host"`

	// SSHPort defines custom remote shell port.
	SSHPort int `json:"sshPort"`
}

// Prefetch is used to initially prefetch files from remote machine to local
// directory.
type Prefetch struct {
	Options

	// Strategy strategy stores the name of strategy used to prefetch files.
	Strategy string `json:"strategy"`

	// Count stores the amount of files which are going to be prefetched.
	Count int64 `json:"count"`

	// DiskSize stores the size of all fetched files.
	DiskSize int64 `json:"diskSize"`
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
