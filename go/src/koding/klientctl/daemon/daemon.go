package daemon

import (
	"bytes"
	"compress/gzip"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"

	"koding/kites/config"
)

type Details struct {
	Username     string                       `json:"username"`
	KodingHome   string                       `json:"kodingHome"`
	KlientHome   string                       `json:"klientHome"`
	Files        map[string]string            `json:"files"`
	LogFiles     map[string]map[string]string `json:"logFiles"`
	Installation []InstallResult              `json:"status,omitempty"`
}

func newDetails() *Details {
	kd := "/usr/local/bin/kd"

	klientHome := "/opt/kite/klient"
	if s := os.Getenv("KLIENT_HOME"); s != "" {
		klientHome = s
	}

	return &Details{
		Username:   config.CurrentUser.Username,
		KodingHome: config.KodingHome(),
		KlientHome: klientHome,
		Files: map[string]string{
			"klient":    filepath.Join(klientHome, "klient"),
			"klient.sh": filepath.Join(klientHome, "klient.sh"),
			"kd":        kd,
		},
		LogFiles: map[string]map[string]string{
			"kd": {
				"darwin": "/Library/Logs/kd.log",
				"linux":  "/var/log/kd.log",
			},
			"klient": {
				"darwin": "/Library/Logs/klient.log",
				"linux":  "/var/log/klient.log",
			},
		},
	}
}

func (d *Details) setPrefix(prefix string) {
	d.KlientHome = prefix
	d.Files = map[string]string{
		"klient":    filepath.Join(prefix, "klient"),
		"klient.sh": filepath.Join(prefix, "klient.sh"),
		"kd":        filepath.Join(prefix, "kd"),
	}
}

func (d *Details) helper() *klientSh {
	return &klientSh{
		Username:     d.Username,
		KlientPath:   d.Files["klient"],
		KlientShPath: d.Files["klient.sh"],
	}
}

func parseVersion(bin string) (int, error) {
	p, err := exec.Command(bin, "-version").Output()
	if err != nil {
		return 0, err
	}

	q := bytes.SplitN(p, []byte{'.'}, 3)
	if len(q) != 3 {
		return 0, errors.New("invalid version string")
	}

	n, err := strconv.Atoi(string(q[2]))
	if err != nil {
		return 0, err
	}

	return n, nil
}

func wget(url, output string) error {
	if err := os.MkdirAll(filepath.Dir(output), 0755); err != nil {
		return err
	}

	f, err := os.OpenFile(output, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0755)
	if err != nil {
		return err
	}

	resp, err := http.Get(url)
	if err != nil {
		return err
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return errors.New(url + ":" + http.StatusText(resp.StatusCode))
	}

	var buf bytes.Buffer // to restore begining of a response body consumed by gzip.NewReader
	var body io.Reader = io.MultiReader(&buf, resp.Body)

	// If body contains gzip header, it means the payload was compressed.
	// Relying solely on Content-Type == "application/gzip" check
	// was not reliable.
	if r, err := gzip.NewReader(io.TeeReader(resp.Body, &buf)); err == nil {
		if r, err = gzip.NewReader(body); err == nil {
			body = r
		}
	}

	if _, err := io.Copy(f, body); err != nil {
		return err
	}

	return f.Close()
}

func curl(url string, format string, v interface{}) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return errors.New(url + ":" + http.StatusText(resp.StatusCode))
	}

	n, err := fmt.Fscanf(resp.Body, format, v)
	if err != nil {
		return err
	}
	if n != 1 {
		return io.ErrUnexpectedEOF
	}

	return nil
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
