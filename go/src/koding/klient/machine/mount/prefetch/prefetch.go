package prefetch

import (
	"context"
	"fmt"
	"io"

	"koding/klient/machine/index"
	"koding/klient/machine/transport/rsync"
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

	// WorkDir represents destination files working directory.
	WorkDir string `json:"workDir"`

	// Strategy strategy stores the name of strategy used to prefetch files.
	Strategy string `json:"strategy"`

	// Count stores the amount of files which are going to be prefetched.
	Count int64 `json:"count"`

	// DiskSize stores the size of all fetched files.
	DiskSize int64 `json:"diskSize"`
}

// Run ues rsync to prefetch files. It writes information about prefetching
// progress to provided writer. Strategy is used to post run operations after
// prefetching.
func (p *Prefetch) Run(w io.Writer, s Strategy, privPath string) error {
	if p.Strategy == "" {
		fmt.Fprintf(w, "Prefetching is disabled, skipping.\n")
		return nil
	}

	pref, ok := s[p.Strategy]
	if !ok {
		return fmt.Errorf("missing %s file prefetching strategy", p.Strategy)
	}

	if p.SourcePath == "" || p.DestinationPath == "" {
		return fmt.Errorf("missing prefetching paths")
	}

	fmt.Fprintf(w, "Using %s files strategy to prefetch initial mount data.\n", p.Strategy)

	cmd := &rsync.Command{
		Download:        true,
		SourcePath:      p.SourcePath,
		DestinationPath: p.DestinationPath,
		Username:        p.Username,
		Host:            p.Host,
		SSHPort:         p.SSHPort,
		PrivateKeyPath:  privPath,
		Progress:        rsync.Progress(w, p.Count, p.DiskSize),
	}

	// Create initial progess report and run the command.
	cmd.Progress(0, 0, 0, nil)

	return nonil(cmd.Run(context.Background()), pref.PostRun(p.WorkDir))
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
