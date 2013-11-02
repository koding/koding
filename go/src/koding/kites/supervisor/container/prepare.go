package container

import (
	"fmt"
	"koding/kites/supervisor/rbd"
	"os"
	"os/exec"
	"path"
	"strconv"
	"syscall"
	"time"
)

// Prepare creates and initialized the container to be started later directly
// with lxc.start. We don't use lxc.create (which uses shell scipts for
// templating). Instead we use this method which basically let us do things
// more simpler. It creates the home directory, generates files like lxc.conf
// and mounts the necessary disks.
func (c *Container) Prepare() error {
	err := c.CreateContainerDir()
	if err != nil {
		return err
	}

	err := c.MountRBD()
	if err != nil {
		return err
	}

	err := c.CreateOverlay()
	if err != nil {
		return err
	}

	err := c.MergingFiles()
	if err != nil {
		return err
	}

	err = c.MountAufs()
	if err != nil {
		return err
	}

	err = c.PrepareAndMountPts()
	if err != nil {
		return err
	}

	err = c.AddEbtablesRule()
	if err != nil {
		return err
	}

	err = c.AddStaticRoute()
	if err != nil {
		return err
	}

	err = c.PrepareHomeDirectory()
	if err != nil {
		return err
	}

	return nil
}

func (c *Container) CreateContainerDir() {
	fmt.Println("generating lxc files")
	err := c.AsHost().PrepareDir(c.Path(""))
	if err != nil {
		return err // for now just check this, no need for others
	}

	c.AsHost().GenerateFile(c.Path("config"), "config")
	c.AsHost().GenerateFile(c.Path("fstab"), "fstab")
	c.AsHost().GenerateFile(c.Path("ip-address"), "ip-address")

	return nil
}

func (c *Container) MountRBD() error {
	fmt.Println("mounting rbd")
	r := rbd.NewRBD(c.Name)

	out, err := r.Info(c.Name)
	if err != nil {
		return err
	}

	makeFileSystem := false
	// means image doesn't exist, create new one
	if out == nil {
		out, err := r.Create(c.Name, "1024")
		if err != nil {
			return fmt.Errorf("mountrbd create failed.", err, out)
		}

		makeFileSystem = true
	}

	out, err = r.Map(c.Name)
	if err != nil {
		return fmt.Errorf("mountrbd map failed.", err, out)
	}

	timeout := time.Now().Add(30 * time.Second)
	for {
		_, err := os.Stat(r.Device)
		if err == nil {
			break
		}
		if !os.IsNotExist(err) {
			return err
		}
		time.Sleep(time.Second / 2)

		if time.Now().After(timeout) {
			return fmt.Errorf("timeout. rbd device '%s' does not exist", r.Device)
		}
	}

	// protect fsck.ext4 is not concurrent ready
	c.Lock()
	defer c.Unlock()

	if makeFileSystem {
		if out, err := exec.Command("/sbin/mkfs.ext4", r.Device).CombinedOutput(); err != nil {
			return fmt.Errorf("mkfs.ext4 failed.", err, out)
		}
	}

	mountDir := c.OverlayPath("")

	err = c.CheckExt4(r.Device)
	if err != nil {
		return err
	}

	if err := os.Mkdir(mountDir, 0755); err != nil && !os.IsExist(err) {
		return err
	}

	if out, err := exec.Command("/bin/mount", "-t", "ext4", r.Device, mountDir).CombinedOutput(); err != nil {
		os.Remove(mountDir)
		return fmt.Errorf("mount rbd failed. err: %s\nout:%s\n", err, string(out))
	}

	return nil
}

func (c *Container) CreateOverlay() error {
	fmt.Println("generating  overlay files")
	err := c.AsContainer().PrepareDir(c.OverlayPath("")) //for chown
	if err != nil {
		return err // for now just check this, no need for others
	}

	c.AsContainer().PrepareDir(c.OverlayPath("lost+found")) // for chown
	c.AsContainer().PrepareDir(c.OverlayPath("etc"))

	c.AsContainer().GenerateFile(c.OverlayPath("etc/hostname"), "hostname")
	c.AsContainer().GenerateFile(c.OverlayPath("etc/hosts"), "hosts")
	c.AsContainer().GenerateFile(c.OverlayPath("etc/ldap.conf"), "ldap.conf")

	return nil
}

func (c *Container) MergingFiles() error {
	fmt.Println("merging files")
	c.MergePasswdFile()
	c.MergeGroupFile()
	c.MergeDpkgDatabase()
}

// mount "/var/lib/lxc/vm-{id}/overlay" (rw) and "/var/lib/lxc/vmroot" (ro)
// under "/var/lib/lxc/vm-{id}/rootfs"
func (c *Container) MountAufs() error {
	fmt.Println("creating empty rootfs for aufs")
	err = c.AsContainer().PrepareDir(c.Path("rootfs"))
	if err != nil {
		return err
	}

	fmt.Println("mounting aufs")
	out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "aufs", "-o",
		fmt.Sprintf("noplink,br=%s:%s", c.OverlayPath(""), vmRoot+"/rootfs/"),
		"aufs", c.Path("rootfs")).CombinedOutput()
	if err != nil {
		return fmt.Errorf("mount overlay failed. err: %s\n out:%s\n", err, out)
	}

	return nil
}

func (c *Container) PrepareAndMountPts() error {
	fmt.Println("preparing and mounting pts")
	c.AsContainer().PrepareDir(c.PtsDir())

	out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "devpts", "-o",
		"rw,noexec,nosuid,newinstance,gid="+strconv.Itoa(RootUIDOffset+5)+",mode=0620,ptmxmode=0666",
		"devpts", c.PtsDir()).CombinedOutput()
	if err != nil {
		return fmt.Errorf("mount devpts failed. err: %s\n out:%s\n", err, out)
	}

	c.AsContainer().Chown(c.PtsDir())
	c.AsContainer().Chown(c.PtsDir() + "/ptmx")

	return nil
}

func (c *Container) AddEbtablesRule() error {
	fmt.Println("add ebtables rules")
	// add ebtables entry to restrict IP and MAC
	out, err := exec.Command("/sbin/ebtables", "--append", "VMS", "--protocol", "IPv4", "--source",
		c.MAC().String(), "--ip-src", c.IP.String(), "--in-interface", c.VEth(),
		"--jump", "ACCEPT").CombinedOutput()
	if err != nil {
		return fmt.Errorf("ebtables rule addition failed. err: %s\n out:%s\n", err, out)
	}

	return nil
}

func (c *Container) AddStaticRoute() error {
	fmt.Println("add static route")
	// add a static route so it is redistributed by BGP
	out, err := exec.Command("/sbin/route", "add", c.IP.String(), "lxcbr0").CombinedOutput()
	if err != nil {
		return fmt.Errorf("adding route failed. err: %s\n out:%s\n", err, out)
	}

	return nil
}

func (c *Container) PrepareHomeDirectory() error {
	fmt.Println("prepare home directories")
	// make sure that executable flag is set
	os.Chmod(c.Path("rootfs/"), 0755)
	os.Chmod(c.Path("rootfs/home"), 0755)

	err := c.createUserHome()
	if err != nil {
		return err
	}

	vmWebDir := c.Path(fmt.Sprintf("rootfs/home/%s/Web", c.WebHome))
	err = c.createWebDir(vmWebDir)
	if err != nil {
		return err
	}

	return nil
}

// create and initiate /home/username from {templatedir}/user
func (c *Container) createUserHome() error {
	homeDir := c.Path(fmt.Sprintf("rootfs/home/%s", c.Username))

	fmt.Println("creating user home:...", homeDir)
	if info, err := os.Stat(homeDir); !os.IsNotExist(err) {
		// make sure that user read and executable flag is set
		fmt.Println("username exist", info.Name(), info.IsDir())
		return os.Chmod(homeDir, info.Mode().Perm()|0511)
	}

	fmt.Println("home directory does not exist", c.Username)
	// home directory does not exist, create it
	err := os.MkdirAll(homeDir, 0755)
	if err != nil {
		return err
	}

	fmt.Println("chowning ", homeDir)
	err = c.AsUser().Lchown(homeDir)
	if err != nil {
		return err
	}

	err = c.AsUser().Chown(homeDir)
	if err != nil {
		return err
	}

	err = c.copyIntoContainer(templateDir+"/user", homeDir)
	if err != nil {
		return err
	}

	return nil
}

// create and initiate /home/username/Web from {templatedir}/website. Also
// make symlink to /var/www from /home/username/Web that it get served via
// Apache webserver.
func (c *Container) createWebDir(webDir string) error {
	wwwDir := c.Path("rootfs/var/www")
	if err := os.Symlink(webDir, wwwDir); err != nil && !os.IsExist(err) {
		return err
	}
	c.AsContainer().Lchown(wwwDir)

	if _, err := os.Stat(webDir); !os.IsNotExist(err) {
		return nil // web directory exist
	}

	err := os.MkdirAll(webDir, 0755)
	if err != nil {
		return err
	}

	err = c.AsUser().Lchown(webDir)
	if err != nil {
		return err
	}

	err = c.copyIntoContainer(templateDir+"/website", webDir)
	if err != nil {
		return err
	}

	return nil
}

func (c *Container) copyIntoContainer(src, dst string) error {
	sf, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sf.Close()

	fi, err := sf.Stat()
	if err != nil {
		return err
	}

	// TODO: There are some folders called "empty-diretory", look at them.
	if fi.Name() == "empty-directory" {
		// ignored file
	} else if fi.IsDir() {
		fmt.Println("src is a dir:", src, path.Base(src))
		err := os.Mkdir(dst, fi.Mode())
		if err != nil && !os.IsExist(err) {
			return err
		}

		err = c.AsUser().Lchown(dst)
		if err != nil {
			return err
		}

		entries, err := sf.Readdirnames(0)
		if err != nil {
			return err
		}

		for _, entry := range entries {
			if err := c.copyIntoContainer(src+"/"+entry, dst+"/"+entry); err != nil {
				return err
			}
		}
	} else {
		fmt.Printf("copying from '%s' to '%s'\n", src, dst)
		err := c.AsUser().CopyFile(src, dst)
		if err != nil {
			return err
		}
	}

	return nil
}

func (c *Container) CheckExt4(device string) error {
	// check/correct filesystem
	out, err := exec.Command("/sbin/fsck.ext4", "-p", device).CombinedOutput()
	if err == nil {
		return nil
	}

	exitError, ok := err.(*exec.ExitError)
	if !ok || exitError.Sys().(syscall.WaitStatus).ExitStatus() == 4 {
		return fmt.Errorf(fmt.Sprintf("fsck.ext4 failed %s. %s %s", c.HostnameAlias), err,
			string(out))
	}

	out, err = exec.Command("/sbin/fsck.ext4", "-y", device).CombinedOutput()
	if err == nil {
		return nil
	}

	exitError, ok = err.(*exec.ExitError)
	if !ok || exitError.Sys().(syscall.WaitStatus).ExitStatus() != 1 {
		return fmt.Errorf(fmt.Sprintf("fsck.ext4 could not automatically repair FS for %s.",
			c.HostnameAlias), err, string(out))
	}

	return nil
}
