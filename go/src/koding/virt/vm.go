package virt

import (
	"fmt"
	"io"
	"io/ioutil"
	"koding/db/models"
	"net"
	"os"
	"os/exec"
	"strconv"
	"syscall"
	"text/template"
	"time"

	"labix.org/v2/mgo/bson"
)

type VM models.VM
type Permissions models.Permissions

var VMPool string = "vms"
var templateDir string
var Templates = template.New("lxc")

func LoadTemplates(dir string) error {
	interf, err := net.InterfaceByName("lxcbr0")
	if err != nil {
		return err
	}
	addrs, err := interf.Addrs()
	if err != nil {
		return err
	}
	hostIP, _, err := net.ParseCIDR(addrs[0].String())
	if err != nil {
		return err
	}

	templateDir = dir
	Templates.Funcs(template.FuncMap{
		"hostIP": func() string {
			return hostIP.String()
		},
		"swapAccountingEnabled": func() bool {
			_, err := os.Stat("/sys/fs/cgroup/memory/memory.memsw.limit_in_bytes")
			return err == nil
		},
		"kernelMemoryAccountingEnabled": func() bool {
			_, err := os.Stat("/sys/fs/cgroup/memory/memory.kmem.limit_in_bytes")
			return err == nil
		},
	})
	if _, err := Templates.ParseGlob(templateDir + "/vm/*"); err != nil {
		return err
	}

	return nil
}

func VMName(vmId bson.ObjectId) string {
	return "vm-" + vmId.Hex()
}

func (v *VM) String() string {
	return VMName(v.Id)
}

func (v *VM) VEth() string {
	return fmt.Sprintf("veth-%x", []byte(v.IP[12:16]))
}

func (v *VM) MAC() net.HardwareAddr {
	return net.HardwareAddr([]byte{0, 0, v.IP[12], v.IP[13], v.IP[14], v.IP[15]})
}

func (v *VM) RbdDevice() string {
	return "/dev/rbd/" + VMPool + "/" + v.String()
}

func (v *VM) File(p string) string {
	return fmt.Sprintf("/var/lib/lxc/%s/%s", v, p)
}

func (v *VM) OverlayFile(p string) string {
	return v.File("overlay/" + p)
}

func (v *VM) LowerdirFile(p string) string {
	return v.VMRoot + "rootfs/" + p
}

func (v *VM) PtsDir() string {
	return v.File("rootfs/dev/pts")
}

func (v *VM) GetPermissions(user *User) *Permissions {
	for _, entry := range v.Users {
		if entry.Id == user.ObjectId {
			p := Permissions(entry)
			return &p
		}
	}
	return nil
}

func (v *VM) ApplyDefaults() {
	if v.NumCPUs == 0 {
		v.NumCPUs = 1
	}

	if v.MaxMemoryInMB == 0 {
		v.MaxMemoryInMB = 1024
	}

	if v.DiskSizeInMB == 0 {
		v.DiskSizeInMB = 1200
	}

	if v.VMRoot == "" {
		v.VMRoot = "/var/lib/lxc/vmroot/"
	}
}

// Prepare creates and initialized the container to be started later directly
// with lxc.start. We don't use lxc.create (which uses shell scipts for
// templating), instead of we use this method which basically let us do things
// more efficient. It creates the home directory, generates files like lxc.conf
// and mounts the necessary filesystems.
func (v *VM) Prepare(reinitialize bool, logWarning func(string, ...interface{})) {
	// first unprepare to not conflict with everything else
	v.Unprepare()

	// create our lxc container dir
	v.createContainerDir()

	// map rbd image to block device
	v.mountRBD()

	// remove all except /home on reinitialize
	if reinitialize {
		v.reinitialize()
	}

	v.createOverlay()
	v.mergeFiles(logWarning)
	v.mountAufs()
	v.prepareAndMountPts()
	v.addEbtablesRule()
	v.addStaticRoute()
}

func (v *VM) createContainerDir() {
	// write LXC files
	prepareDir(v.File(""), 0)
	v.generateFile(v.File("config"), "config", 0, false)
	v.generateFile(v.File("fstab"), "fstab", 0, false)
	v.generateFile(v.File("ip-address"), "ip-address", 0, false)
}

func (v *VM) mountRBD() {
	if err := v.MountRBD(v.OverlayFile("")); err != nil {
		panic(err)
	}
}

func (v *VM) reinitialize() {
	entries, err := ioutil.ReadDir(v.OverlayFile("/"))
	if err != nil {
		panic(err)
	}
	for _, entry := range entries {
		if entry.Name() != "home" {
			os.RemoveAll(v.OverlayFile("/" + entry.Name()))
		}
	}
}

func (v *VM) createOverlay() {
	// prepare overlay
	prepareDir(v.OverlayFile("/"), RootIdOffset)           // for chown
	prepareDir(v.OverlayFile("/lost+found"), RootIdOffset) // for chown
	prepareDir(v.OverlayFile("/etc"), RootIdOffset)

	v.generateFile(v.OverlayFile("/etc/hostname"), "hostname", RootIdOffset, false)
	v.generateFile(v.OverlayFile("/etc/hosts"), "hosts", RootIdOffset, false)
	v.generateFile(v.OverlayFile("/etc/ldap.conf"), "ldap.conf", RootIdOffset, false)
}

func (v *VM) mergeFiles(logWarning func(string, ...interface{})) {
	v.MergePasswdFile(logWarning)
	v.MergeGroupFile(logWarning)
	v.MergeDpkgDatabase()
}

func (v *VM) mountAufs() {
	// mount "/var/lib/lxc/vm-{id}/overlay" (rw) and "/var/lib/lxc/vmroot" (ro)
	// under "/var/lib/lxc/vm-{id}/rootfs"
	prepareDir(v.File("rootfs"), RootIdOffset)
	// if out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "overlayfs", "-o", fmt.Sprintf("lowerdir=%s,upperdir=%s", v.LowerdirFile("/"), v.OverlayFile("/")), "overlayfs", v.File("rootfs")).CombinedOutput(); err != nil {
	if out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "aufs", "-o", fmt.Sprintf("noplink,br=%s:%s", v.OverlayFile("/"), v.LowerdirFile("/")), "aufs", v.File("rootfs")).CombinedOutput(); err != nil {
		panic(commandError("mount overlay failed.", err, out))
	}
}

func (v *VM) prepareAndMountPts() {
	// mount devpts
	prepareDir(v.PtsDir(), RootIdOffset)
	if out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "devpts", "-o", "rw,noexec,nosuid,newinstance,gid="+strconv.Itoa(RootIdOffset+5)+",mode=0620,ptmxmode=0666", "devpts", v.PtsDir()).CombinedOutput(); err != nil {
		panic(commandError("mount devpts failed.", err, out))
	}
	chown(v.PtsDir(), RootIdOffset, RootIdOffset)
	chown(v.PtsDir()+"/ptmx", RootIdOffset, RootIdOffset)

	if v.IP == nil {
		if ip, err := ioutil.ReadFile(v.File("ip-address")); err == nil {
			v.IP = net.ParseIP(string(ip))
		}
	}
}

// addEbtablesRule adds entries to restrict IP and MAC
func (v *VM) addEbtablesRule() {
	if out, err := exec.Command("/sbin/ebtables", "--append", "VMS", "--protocol", "IPv4", "--source", v.MAC().String(), "--ip-src", v.IP.String(), "--in-interface", v.VEth(), "--jump", "ACCEPT").CombinedOutput(); err != nil {
		panic(commandError("ebtables rule addition failed.", err, out))
	}
}

func (v *VM) addStaticRoute() {
	if out, err := exec.Command("/sbin/route", "add", v.IP.String(), "lxcbr0").CombinedOutput(); err != nil {
		panic(commandError("adding route failed.", err, out))
	}
}

func UnprepareVM(id bson.ObjectId) error {
	vm := VM{Id: id}
	return vm.Unprepare()
}

func (vm *VM) Unprepare() error {
	var firstError error

	// stop VM
	if err := vm.Shutdown(); err != nil {
		panic(err)
	}

	// backup dpkg database for statistical purposes
	os.Mkdir("/var/lib/lxc/dpkg-statuses", 0755)
	copyFile(vm.OverlayFile("/var/lib/dpkg/status"), "/var/lib/lxc/dpkg-statuses/"+vm.String(), RootIdOffset)
	if vm.IP != nil {
		// remove ebtables entry
		if out, err := exec.Command("/sbin/ebtables", "--delete", "VMS", "--protocol", "IPv4", "--source", vm.MAC().String(), "--ip-src", vm.IP.String(), "--in-interface", vm.VEth(), "--jump", "ACCEPT").CombinedOutput(); err != nil && firstError == nil {
			firstError = commandError("ebtables rule deletion failed.", err, out)
		}

		// remove the static route so it is no longer redistribed by BGP
		if out, err := exec.Command("/sbin/route", "del", vm.IP.String(), "lxcbr0").CombinedOutput(); err != nil {
			firstError = commandError("Removing route failed.", err, out)
		}
	}

	// unmount and unmap everything
	if out, err := exec.Command("/bin/umount", vm.PtsDir()).CombinedOutput(); err != nil && firstError == nil {
		firstError = commandError("umount devpts failed.", err, out)
	}
	//Flush the aufs
	if out, err := exec.Command("/sbin/auplink", vm.File("rootfs"), "flush").CombinedOutput(); err != nil && firstError == nil {
		firstError = commandError("AUFS flush failed.", err, out)
	}
	if out, err := exec.Command("/bin/umount", vm.File("rootfs")).CombinedOutput(); err != nil && firstError == nil {
		firstError = commandError("umount overlay failed.", err, out)
	}
	if err := vm.UnmountRBD(vm.OverlayFile("")); err != nil && firstError == nil {
		firstError = err
	}

	// remove VM directory
	os.Remove(vm.File("config"))
	os.Remove(vm.File("fstab"))
	os.Remove(vm.File("ip-address"))
	os.Remove(vm.File("rootfs"))
	os.Remove(vm.File("rootfs.hold"))
	os.Remove(vm.File(""))

	return firstError
}

func (vm *VM) MountRBD(mountDir string) error {
	makeFileSystem := false

	// create image if it does not exist
	if out, err := exec.Command("/usr/bin/rbd", "info", "--pool", VMPool, "--image", vm.String()).CombinedOutput(); err != nil {
		exitError, isExitError := err.(*exec.ExitError)
		if !isExitError || exitError.Sys().(syscall.WaitStatus).ExitStatus() > 2 {
			return commandError("rbd info failed.", err, out)
		}

		if vm.SnapshotName == "" {
			if out, err := exec.Command("/usr/bin/rbd", "create", "--pool", VMPool, "--size", strconv.Itoa(vm.DiskSizeInMB), "--image", vm.String(), "--image-format", "1").CombinedOutput(); err != nil {
				return commandError("rbd create failed.", err, out)
			}
		}
		if vm.SnapshotName != "" {
			if out, err := exec.Command("/usr/bin/rbd", "clone", "--pool", VMPool, "--image", VMName(vm.SnapshotVM), "--snap", vm.SnapshotName, "--dest-pool", VMPool, "--dest", vm.String()).CombinedOutput(); err != nil {
				return commandError("rbd clone failed.", err, out)
			}
		}

		makeFileSystem = true
	}

	// map image
	if out, err := exec.Command("/usr/bin/rbd", "map", "--pool", VMPool, "--image", vm.String()).CombinedOutput(); err != nil {
		return commandError("rbd map failed.", err, out)
	}

	// wait for rbd device to appear
	for {
		_, err := os.Stat(vm.RbdDevice())
		if err == nil {
			break
		}
		if !os.IsNotExist(err) {
			return err
		}
		time.Sleep(time.Second / 2)
	}

	if makeFileSystem {
		if out, err := exec.Command("/sbin/mkfs.ext4", vm.RbdDevice()).CombinedOutput(); err != nil {
			return commandError("mkfs.ext4 failed.", err, out)
		}
	}

	// check/correct filesystem
	if out, err := exec.Command("/sbin/fsck.ext4", "-p", vm.RbdDevice()).CombinedOutput(); err != nil {
		exitError, ok := err.(*exec.ExitError)
		if !ok || exitError.Sys().(syscall.WaitStatus).ExitStatus() == 4 {
			if out, err := exec.Command("/sbin/fsck.ext4", "-y", vm.RbdDevice()).CombinedOutput(); err != nil {
				exitError, ok := err.(*exec.ExitError)
				if !ok || exitError.Sys().(syscall.WaitStatus).ExitStatus() != 1 {
					return commandError(fmt.Sprintf("fsck.ext4 could not automatically repair FS for %s.", vm.HostnameAlias), err, out)
				}
			}
		} else {
			return commandError(fmt.Sprintf("fsck.ext4 failed %s.", vm.HostnameAlias), err, out)
		}
	}

	if err := os.Mkdir(mountDir, 0755); err != nil && !os.IsExist(err) {
		return err
	}
	if out, err := exec.Command("/bin/mount", "-t", "ext4", vm.RbdDevice(), mountDir).CombinedOutput(); err != nil {
		os.Remove(mountDir)
		return commandError("mount rbd failed.", err, out)
	}

	return nil
}

func (vm *VM) UnmountRBD(mountDir string) error {
	var firstError error
	if out, err := exec.Command("/bin/umount", vm.OverlayFile("")).CombinedOutput(); err != nil && firstError == nil {
		firstError = commandError("umount rbd failed.", err, out)
	}
	if out, err := exec.Command("/usr/bin/rbd", "unmap", vm.RbdDevice()).CombinedOutput(); err != nil && firstError == nil {
		firstError = commandError("rbd unmap failed.", err, out)
	}
	os.Remove(mountDir)
	return firstError
}

func (vm *VM) ResizeRBD() error {
	if out, err := exec.Command("/usr/bin/rbd", "resize", "--pool", VMPool, "--image", vm.String(), "--size", strconv.Itoa(vm.DiskSizeInMB)).CombinedOutput(); err != nil {
		return commandError("rbd resize failed.", err, out)
	}

	if out, err := exec.Command("/sbin/resize2fs", vm.RbdDevice()).CombinedOutput(); err != nil {
		return commandError("resize2fs failed.", err, out)
	}

	if out, err := exec.Command("/bin/mount", "-o", "remount", vm.OverlayFile("")).CombinedOutput(); err != nil {
		return commandError("remount failed.", err, out)
	}

	return nil
}

const FIFREEZE = 0xC0045877
const FITHAW = 0xC0045878

func (vm *VM) FreezeFileSystem() error {
	return vm.controlOverlay(FIFREEZE)
}

func (vm *VM) ThawFileSystem() error {
	return vm.controlOverlay(FITHAW)
}

func (vm *VM) controlOverlay(action uintptr) error {
	fd, err := os.Open(vm.OverlayFile(""))
	if err != nil {
		return err
	}
	defer fd.Close()
	if _, _, errno := syscall.Syscall(syscall.SYS_IOCTL, fd.Fd(), action, 0); errno != 0 {
		return errno
	}
	return nil
}

func (vm *VM) CreateConsistentSnapshot(snapshotName string) error {
	if err := vm.FreezeFileSystem(); err != nil {
		return err
	}
	defer vm.ThawFileSystem()
	if out, err := exec.Command("/usr/bin/rbd", "snap", "create", "--pool", VMPool, "--image", vm.String(), "--snap", snapshotName).CombinedOutput(); err != nil {
		return commandError("Creating snapshot failed.", err, out)
	}
	if out, err := exec.Command("/usr/bin/rbd", "snap", "protect", "--pool", VMPool, "--image", vm.String(), "--snap", snapshotName).CombinedOutput(); err != nil {
		return commandError("Protecting snapshot failed.", err, out)
	}
	return nil
}

func (vm *VM) DeleteSnapshot(snapshotName string) error {
	if out, err := exec.Command("/usr/bin/rbd", "snap", "unprotect", "--pool", VMPool, "--image", vm.String(), "--snap", snapshotName).CombinedOutput(); err != nil {
		return commandError("Unprotecting snapshot failed.", err, out)
	}
	if out, err := exec.Command("/usr/bin/rbd", "snap", "rm", "--pool", VMPool, "--image", vm.String(), "--snap", snapshotName).CombinedOutput(); err != nil {
		return commandError("Removing snapshot failed.", err, out)
	}
	return nil
}

func DestroyVM(id bson.ObjectId) error {
	if out, err := exec.Command("/usr/bin/rbd", "rm", "--pool", VMPool, "--image", VMName(id)).CombinedOutput(); err != nil {
		return commandError("Removing image failed.", err, out)
	}
	return nil
}

func commandError(message string, err error, out []byte) error {
	return fmt.Errorf("%s\n%s\n%s", message, err.Error(), string(out))
}

// may panic
func prepareDir(p string, id int) {
	if err := os.Mkdir(p, 0755); err != nil && !os.IsExist(err) {
		panic(err)
	}
	chown(p, id, id)
}

// may panic
func (vm *VM) generateFile(p, template string, id int, executable bool) {
	var mode os.FileMode = 0644
	if executable {
		mode = 0755
	}
	file, err := os.OpenFile(p, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, mode)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	if err := Templates.ExecuteTemplate(file, template, vm); err != nil {
		panic(err)
	}

	if err := file.Chown(id, id); err != nil {
		panic(err)
	}
	if err := file.Chmod(mode); err != nil {
		panic(err)
	}
}

// may panic
func chown(p string, uid, gid int) {
	if err := os.Chown(p, uid, gid); err != nil {
		panic(err)
	}
}

func copyFile(src, dst string, id int) error {
	sf, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sf.Close()

	fi, err := sf.Stat()
	if err != nil {
		return err
	}

	df, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, fi.Mode())
	if err != nil {
		return err
	}
	defer df.Close()

	if _, err := io.Copy(df, sf); err != nil {
		return err
	}

	if err := df.Chown(id, id); err != nil {
		return err
	}

	return nil
}
