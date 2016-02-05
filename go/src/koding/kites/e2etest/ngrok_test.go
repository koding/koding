package e2etest

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"koding/kites/kloud/utils"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"strings"
	"time"

	"golang.org/x/net/context"
	"golang.org/x/net/context/ctxhttp"
)

type Ngrok struct {
	StartTimeout time.Duration // by default 15s

	exec    string
	process *exec.Cmd
}

func NewNgrok() (*Ngrok, error) {
	if Test.NgrokToken == "" {
		return nil, errors.New("Test.NgrokToken is empty")
	}

	ngrok, err := exec.LookPath("ngrok")
	if err != nil {
		return nil, err
	}

	n := &Ngrok{
		StartTimeout: 15 * time.Second,
		exec:         ngrok,
	}

	// NOTE(rjeczalik): currently we have authtoken for ngrok v1, ensure
	// the executable is correct version.
	version, err := n.Version()
	if err != nil {
		return nil, err
	}

	if !strings.HasPrefix(version, "1.") {
		return nil, errors.New("ngrok v1 required, got: " + version)
	}

	return n, nil
}

func (n *Ngrok) Version() (string, error) {
	c := n.cmd("version")
	c.Stdout = nil
	out, err := c.Output()
	if err != nil {
		return "", err
	}
	var version string
	p := bytes.Split(bytes.TrimSpace(out), []byte{' '})
	if len(p) != 0 {
		version = string(bytes.TrimSpace(p[len(p)-1]))
	}
	if version == "" {
		return "", errors.New("unable to read version")
	}
	return version, nil
}

func (n *Ngrok) Start(subdomain, localAddr string) (string, error) {
	if n.process != nil {
		return "", errors.New("ngrok tunnel is already running")
	}

	if subdomain == "" {
		subdomain = utils.RandString(12)
	}

	p := n.cmd("-log", "stdout", "-authtoken", Test.NgrokToken, "-subdomain", subdomain, localAddr)
	if err := p.Start(); err != nil {
		return "", err
	}

	// wait for tunnel to get up
	tunnelHost := subdomain + ".ngrok.com"
	tunnelURL := "http://" + tunnelHost
	ctx, cancel := context.WithTimeout(context.Background(), n.StartTimeout)
	defer cancel()

	for {
		resp, err := ctxhttp.Get(ctx, nil, tunnelURL)
		if err == context.DeadlineExceeded {
			return "", fmt.Errorf("timed out after %s waiting for %s to be ready", n.StartTimeout, tunnelURL)
		}
		if err == nil {
			resp.Body.Close()

			// 404 means tunnel not found
			if resp.StatusCode != http.StatusNotFound {
				n.process = p
				return tunnelHost, nil
			}
		}

		time.Sleep(1 * time.Second)
	}
}

var respAnchor = []byte("Read message ")

func (n *Ngrok) StartTCP(localAddr string) (string, error) {
	if n.process != nil {
		return "", errors.New("ngrok tunnel is already running")
	}

	var ngrokResp struct {
		Type    string
		Payload struct {
			ReqId    string
			Url      string
			Protocol string
			Error    string
		}
	}

	r, w, err := os.Pipe()
	if err != nil {
		return "", err
	}

	p := n.cmd("-log", "stdout", "-authtoken", Test.NgrokToken, "-proto", "tcp", localAddr)
	if p.Stdout != nil {
		p.Stdout = io.MultiWriter(p.Stdout, w)
	} else {
		p.Stdout = w
	}
	if err := p.Start(); err != nil {
		return "", err
	}

	var scanErr error
	scanner := bufio.NewScanner(bufio.NewReader(r))

	for scanner.Scan() {
		line := scanner.Bytes()
		i := bytes.Index(line, respAnchor)
		if i == -1 {
			continue
		}

		if err := json.Unmarshal(line[i+len(respAnchor):], &ngrokResp); err != nil {
			Test.Log.Debug("ngrok.StartTCP: %s", err)
			continue
		}

		if ngrokResp.Payload.Error != "" {
			scanErr = errors.New(ngrokResp.Payload.Error)
			break
		}

		if ngrokResp.Type == "NewTunnel" {
			u, err := url.Parse(ngrokResp.Payload.Url)
			if err != nil {
				scanErr = err
				break
			}
			host, port, err := net.SplitHostPort(u.Host)
			if err != nil {
				scanErr = err
				break
			}
			addrs, err := net.LookupHost(host)
			if err != nil {
				scanErr = err
			}
			return net.JoinHostPort(addrs[0], port), nil
		}
	}
	p.Process.Kill()
	if scanErr != nil {
		return "", scanErr
	}
	if err := scanner.Err(); err != nil {
		return "", err
	}
	return "", errors.New("couldn't read remote TCP address")
}

func (n *Ngrok) Stop() error {
	if n.process == nil {
		return errors.New("ngrok tunnel is not started")
	}

	p := n.process
	n.process = nil

	p.Process.Kill()
	return p.Wait()

}

func (n *Ngrok) cmd(args ...string) *exec.Cmd {
	c := exec.Command(n.exec, args...)
	if Test.Debug {
		Test.Log.Debug("creating ngrok command: %v", args)
	}
	if Test.NgrokDebug {
		c.Stderr = os.Stderr
		c.Stdout = os.Stdout
	}
	return c
}
