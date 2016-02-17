package rsync

import (
	"errors"
	"fmt"
	"math"
	"os"
	"os/exec"
	"time"

	"github.com/koding/kite"
)

type Progress struct {
	Progress int        `json:progress`
	Error    kite.Error `json:error`
}

type Client struct {
	log kite.Logger
}

func NewClient(log kite.Logger) *Client {
	return &Client{
		log: log,
	}
}

type SyncOpts struct {
	Host              string `json:"host"`
	Username          string `json:"username"`
	SSHAuthSock       string `json:"sshAuthSock"`
	SSHPrivateKeyPath string `json:"sshPrivateKeyPath"`
	RemoteDir         string `json:"remoteDir"`
	LocalDir          string `json:"localDir"`
	DirSize           int    `json:"dirSize"`
}

type SyncIntervalOpts struct {
	SyncOpts
	Interval time.Duration `json:"interval"`
}

// IsZero returns true if the struct is zero value, false otherwise.
func (o SyncOpts) IsZero() bool {
	switch {
	case o.Host != "":
		return false
	case o.Username != "":
		return false
	case o.SSHAuthSock != "":
		return false
	case o.SSHPrivateKeyPath != "":
		return false
	case o.RemoteDir != "":
		return false
	case o.LocalDir != "":
		return false
	case o.DirSize != 0:
		return false
	default:
		return true
	}
}

// IsZero returns true if the struct is zero value, false otherwise.
func (o SyncIntervalOpts) IsZero() bool {
	// If the embedded SyncOpts isn't zero, then this isn't.
	if !o.SyncOpts.IsZero() {
		return false
	}

	// Check any SyncInterval specific options, if they're not zero the struct
	// is not zero value.
	if o.Interval != 0 {
		return false
	}

	return true
}

func (c *Client) SyncInterval(opts SyncIntervalOpts) (SyncIntervaler, error) {
	si := &syncInterval{
		Syncer: c,
		Opts:   opts,
	}

	si.Start()

	return si, nil
}

func (rs *Client) Sync(opts SyncOpts) <-chan Progress {
	progCh := make(chan Progress, 100)

	go rs.sync(progCh, opts)

	return progCh
}

// sync implements the blocking version of Sync
func (rs *Client) sync(progCh chan Progress, opts SyncOpts) {
	//rs.log.Info("Running RSync.sync with opts: %#v", opts)

	var err error
	switch {
	case opts.Host == "":
		err = errors.New("SyncOpts.Host is required.")
	case opts.Username == "":
		err = errors.New("SyncOpts.Username is required.")
	case opts.SSHAuthSock == "":
		err = errors.New("SyncOpts.SSHAuthSock is required.")
	case opts.SSHPrivateKeyPath == "":
		err = errors.New("SyncOpts.SSHPrivateKeyPath is required.")
	case opts.LocalDir == "":
		err = errors.New("SyncOpts.LocalDir is required.")
	case opts.DirSize == 0:
		err = errors.New("SyncOpts.DirSize is required.")
	}
	if err != nil {
		progCh <- progressErr(err)
		close(progCh)
		return
	}

	// add / to end so rsync syncs considers the folder to be root level;
	// if not it creates the folder itself
	remoteDir := opts.RemoteDir + string(os.PathSeparator)

	cmd := exec.Command(
		"rsync", "--progress", "--delete", "-zave",
		fmt.Sprintf("ssh -i %s -oStrictHostKeyChecking=no", opts.SSHPrivateKeyPath),
		fmt.Sprintf("%s@%s:%s", opts.Username, opts.Host, remoteDir),
		opts.LocalDir,
	)

	// Rsync is using SSH which requires a valid SSH_AUTH_SOCK of the user calling
	// kd. So, we accept that and apply it to the rsync command here.
	cmd.Env = append(os.Environ(), []string{
		fmt.Sprintf("SSH_AUTH_SOCK=%s", opts.SSHAuthSock),
	}...)

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		progCh <- progressErr(err)
		close(progCh)
		return
	}

	done := make(chan bool)
	progress := ParseProgress(stdout)

	go func() {
		var percentage int
		for p := range progress {
			// Figure out the percentage of data downloaded, based on the total size
			percentage = int(math.Floor(float64(p) / float64(opts.DirSize) * 100))

			// The kite API only sends percentage and error events - because of this,
			// the API consumer won't know when the progress is truly done. Ie, we
			// could return 100%, 110%, etc.
			//
			// So, by changing any >= percentages to 100, while progress is still being
			// parsed, we ensure to only send a final 100%. The worst case, is that we
			// send a lot of 99% events, but that seems like a reasonable tradeoff.
			//
			// For future developers, if stuck at 99% becomes a problem, the original
			// size estimate given to Sync() was likely wrong - this is the easiest fix.
			// If that is not good enough, the API can be changed to return a Done:bool
			// field, so that percentage does not matter so much.
			if percentage >= 100 {
				percentage = 99
			}

			progCh <- Progress{
				Progress: percentage,
			}
		}

		// To make the api simple, always send the last event as 100 percent.
		progCh <- Progress{
			Progress: 100,
		}

		done <- true
	}()

	if err := cmd.Run(); err != nil {
		progCh <- progressErr(err)
		// No need to close chan here, because we close below in all events.
	}

	<-done
	close(progCh)
	close(done)
}

// progressErr returns a progress formatted with a kiteError
func progressErr(err error) Progress {
	return Progress{
		Error: kite.Error{
			Message: err.Error(),
		},
	}
}
