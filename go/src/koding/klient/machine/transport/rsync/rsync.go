package rsync

import (
	"bufio"
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"syscall"
	"time"
	"unicode"

	"koding/klient/machine/index"
	kos "koding/klient/os"
)

// englishEnv contains current environment with C locale.
var englishEnv []string

func init() {
	englishEnv = kos.NewEnviron(os.Environ()).Encode(kos.ParseEnviron("LANG=C,LC_ALL=C"))
}

// Command describes rsync executable.
type Command struct {
	// Download indicates the direction of changes. If set to true, source path
	// defines remote machine.
	Download bool `json:"download"`

	// SourcePath defines source path from which file(s) will be pulled.
	// This field is required.
	SourcePath string `json:"sourcePath"`

	// DestinationPath defines destination path to which file(s) will be pushed.
	// This field is required.
	DestinationPath string `json:"destinationPath"`

	// Cmd defines command to run. If nil, default rsync command will be used.
	Cmd *exec.Cmd `json:"-"`

	// Username defines remote machine user name. If not set, localhost transfer
	// will be used.
	Username string `json:"username"`

	// Host defines the remote machine address. If not set, localhost transfer
	// will be used.
	Host string `json:"host"`

	// PrivateKeyPath if set, SSH remote shell will be used as a data transport.
	PrivateKeyPath string `json:"privateKeyPath"`

	// SSHPort defines custom remote shell port. If not set, default will be used.
	SSHPort int `json:"sshPort"`

	// Progress if set, rsync will be run in recursive and verbose mode. The
	// current status of downloading will be periodically sent to provided
	// progress callback function. io.EOF error is sent to the callback when
	// downloading is complete.
	Progress func(n, size, speed int64, err error) `json:"-"`

	// Change if set, joins change name to source and destination paths and
	// uses provided metadata to set rsync arguments that allow to sync the
	// change.
	Change *index.Change `json:"change,omitempty"`

	// Output specifies an optional writer which, if set, will receive rsync
	// command output.
	Output io.Writer `json:"-"`
}

// valid checks if command fields are valid.
func (c *Command) valid() error {
	if c == nil {
		return errors.New("rsync: command is nil")
	}

	if c.SourcePath == "" {
		return errors.New("rsync: source path is not set")
	}
	if c.DestinationPath == "" {
		return errors.New("rsync: destination path is not set")
	}

	return nil
}

// DryRun copies command and runs it in dry mode - no copying is performed. This
// method is useful when one need to check the amount and size of transferred
// files.
func (c *Command) DryRun(ctx context.Context) (n, size int64, err error) {
	copy := *c

	// Dissable progress bar.
	var found = false
	copy.Progress = func(nAll, sizeAll, _ int64, err error) {
		if err == nil {
			n, size, found = nAll, sizeAll, true
		}
	}

	// Shallow copy since Cmd can be used only once.
	if copy.Cmd == nil {
		copy.Cmd = exec.CommandContext(ctx, "rsync")
	} else {
		copyCmd := *c.Cmd
		copy.Cmd = &copyCmd
	}

	copy.Cmd.Args = append(copy.Cmd.Args, "--dry-run")
	if err := copy.run(ctx, copy.dryscan); err != nil {
		return 0, 0, err
	}

	if !found {
		return 0, 0, errors.New("data size and number was not found")
	}

	return n, size, nil
}

// Run starts new rsync process. And waits for it to complete.
func (c *Command) Run(ctx context.Context) error {
	return c.run(ctx, c.scan)
}

// Run starts new rsync process. And waits for it to complete.
func (c *Command) run(ctx context.Context, scan func(r io.Reader)) error {
	if err := c.valid(); err != nil {
		return err
	}

	if c.Cmd == nil {
		c.Cmd = exec.CommandContext(ctx, "rsync")
	}

	// Add default arguments.
	c.Cmd.Args = append(c.Cmd.Args, "-zlptgoDd")
	if c.Cmd.Env == nil {
		c.Cmd.Env = englishEnv
	} else {
		c.Cmd.Env = kos.NewEnviron(englishEnv).Encode(kos.NewEnviron(c.Cmd.Env))
	}

	// Use remote shell if SSH private key path is set.
	if c.PrivateKeyPath != "" {
		// TODO(ppknap): check if RC4 cipher will work on every machine without
		// altering sshd_config on destination.
		rsh := []string{
			"ssh", "-T", "-x", "-i", c.PrivateKeyPath,
			"-oCompression=no",
			"-oStrictHostKeychecking=no",
			"-oUserKnownHostsFile=/dev/null",
		}

		if c.SSHPort > 0 {
			rsh = append(rsh, " -p ", strconv.Itoa(c.SSHPort))
		}

		c.Cmd.Args = append(c.Cmd.Args, "-e", strings.Join(rsh, " "))
	}

	// Apply index change.
	if c.Change != nil {
		c.SourcePath = filepath.Join(c.SourcePath, c.Change.Path())
		c.DestinationPath = filepath.Join(c.DestinationPath, c.Change.Path())

		meta := c.Change.Meta()
		c.Download = meta&index.ChangeMetaLocal == 0 && meta&index.ChangeMetaRemote != 0
		if c.Download {
			c.SourcePath, c.DestinationPath = c.DestinationPath, c.SourcePath
		}

		if meta&index.ChangeMetaRemove != 0 {
			c.Cmd.Args = append(c.Cmd.Args, "--delete")
		}

		c.Cmd.Args = append(c.Cmd.Args, "--include='/"+filepath.Base(c.SourcePath)+"'", "--exclude='*'")
	}

	// Progress logic needs verbose mode with itemized changes.
	if c.Progress != nil {
		c.Cmd.Args = append(c.Cmd.Args, "-Piv")
		if c.Change == nil {
			// Do not use recursive downloads for index changes.
			c.Cmd.Args = append(c.Cmd.Args, "-r")
		}
	}

	var destPath = c.DestinationPath
	if c.Username != "" && c.Host != "" {
		if c.Download {
			c.SourcePath = c.Username + "@" + c.Host + ":" + c.SourcePath
		} else {
			c.DestinationPath = c.Username + "@" + c.Host + ":" + destPath
		}
	}

	if c.Change != nil {
		c.Cmd.Args = append(c.Cmd.Args, filepath.Dir(c.SourcePath)+"/", filepath.Dir(c.DestinationPath)+"/")
	} else {
		c.Cmd.Args = append(c.Cmd.Args, c.SourcePath, c.DestinationPath)
	}

	var errBuf bytes.Buffer
	c.Cmd.Stderr = noNilMultiWriter(c.Cmd.Stderr, c.Output, &errBuf)
	if c.Progress == nil {
		c.Cmd.Stdout = noNilMultiWriter(c.Cmd.Stdout, c.Output)
		return c.Cmd.Run()
	}

	// Set up progress callback when it's provided.
	rc, err := c.Cmd.StdoutPipe()
	if err != nil {
		return err
	}
	defer rc.Close()

	var r io.Reader = rc
	if c.Output != nil {
		r = io.TeeReader(rc, c.Output)
	}

	if err := c.Cmd.Start(); err != nil {
		return err
	}

	scan(r)
	if err = c.Cmd.Wait(); err != nil {
		c.Progress(0, 0, 0, err)
		if ee, ok := err.(*exec.ExitError); ok {
			// If we upload files and get exit status code set to 12 from rsync
			// this most likely means that we don't have write access to to
			// destination directory.
			//
			// syscall.WaitStatus is present both on Windows and Unix.
			if status, ok := ee.Sys().(syscall.WaitStatus); ok && status.ExitStatus() == 12 && !c.Download {
				err = fmt.Errorf("cannot upload files to %s, you may not have write permissions to this path", destPath)
			} else {
				ee.Stderr = errBuf.Bytes()
			}
		}
	} else {
		c.Progress(0, 0, 0, io.EOF)
	}

	return err
}

var (
	rmComma = strings.NewReplacer(",", "")
	bitRe   = regexp.MustCompile(`^[.><ch*].{7,11} .`)
	sizeRe  = regexp.MustCompile(`^\s*([\d,]+)\s+\d+%.*$`)
	totalRe = regexp.MustCompile(`^[^\d]*([\d,]+).*(?:speedup\sis|DRY\sRUN).*$`)
)

func (c *Command) dryscan(r io.Reader) {
	var n int64

	scanner := bufio.NewScanner(r)
	scanner.Split(scanNonControl)
	for scanner.Scan() {
		line := scanner.Text()
		if bitRe.MatchString(line) {
			n++
			continue
		}

		ms := totalRe.FindStringSubmatch(line)
		if len(ms) < 2 {
			continue
		}
		rmComma.Replace(ms[1])
		size, err := strconv.Atoi(rmComma.Replace(ms[1]))
		if err != nil {
			continue
		}

		c.Progress(n, int64(size), 0, nil)
	}
}

func (c *Command) scan(r io.Reader) {
	var (
		now           time.Time
		n, size, part int64
	)

	scanner := bufio.NewScanner(r)
	scanner.Split(scanNonControl)
	for scanner.Scan() {
		if now.IsZero() {
			now = time.Now()
		}

		line := scanner.Text()
		if bitRe.MatchString(line) {
			size += part
			n++
			part = 0
			continue
		}

		ms := sizeRe.FindStringSubmatch(line)
		if len(ms) < 2 {
			continue
		}
		rmComma.Replace(ms[1])
		p, err := strconv.Atoi(rmComma.Replace(ms[1]))
		if err != nil {
			continue
		}

		part = int64(p)

		speed := int64(float64(part+size)/(float64(time.Since(now))/float64(time.Second)) + 0.5)
		c.Progress(n, part+size, speed, nil)
	}
}

func scanNonControl(data []byte, atEOF bool) (advance int, token []byte, err error) {
	if atEOF && len(data) == 0 {
		return 0, nil, nil
	}

	if i := bytes.IndexFunc(data, unicode.IsControl); i >= 0 {
		return i + 1, dropCR(data[0:i]), nil
	}

	if atEOF {
		return len(data), dropCR(data), nil
	}

	return 0, nil, nil
}

// dropCR drops a terminal \r from the data. This function was copied from
// standard library.
func dropCR(data []byte) []byte {
	if len(data) > 0 && data[len(data)-1] == '\r' {
		return data[0 : len(data)-1]
	}
	return data
}

// noNilMultiWriter creates a multi writer from provided non-nil writers. If
// all writers are nil, this function will return nil writer.
func noNilMultiWriter(ws ...io.Writer) io.Writer {
	var writers []io.Writer
	for _, w := range ws {
		if w != nil {
			writers = append(writers, w)
		}
	}

	if len(writers) == 0 {
		return nil
	}

	return io.MultiWriter(writers...)
}
