package rsync

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"sync"
	"time"

	"koding/kites/config"
	"koding/klient/machine/client"
	"koding/klient/machine/index"
	msync "koding/klient/machine/mount/sync"
	"koding/klientctl/ssh"
)

// Builder is a factory for rsync-based synchronization objects.
type Builder struct{}

// Build satisfies msync.Builder interface. It produces Rsync objects from a
// given options if rsync executable is present in $PATH.
func (Builder) Build(opts *msync.BuildOpts) (msync.Syncer, error) {
	return NewRsync(opts)
}

// Event is a rsync synchronization object that utilizes rsync executable.
type Event struct {
	ev     *msync.Event
	parent *Rsync
}

// Exec satisfies msync.Execer interface. It executes rsync executable with
// arguments available to sync stored change.
func (e *Event) Exec() error {
	if !e.ev.Valid() {
		return nil
	}
	defer e.ev.Done()

	host, port, err := e.parent.dynSSH()
	if err != nil {
		return err
	}

	change := e.ev.Change()
	err = e.parent.Cmd(e.ev.Context(), e.makeArgs(host, port, change)...).Run()
	e.parent.indexSync(change)

	return err
}

// makeArgs transforms provided index change to rsync executable arguments.
func (e *Event) makeArgs(host string, port int, c *index.Change) []string {
	remote := e.parent.username + "@" + host + ":"
	if e.parent.username == "" || host == "" {
		remote = ""
	}

	var (
		src  = filepath.Join(e.parent.local, c.Path())
		dst  = remote + filepath.Join(e.parent.remote, c.Path())
		meta = c.Meta()
	)

	if meta&index.ChangeMetaLocal == 0 && meta&index.ChangeMetaRemote != 0 {
		src, dst = dst, src // Swap sync directions.
	}

	var rsyncAgent []string
	if e.parent.privKeyPath != "" {
		sshcmd := "ssh -i " + e.parent.privKeyPath + " -oStrictHostKeyChecking=no"
		if port > 0 && port != 22 {
			sshcmd += " -p " + strconv.Itoa(port)
		}
		rsyncAgent = append(rsyncAgent, "-e", sshcmd)
	}

	if meta&index.ChangeMetaRemove != 0 {
		rsyncAgent = append(rsyncAgent, "--delete")
	}

	rsyncAgent = append(rsyncAgent, "--include='/"+filepath.Base(src)+"'", "--exclude='*'")

	return append(rsyncAgent, "-zlptgoDd", filepath.Dir(src)+"/", filepath.Dir(dst)+"/")
}

// String implements fmt.Stringer interface. It pretty prints internal event.
func (e *Event) String() string {
	return e.ev.String() + " - " + "rsynced"
}

// Rsync uses rsync(1) file-copying tool to provide synchronization between
// remote and local files.
type Rsync struct {
	Cmd func(ctx context.Context, args ...string) *exec.Cmd // Comand factory.

	remote      string               // remote directory root.
	local       string               // local directory root.
	privKeyPath string               // ssh private key path.
	username    string               // remote username.
	dynSSH      msync.DynamicSSHFunc // address of connected machine.
	indexSync   msync.IndexSyncFunc  // callback used to update index.

	once  sync.Once
	stopC chan struct{} // channel used to close any opened exec streams.
}

// NewRsync creates a new Rsync object from given options.
func NewRsync(opts *msync.BuildOpts) (*Rsync, error) {
	// Get path for SSH private key.
	privKeyPath, err := UserSSHPrivateKeyPath()
	if err != nil {
		return nil, err
	}

	// Get remote machine user name.
	username, err := client.NewSupervised(opts.ClientFunc, 10*time.Second).CurrentUser()
	if err != nil {
		return nil, err
	}

	return &Rsync{
		Cmd: func(ctx context.Context, args ...string) *exec.Cmd {
			cmd := exec.CommandContext(ctx, "rsync", args...)
			cmd.Env = os.Environ()
			return cmd
		},

		remote:      opts.Mount.RemotePath,
		local:       opts.CacheDir,
		privKeyPath: privKeyPath,
		username:    username,
		dynSSH:      opts.SSHFunc,
		indexSync:   opts.IndexSyncFunc,
		stopC:       make(chan struct{}),
	}, nil
}

// ExecStream wraps incoming msync events with Rsync event logic that is
// responsible for invoking rsync process and ensuring final index state.
func (r *Rsync) ExecStream(evC <-chan *msync.Event) <-chan msync.Execer {
	exC := make(chan msync.Execer)

	go func() {
		defer close(exC)
		for {
			select {
			case ev, ok := <-evC:
				if !ok {
					return
				}

				ex := &Event{
					ev:     ev,
					parent: r,
				}
				select {
				case exC <- ex:
				case <-r.stopC:
					return
				}
			case <-r.stopC:
				return
			}
		}
	}()

	return exC
}

// UserSSHPrivateKeyPath gets the filepath to user's private SSH key.
func UserSSHPrivateKeyPath() (string, error) {
	path, err := ssh.GetKeyPath(config.CurrentUser.User)
	if err != nil {
		return "", err
	}

	_, privKeyPath, err := ssh.KeyPaths(path)
	if err != nil {
		return "", err
	}

	return privKeyPath, nil
}

// Close stops all created synchronization streams.
func (r *Rsync) Close() error {
	r.once.Do(func() {
		close(r.stopC)
	})

	return nil
}
