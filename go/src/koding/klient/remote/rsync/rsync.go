package rsync

import (
	"bytes"
	"errors"
	"fmt"
	"math"
	"os"
	"os/exec"
	"strings"
	"time"

	"koding/klient/util"

	"github.com/koding/kite"
	"github.com/koding/logging"
)

type Progress struct {
	Progress int        `json:progress`
	Error    kite.Error `json:error`
}

type Client struct {
	log logging.Logger
}

func NewClient(log logging.Logger) *Client {
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
	DirSize           int64  `json:"dirSize"`
	LocalToRemote     bool   `json:"localToRemote"`
	IgnoreFile        string `json:"ignoreFile"`
	IncludePath       bool   `json:"includePath"`
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
	case o.IgnoreFile != "":
		return false
	case o.IncludePath != false:
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
	log := rs.log.New("sync")

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
	case opts.RemoteDir == "":
		err = errors.New("SyncOpts.RemoteDir is required.")
	}
	if err != nil {
		progCh <- progressErr(err)
		close(progCh)
		return
	}

	var dstDir, srcDir string
	if opts.LocalToRemote {
		log.Debug("Using localToRemote")
		srcDir = opts.LocalDir
		dstDir = fmt.Sprintf("%s@%s:%s", opts.Username, opts.Host, opts.RemoteDir)
	} else {
		log.Debug("Using remoteToLocal")
		srcDir = fmt.Sprintf("%s@%s:%s", opts.Username, opts.Host, opts.RemoteDir)
		dstDir = opts.LocalDir
	}

	if !opts.IncludePath {
		// add / to end so rsync syncs considers the folder to be root level;
		// if not it creates the folder itself
		srcDir = srcDir + string(os.PathSeparator)
	}

	args := []string{}

	if opts.IgnoreFile != "" {
		args = append(args, fmt.Sprintf("--filter=:- %s", opts.IgnoreFile))
	}

	args = append(args, []string{
		"--progress", "--delete", "-zave",
		fmt.Sprintf("ssh -i %s -oStrictHostKeyChecking=no", opts.SSHPrivateKeyPath),
		srcDir, dstDir,
	}...)

	log.Debug(
		"Running command: rsync %s",
		strings.Join(util.QuoteSpacedStrings(args...), " "),
	)
	cmd := exec.Command("rsync", args...)

	// Record our stderr, incase we need to print an error.
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

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
		// If the error was an exit error, log the last X lines of stderr output to
		// aid in debugging.
		if _, ok := err.(*exec.ExitError); ok {
			rs.log.Error(
				"RSync returned a non-zero exit status.\nerr: %s, stderr output:\n%s",
				err, stderr.String(),
			)
		}
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
