package rsync

import (
	"bufio"
	"bytes"
	"context"
	"errors"
	"io"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
	"unicode"
)

// Command describes rsync executable.
type Command struct {
	// Download indicates the direction of changes. If set to true, source path
	// defines remote machine.
	Download bool

	// SourcePath defines source path from which file(s) will be pulled.
	// This field is required.
	SourcePath string

	// DestinationPath defines destination path to which file(s) will be pushed.
	// This field is required.
	DestinationPath string

	// Cmd defines command to run. If nil, default rsync command will be used.
	Cmd *exec.Cmd

	// Username defines remote machine user name. If not set, localhost transfer
	// will be used.
	Username string

	// Host defines the remote machine address. If not set, localhost transfer
	// will be used.
	Host string

	// PrivateKeyPath if set, SSH remote shell will be used as a data transport.
	PrivateKeyPath string

	// SSHPort defines custom remote shell port. If not set, default will be used.
	SSHPort int

	// Progress if set, rsync will be run in recursive and verbose mode. The
	// current status of downloading will be periodically sent to provided
	// progress callback function. io.EOF error is sent to the callback when
	// downloading is complete.
	Progress func(n, size, speed int64, err error)
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

// Run starts new rsync process. And waits for it to complete.
func (c *Command) Run(ctx context.Context) error {
	if err := c.valid(); err != nil {
		return err
	}

	if c.Cmd == nil {
		c.Cmd = exec.CommandContext(ctx, "rsync")
	}

	// Add default arguments.
	c.Cmd.Args = append(c.Cmd.Args, "-zlptgoDd")

	// Use remote shell if SSH private key path is set.
	if c.PrivateKeyPath != "" {
		// TODO(ppknap): check if RC4 cipher will work on every machine without
		// altering sshd_config on destination.
		rsh := []string{
			"ssh", "-T", "-x", "-i", c.PrivateKeyPath,
			"-oCompression=no",
			"-oStrictHostKeychecking=no",
		}

		if c.SSHPort > 0 {
			rsh = append(rsh, " -p ", strconv.Itoa(c.SSHPort))
		}

		c.Cmd.Args = append(c.Cmd.Args, "-e", strings.Join(rsh, " "))
	}

	// Progress logic needs verbose mode with itemized changes.
	if c.Progress != nil {
		c.Cmd.Args = append(c.Cmd.Args, "-Priv")
	}

	if c.Username != "" && c.Host != "" {
		if c.Download {
			c.SourcePath = c.Username + "@" + c.Host + ":" + c.SourcePath
		} else {
			c.DestinationPath = c.Username + "@" + c.Host + ":" + c.DestinationPath
		}
	}
	c.Cmd.Args = append(c.Cmd.Args, c.SourcePath, c.DestinationPath)

	if c.Progress == nil {
		return c.Cmd.Run()
	}

	// Set up progress callback when it's provided.
	rc, err := c.Cmd.StdoutPipe()
	if err != nil {
		return err
	}
	defer rc.Close()

	if err := c.Cmd.Start(); err != nil {
		return err
	}

	c.scan(rc)
	return c.Cmd.Wait()
}

var (
	rmComma = strings.NewReplacer(",", "")
	bitRe   = regexp.MustCompile(`^[.><ch*].......... .`)
	sizeRe  = regexp.MustCompile(`^\s*([\d,]+)\s+\d+%.*$`)
)

func (c *Command) scan(r io.Reader) {
	defer c.Progress(0, 0, 0, io.EOF)

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

		speed := int64(float64(part+size)/float64(time.Since(now)/time.Second) + 0.5)
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
