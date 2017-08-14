package daemon

import (
	"archive/tar"
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
	"path/filepath"
	"runtime"
	"strconv"
	"strings"

	conf "koding/kites/config"
	"koding/kites/config/configstore"
	"koding/kites/kloud/metadata"
	"koding/klient/tunnel/tlsproxy"
	"koding/klient/uploader"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/auth"
	"koding/klientctl/helper"

	multierror "github.com/hashicorp/go-multierror"
	"github.com/koding/logging"
)

var vagrantfile = []byte(`VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
    config.vm.hostname = "kd-install-test"
end
`)

// ErrSkipInstall is returned by InstallStep's Install/Uninstall
// functors, when a given step should be skipped.
var ErrSkipInstall = errors.New("skip installation step")

// InstallResult describes a result of a single InstallStep execution.
type InstallResult struct {
	Skipped bool   `json:"skipped"`           // whether the step was skipped
	Name    string `json:"name,omitempty"`    // name of the step
	Version string `json:"version,omitempty"` // step versionning
}

// InstallStep represents a single installation step,
// like "Installing KD Daemon" or "Testing Vagrant Stacks".
//
// Steps are ordered and used for install / uninstall
// and update procedures.
//
// Steps are executed in an increasing order during
// the "install" procedure.
//
// Steps are executed in a decreasing order during
// the "uninstall" procedure.
type InstallStep struct {
	Name        string                               // name of the step
	Install     func(*Client, *Opts) (string, error) // code to run during installation
	Uninstall   func(*Client, *Opts) error           // code to run during uninstallation
	RunOnUpdate bool                                 // whether to run the Install on update procedure
}

// Opts describe daemon optional parameters used by
// install / uninstall and update commands in order
// to change their behaviour.
type Opts struct {
	Force   bool     // whether to continue installation steps despite any failure
	Token   string   // an optional kite token to use during authentication
	Prefix  string   // an optional custom installation directory
	Baseurl string   // Koding baseurl to use
	Team    string   // Koding team to use
	Skip    []string // steps that should be omitted during installation
}

// Installs executes installation steps.
//
// If the execution fails, Install marks the step which
// failed in a cache, so another Install is going to
// continue from that exact step.
func (c *Client) Install(opts *Opts) error {
	c.init()

	if opts.Baseurl == "" {
		return errors.New("invalid empty -baseurl value")
	}

	base, err := url.Parse(opts.Baseurl)
	if err != nil {
		return err
	}

	if opts.Prefix != "" {
		c.d.setPrefix(opts.Prefix)
	}

	start := min(len(c.d.Installation), len(Script))
	if opts.Force {
		start = 0
	}

	switch start {
	case 0:
		fmt.Fprintln(os.Stderr, "Performing fresh installation...")
	case len(Script):
		return errors.New(`Already installed. To reinstall, run "sudo kd uninstall" first.`)
	default:
		fmt.Fprintf(os.Stderr, "Resuming installation at %q step...\n", Script[start].Name)
	}

	c.d.Base = &conf.URL{
		URL: base,
	}

	skip := make(map[string]struct{}, len(opts.Skip))
	for _, s := range opts.Skip {
		skip[strings.ToLower(s)] = struct{}{}
	}

	var merr error
	for _, step := range c.script()[start:] {
		fmt.Fprintf(os.Stderr, "Installing %q...\n\n", step.Name)

		result := InstallResult{
			Name: step.Name,
		}

		if _, ok := skip[strings.ToLower(step.Name)]; ok {
			result.Skipped = true
		} else {
			result.Version, err = step.Install(c, opts)
			switch err {
			case ErrSkipInstall:
				result.Skipped = true
			case nil:
			default:
				if !opts.Force {
					return fmt.Errorf("error installing %q: %s", step.Name, err)
				}

				merr = multierror.Append(merr, err)
				fmt.Fprintf(os.Stderr, "\terror: %s\n\n", err)
			}
		}

		if result.Skipped {
			fmt.Fprintf(os.Stderr, "\tAlready installed, skipping.\n\n")
		}

		c.d.Installation = append(c.d.Installation, result)
	}

	if err = c.Ping(); err != nil {
		if merr == nil {
			return err
		}

		merr = multierror.Append(merr, err)
	}

	if merr == nil {
		fmt.Println("Installed successfully.")
	}

	return merr
}

// Uninstall executes uninstallation steps.
//
// If installation failed at a certain step, Uninstall
// is going to execute steps starting from that exact step.
func (c *Client) Uninstall(opts *Opts) error {
	c.init()

	start := min(len(c.d.Installation), len(c.script())) - 1
	if opts.Force {
		start = len(Script) - 1
	}

	switch start {
	case -1:
		return errors.New(`Already uninstalled. To install again, run "sudo kd install".`)
	case len(Script) - 1:
		fmt.Fprintln(os.Stderr, "Performing full uninstallation...")
	default:
		fmt.Fprintf(os.Stderr, "Performing partial uninstallation at %q step...\n", c.script()[start].Name)
	}

	var merr error
	for i := start; i >= 0; i-- {
		step := c.script()[i]

		fmt.Fprintf(os.Stderr, "Uninstalling %q...\n", step.Name)

		if step.Uninstall != nil {
			switch err := step.Uninstall(c, opts); err {
			case nil, ErrSkipInstall:
			default:
				if !opts.Force {
					return fmt.Errorf("error uninstalling %q: %s", step.Name, err)
				}

				merr = multierror.Append(merr, err)
				fmt.Fprintf(os.Stderr, "\terror: %s\n\n", err)
			}
		}

		c.d.Installation = c.d.Installation[:i]
	}

	if len(c.d.Installation) == 0 || opts.Force {
		c.uninstall = true
	}

	if merr == nil {
		fmt.Println("Uninstalled successfully.")
	}

	return merr
}

// Update runs installation steps which are marked as updatable.
func (c *Client) Update(opts *Opts) error {
	c.init()

	if len(c.d.Installation) != len(c.script()) {
		return errors.New(`KD is not yet installed. Please run "sudo kd install".`)
	}

	var merr error
	for i, step := range c.script() {
		if !step.RunOnUpdate || c.Install == nil {
			continue
		}

		fmt.Fprintf(os.Stderr, "Updating %q...\n\n", step.Name)

		switch version, err := step.Install(c, opts); err {
		case nil:
			c.d.Installation[i].Version = version
		case ErrSkipInstall:
			fmt.Fprintf(os.Stderr, "\tAlready updated, skipping.\n\n")
		default:
			if !opts.Force {
				return fmt.Errorf("error updating %q: %s", step.Name, err)
			}

			merr = multierror.Append(merr, err)
		}
	}

	if err := c.Ping(); err != nil {
		if merr == nil {
			return err
		}

		merr = multierror.Append(merr, err)
	}

	return merr
}

func (c *Client) needVagrant(opts *Opts) bool {
	if c.vagrant != nil {
		return *c.vagrant
	}

	if opts.Force {
		b := true
		c.vagrant = &b
		return true
	}

	for {
		resp, err := helper.Ask("\tDo you want to deploy Vagrant Stacks on this machine? [y/N]: ")
		if err != nil {
			return false
		}

		fmt.Fprintln(os.Stderr)

		switch strings.ToLower(resp) {
		case "y", "yes":
			b := true
			c.vagrant = &b
			return true
		case "", "n", "no":
			b := false
			c.vagrant = &b
			return false
		}
	}
}

func InstallScreen() error {
	var res InstallResult

	err := DefaultClient.store().Commit(func(cache *conf.Cache) error {
		return cache.GetValue("daemon.screen", &res)
	})

	if err == nil {
		return ErrSkipInstall
	}

	DefaultClient.log().Info("Going to install screen...")

	switch _, err = Screen.Install(DefaultClient, nil); err {
	case nil:
		DefaultClient.log().Info("Screen was successfully installed.")
	case ErrSkipInstall:
		res.Skipped = true
	default:
		return err
	}

	res.Name = "screen"

	return nonil(DefaultClient.store().Commit(func(cache *conf.Cache) error {
		return cache.SetValue("daemon.screen", &res)
	}), err)
}

var Screen = (map[string]InstallStep{
	"darwin": {
		Name: "screen",
		Install: func(c *Client, _ *Opts) (string, error) {
			return "", ErrSkipInstall
		},
		Uninstall: func(c *Client, _ *Opts) error {
			return nil
		},
	},
	"linux": {
		Name: "screen",
		Install: func(*Client, *Opts) (string, error) {
			const base = "/opt/kite/klient/embedded"
			bin := filepath.Join(base, "bin", "screen")

			if fi, err := os.Stat(bin); err == nil && !fi.IsDir() {
				return "", ErrSkipInstall
			}

			if err := mkdirAll(base, 0755); err != nil {
				return "", err
			}

			// TODO(rjeczalik): remove after kloud deploy
			_ = exec.Command("sudo", "chown", "-R", conf.CurrentUser.Username, "/opt/kite").Run()

			resp, err := http.Get(metadata.DefaultScreenURL)
			if err != nil {
				return "", err
			}
			defer resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				return "", errors.New(http.StatusText(resp.StatusCode))
			}

			cr, err := gzip.NewReader(resp.Body)
			if err != nil {
				return "", err
			}
			defer cr.Close()

			tr := tar.NewReader(cr)

			for {
				h, err := tr.Next()
				if err == io.EOF {
					break
				}
				if err != nil {
					return "", err
				}

				name := filepath.Join("/", h.Name)

				if !strings.HasPrefix(name, base) {
					return "", errors.New("invalid entry: " + name)
				}

				if h.Typeflag == tar.TypeDir {
					if err := mkdirAll(name, 0755); err != nil {
						return "", err
					}

					continue
				}

				if h.Typeflag != tar.TypeReg && h.Typeflag != tar.TypeRegA {
					return "", err
				}

				f, err := os.OpenFile(name, os.O_TRUNC|os.O_CREATE|os.O_WRONLY, os.FileMode(h.Mode))
				if err != nil {
					return "", err
				}

				_, err = io.Copy(f, tr)
				err = nonil(err, f.Chown(conf.CurrentUser.Uid, conf.CurrentUser.Gid), f.Close())
				if err != nil {
					return "", err
				}
			}

			// Best-effort attempt of creating screen dir.
			_ = symlink(filepath.Join(base, "share", "terminfo"), "/usr/share/terminfo")

			return "", nil
		},
		Uninstall: func(c *Client, _ *Opts) error {
			return os.RemoveAll("/opt/kite/klient/embedded")
		},
	},
})[runtime.GOOS]

func mkdirAll(dir string, mode os.FileMode) error {
	if err := os.MkdirAll(dir, mode); err != nil {
		return err
	}

	return os.Chown(dir, conf.CurrentUser.Gid, conf.CurrentUser.Gid)
}

func symlink(from, to string) error {
	if _, err := os.Stat(to); err == nil {
		return nil
	}

	if err := os.MkdirAll(filepath.Dir(to), 0755); err != nil {
		return err
	}

	return os.Symlink(from, to)
}

func run(cmd string, args ...string) error {
	var buf bytes.Buffer

	c := exec.Command(cmd, args...)
	c.Stderr = &buf

	if err := c.Run(); err != nil {
		return fmt.Errorf("%s: %s", err, &buf)
	}

	return nil
}

// Script is a list of installation steps, used by default by KD.
var Script = []InstallStep{{
	Name: "log files",
	Install: func(c *Client, _ *Opts) (string, error) {
		kd := c.d.LogFiles["kd"][runtime.GOOS]
		klient := c.d.LogFiles["klient"][runtime.GOOS]

		f, err := os.OpenFile(kd, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0644)
		if err != nil {
			return "", err
		}

		ctlcli.CloseOnExit(f)

		if err := f.Chown(conf.CurrentUser.Uid, conf.CurrentUser.Gid); err != nil {
			return "", err
		}

		c.log().SetHandler(logging.NewWriterHandler(f))
		fmt.Fprintf(os.Stderr, "\tCreated log file: %s\n", kd)

		fk, err := os.Create(klient)
		if err == nil {
			err = nonil(fk.Chown(conf.CurrentUser.Uid, conf.CurrentUser.Gid), fk.Close())
		}
		if err != nil {
			return "", err
		}

		fmt.Fprintf(os.Stderr, "\tCreated log file: %s\n\n", klient)

		return "", err
	},
	Uninstall: func(c *Client, _ *Opts) (err error) {
		for _, file := range c.d.LogFiles {
			err = nonil(err, os.Remove(file[runtime.GOOS]))
		}
		return err
	},
}, {
	Name: "directory structure",
	Install: func(c *Client, _ *Opts) (string, error) {
		return "", nonil(mkdirAll(c.d.KlientHome, 0755), mkdirAll(c.d.KodingHome, 0755))
	},
	Uninstall: func(c *Client, _ *Opts) error {
		return os.RemoveAll(c.d.KodingHome)
	},
}, (map[string]InstallStep{
	"darwin": {
		Name: "osxfuse",
		Install: func(c *Client, _ *Opts) (string, error) {
			const volume = "/Volumes/FUSE for macOS"
			const pkg = volume + "/Extras/FUSE for macOS 3.5.8.pkg"

			if _, err := os.Stat("/Library/Filesystems/osxfuse.fs"); err == nil {
				return "", ErrSkipInstall
			}

			dmg := c.d.Osxfuse

			if err := dmgInstall(dmg.String(), volume, pkg); err != nil {
				return "", err
			}

			return dmg.Version, nil
		},
	},
	"linux": {
		Name: "FUSE",
		Install: func(c *Client, _ *Opts) (string, error) {
			// TODO(rjeczalik): check if FUSE is correctly configured?

			return "", ErrSkipInstall
		},
	},
})[runtime.GOOS], (map[string]InstallStep{
	"darwin": {
		Name: "VirtualBox",
		Install: func(c *Client, opts *Opts) (string, error) {
			const volume = "/Volumes/VirtualBox"
			const pkg = volume + "/VirtualBox.pkg"

			if hasVirtualBox() || !c.needVagrant(opts) {
				return "", ErrSkipInstall
			}

			dmg := c.d.Virtualbox[runtime.GOOS]

			if err := dmgInstall(dmg.String(), volume, pkg); err != nil {
				return "", err
			}

			return dmg.Version, nil
		},
	},
	"linux": {
		Name: "VirtualBox",
		Install: func(c *Client, opts *Opts) (string, error) {
			if hasVirtualBox() || !c.needVagrant(opts) {
				return "", ErrSkipInstall
			}

			vbox := c.d.Virtualbox[runtime.GOOS]

			// Best-effort attempt to install dependencies on Debian/Ubuntu.
			//
			// TODO(rjeczalik): use distro-specific virtualbox installers
			if _, err := exec.LookPath("apt-get"); err == nil {
				kernel, err := exec.Command("uname", "-r").Output()
				if err != nil {
					return "", err
				}

				headers := fmt.Sprintf("linux-headers-%s", bytes.TrimSpace(kernel))
				_ = cmd("apt-get", "install", "-q", "-y", "dkms", headers, "make", "build-essential").Run()

			}

			run, err := wgetTemp(vbox.String(), 0755)
			if err != nil {
				return "", err
			}
			defer os.Remove(run)

			if err := cmd("sh", "-c", run).Run(); err != nil {
				return "", err
			}

			return vbox.Version, nil
		},
	},
})[runtime.GOOS], (map[string]InstallStep{
	"darwin": {
		Name: "Vagrant",
		Install: func(c *Client, opts *Opts) (string, error) {
			const volume = "/Volumes/Vagrant"
			const pkg = volume + "/Vagrant.pkg"

			if hasVagrant() || !c.needVagrant(opts) {
				return "", ErrSkipInstall
			}

			dmg := c.d.Vagrant[runtime.GOOS]

			if err := dmgInstall(dmg.String(), volume, pkg); err != nil {
				return "", err
			}

			// Best-effort workaround for Vagrant 1.8.7, which fails to "box add".
			_ = os.Remove("/opt/vagrant/embedded/bin/curl")

			return dmg.Version, nil
		},
	},
	"linux": {
		Name: "Vagrant",
		Install: func(c *Client, opts *Opts) (string, error) {
			if hasVagrant() || !c.needVagrant(opts) {
				return "", ErrSkipInstall
			}

			vagrant := c.d.Vagrant[runtime.GOOS]

			deb, err := wgetTemp(vagrant.String(), 0755)
			if err != nil {
				return "", err
			}
			defer os.Remove(deb)

			dpkg := cmd("dpkg", "-i", deb)
			dpkg.Env = append(os.Environ(), "DEBIAN_FRONTEND=noninteractive")

			if err := dpkg.Run(); err != nil {
				return "", err
			}

			return vagrant.Version, nil
		},
	},
})[runtime.GOOS], {
	Name: "Koding account",
	Install: func(c *Client, opts *Opts) (string, error) {
		f, err := c.newFacade()
		if err != nil {
			return "", err
		}

		if opts.Team != "" {
			fmt.Printf("\tSign in to your %q team (%s):\n\n", opts.Team, f.Konfig.Endpoints.Koding.Public)
		} else if opts.Token != "" {
			// TODO(rjeczalik): This is compatibility branch with old installation
			// method which did take team into account when authenticating.
			//
			// Every jToken has a relationship to a jGroup it was created from,
			// thus we do not ask user for their teamname, since we got it
			// from the auth response.
			fmt.Printf("\tSign in to your team with %q token:\n\n", opts.Token)
		} else {
			fmt.Printf("\tSign in to your kd.io account:\n\n")
		}

		_, err = f.Login(&auth.LoginOptions{
			Team:   opts.Team,
			Token:  opts.Token,
			Prefix: "\t",
			Force:  true,
		})

		fmt.Println()

		return "", nonil(err, f.Close())
	},
}, {
	Name: "KD Daemon",
	Install: func(c *Client, _ *Opts) (string, error) {
		var version, newVersion int

		if n, err := parseVersion(c.d.Files["klient"]); err == nil {
			version = n
		}

		if err := curl(c.klientLatest(), "%d", &newVersion); err != nil {
			return "", err
		}

		fmt.Fprintf(os.Stderr, "\tCurrent version: %s\n", formatVersion(version))
		fmt.Fprintf(os.Stderr, "\tLatest version: %s\n\n", formatVersion(newVersion))

		if version != 0 && newVersion <= version {
			return strconv.Itoa(version), ErrSkipInstall
		}

		svc, err := c.d.service()
		if err != nil {
			return "", err
		}

		// Best-effort attempt at stopping the running klient, if any.
		_ = svc.Stop()

		if err := wget(c.klient(newVersion), c.d.Files["klient"], 0755); err != nil {
			return "", err
		}

		if err := c.d.helper().Create(); err != nil {
			return "", err
		}

		// Best-effort attempt at uninstalling klient service, if any.
		_ = svc.Uninstall()

		if err := svc.Install(); err != nil {
			return "", err
		}

		// Best-effort attempts at fixinig permissions and ownership, ignore any errors.
		_ = configstore.FixOwner()
		_ = uploader.FixPerms()
		_ = tlsproxy.Init()

		if n, err := parseVersion(c.d.Files["klient"]); err == nil {
			version = n
		}

		return strconv.Itoa(version), nil
	},
	Uninstall: func(c *Client, _ *Opts) error {
		svc, err := c.d.service()
		if err != nil {
			return err
		}

		_ = svc.Stop() // ignore failue, klient may be already stopped
		_ = svc.Uninstall()

		return nonil(os.Remove(c.d.Files["klient.sh"]), os.Remove(c.d.Files["klient"]))
	},
	RunOnUpdate: true,
}, {
	Name: "KD",
	Install: func(c *Client, _ *Opts) (string, error) {
		var version, newVersion int

		if n, err := parseVersion(c.d.Files["kd"]); err == nil {
			version = n
		}

		if err := curl(c.kdLatest(), "%d", &newVersion); err != nil {
			return "", err
		}

		fmt.Fprintf(os.Stderr, "\tCurrent version: %s\n", formatVersion(version))
		fmt.Fprintf(os.Stderr, "\tLatest version: %s\n\n", formatVersion(newVersion))

		if version != 0 && version < config.VersionNum() && os.Args[0] != c.d.Files["kd"] {
			if err := copyFile(os.Args[0], c.d.Files["kd"], 0755); err != nil {
				return "", err
			}

			return config.Version, nil
		}

		if version != 0 && newVersion <= version {
			return strconv.Itoa(version), ErrSkipInstall
		}

		if err := wget(c.kd(newVersion), c.d.Files["kd"], 0755); err != nil {
			return "", err
		}

		return strconv.Itoa(newVersion), nil
	},
	RunOnUpdate: true,
}, {
	Name: "Start KD Deamon",
	Install: func(c *Client, _ *Opts) (string, error) {
		svc, err := c.d.service()
		if err != nil {
			return "", err
		}

		// Stop the daemon if it's running, for the new configuration
		// to take effect.
		_ = svc.Stop()

		if err := svc.Start(); err != nil {
			return "", err
		}
		return "", c.Ping()
	},
	RunOnUpdate: true,
}, {
	Name: "Test Vagrant Stacks",
	Install: func(c *Client, opts *Opts) (string, error) {
		if !c.needVagrant(opts) {
			return "", ErrSkipInstall
		}

		w, err := newWorkplace()
		if err != nil {
			return "", err
		}

		if err := w.init(vagrantfile); err != nil {
			return "", nonil(err, w.Close())
		}

		_ = w.run("vagrant", "box", "add", "ubuntu/trusty64", "--no-color")
		err = nonil(w.run("vagrant", "up", "--no-color"), w.Close())

		if err == nil {
			fmt.Printf("\n\tYour system seems ready to have some Vagrant Stacks deployed!\n\n")
		} else {
			fmt.Printf("\n\tInstaller failed to create a simple Vagrant vm.\n")
		}

		return "", err
	},
}}

type workplace string

func newWorkplace() (workplace, error) {
	dir, err := ioutil.TempDir("", "kd-workplace")
	if err != nil {
		return "", err
	}

	return workplace(dir), nil
}

func (w workplace) init(vagrantfile []byte) error {
	return ioutil.WriteFile(filepath.Join(string(w), "Vagrantfile"), vagrantfile, 0644)
}

func (w workplace) Close() error {
	if !strings.HasPrefix(filepath.Base(string(w)), "kd-workplace") {
		return nil
	}

	if err := w.run("vagrant", "destroy", "--force", "--no-color"); err != nil {
		return err
	}

	return os.RemoveAll(string(w))
}

func (w workplace) run(cmd string, args ...string) error {
	c := exec.Command(cmd, args...)
	c.Env = append(os.Environ(), "VAGRANT_CHECKPOINT_DISABLE=1")
	c.Dir = string(w)

	c.Stdout = os.Stdout
	c.Stderr = os.Stderr

	fmt.Fprintf(os.Stderr, "\t[%s] Running %v ...\n\n", w, c.Args)

	return c.Run()
}

func hasVirtualBox() bool {
	const s = "Oracle VM VirtualBox Headless Interface"

	// Ignore the following error while running VBoxHeadless under darwin:
	//
	//   exit status 2 VBoxHeadless: error: --height: RTGetOpt: Command line option needs argument.
	//
	p, _ := exec.Command("VBoxHeadless", "-h").CombinedOutput()
	return strings.Contains(string(p), s)
}

func hasVagrant() bool {
	const s = "Installed Version:"

	cmd := exec.Command("vagrant", "version")
	cmd.Env = append(os.Environ(), "VAGRANT_CHECKPOINT_DISABLE=1")

	p, err := cmd.CombinedOutput()
	if err != nil {
		return false
	}

	return strings.Contains(string(p), s)
}

func copyFile(src, dst string, mode os.FileMode) error {
	fsrc, err := os.Open(src)
	if err != nil {
		return err
	}
	defer fsrc.Close()

	if mode == 0 {
		fi, err := fsrc.Stat()
		if err != nil {
			return err
		}

		mode = fi.Mode()
	}

	if err := mkdirAll(filepath.Dir(dst), 0755); err != nil {
		return err
	}

	tmp, err := ioutil.TempFile(filepath.Split(dst))
	if err != nil {
		return err
	}

	if _, err = io.Copy(tmp, fsrc); err != nil {
		return nonil(err, tmp.Close(), os.Remove(tmp.Name()))
	}

	u := conf.CurrentUser

	if err = nonil(tmp.Chmod(mode), tmp.Chown(u.Uid, u.Gid), tmp.Close()); err != nil {
		return nonil(err, os.Remove(tmp.Name()))
	}

	if err = os.Rename(tmp.Name(), dst); err != nil {
		return nonil(err, os.Remove(tmp.Name()))
	}

	return nil
}

func formatVersion(version int) string {
	if version <= 0 {
		return "-"
	}
	return "0.1." + strconv.Itoa(version)
}
