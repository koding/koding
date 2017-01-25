package daemon

import (
	"bytes"
	"compress/gzip"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strconv"

	"koding/kites/config"
	conf "koding/klientctl/config"
)

// TODO:
//
//   - kd/daemon: add more logs
//   - koding/homebrew-kd
//   - remove old code
//
type Package struct {
	*config.URL `json:"url"`
	Version     string `json:"version"`
}

type Details struct {
	Username     string                       `json:"username"`
	Base         *config.URL                  `json:"baseURL"`
	Osxfuse      *Package                     `json:"osxfuse"`
	Virtualbox   map[string]*Package          `json:"virtualbox"`
	Vagrant      map[string]*Package          `json:"vagrant"`
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
		Osxfuse: &Package{
			URL:     mustURL("https://s3.amazonaws.com/koding-dl/osxfuse-3.5.2.dmg"),
			Version: "3.5.2",
		},
		Virtualbox: map[string]*Package{
			"darwin": {
				URL:     mustURL("http://download.virtualbox.org/virtualbox/5.1.8/VirtualBox-5.1.8-111374-OSX.dmg"),
				Version: "5.1.8",
			},
			"linux": {
				URL:     mustURL("http://download.virtualbox.org/virtualbox/5.1.8/VirtualBox-5.1.8-111374-Linux_amd64.run"),
				Version: "5.1.8",
			},
		},
		Vagrant: map[string]*Package{
			"darwin": {
				URL:     mustURL("https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.7.dmg"),
				Version: "1.8.7",
			},
			"linux": {
				URL:     mustURL("https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.7_x86_64.deb"),
				Version: "1.8.7",
			},
		},
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

func mustURL(s string) *config.URL {
	u, err := url.Parse(s)
	if err != nil {
		panic(s + ": " + err.Error())
	}
	return &config.URL{
		URL: u,
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

func (d *Details) base() *url.URL {
	if !d.Base.IsNil() {
		return d.Base.URL
	}
	return conf.Konfig.Endpoints.Koding.Public.URL
}

func cmd(name string, args ...string) *exec.Cmd {
	c := exec.Command(name, args...)
	c.Stderr = os.Stderr
	c.Stdout = os.Stderr
	return c
}

func dmgInstall(url, volume, pkg string) error {
	dmg, err := wgetTemp(url)
	if err != nil {
		return err
	}
	defer os.Remove(dmg)

	if err := cmd("hdiutil", "attach", dmg).Run(); err != nil {
		return err
	}

	if err := cmd("installer", "-pkg", pkg, "-target", "/").Run(); err != nil {
		return err
	}

	return cmd("diskutil", "unmount", "force", volume).Run()
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

func wgetTemp(s string) (string, error) {
	u, err := url.Parse(s)
	if err != nil {
		return "", err
	}

	dir, err := ioutil.TempDir("", "kd-daemon-install")
	if err != nil {
		return "", err
	}

	tmp := filepath.Join(dir, path.Base(u.Path))

	if err := wget(s, tmp); err != nil {
		return "", nonil(err, os.RemoveAll(dir))
	}

	return tmp, nil
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
