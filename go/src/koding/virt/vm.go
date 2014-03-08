package virt

import (
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
	"koding/db/models"
	"net"
	"os"
	"os/exec"
	"strconv"
	"strings"
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

func (vm *VM) String() string {
	return VMName(vm.Id)
}

func (vm *VM) VEth() string {
	return fmt.Sprintf("veth-%x", []byte(vm.IP[12:16]))
}

func (vm *VM) MAC() net.HardwareAddr {
	return net.HardwareAddr([]byte{0, 0, vm.IP[12], vm.IP[13], vm.IP[14], vm.IP[15]})
}

func (vm *VM) RbdDevice() string {
	return "/dev/rbd/" + VMPool + "/" + vm.String()
}

func (vm *VM) File(p string) string {
	return fmt.Sprintf("/var/lib/lxc/%s/%s", vm, p)
}

func (vm *VM) OverlayFile(p string) string {
	return vm.File("overlay/" + p)
}

func (vm *VM) LowerdirFile(p string) string {
	return vm.VMRoot + "rootfs/" + p
}

func (vm *VM) PtsDir() string {
	return vm.File("rootfs/dev/pts")
}

func (vm *VM) GetPermissions(user *User) *Permissions {
	for _, entry := range vm.Users {
		if entry.Id == user.ObjectId {
			p := Permissions(entry)
			return &p
		}
	}
	return nil
}

func (vm *VM) GetGroupPermissions(groupdId bson.ObjectId) *Permissions {
	for _, entry := range vm.Groups {
		if entry.Id == groupdId {
			p := Permissions(entry)
			return &p
		}
	}
	return nil
}

func (vm *VM) ApplyDefaults() {
	if vm.NumCPUs == 0 {
		vm.NumCPUs = 1
	}

	if vm.MaxMemoryInMB == 0 {
		vm.MaxMemoryInMB = 1024
	}

	if vm.DiskSizeInMB == 0 {
		vm.DiskSizeInMB = 3072
	}

	if vm.VMRoot == "" {
		vm.VMRoot = "/var/lib/lxc/vmroot/"
	}
}

type Step struct {
	Message     string  `json:"message"`
	CurrentStep int     `json:"currentStep"`
	TotalStep   int     `json:"totalStep"`
	Err         error   `json:"error"`
	ElapsedTime float64 `json:"elapsedTime"` // time.Duration.Seconds()
}

type StepFunc struct {
	Fn  func() error
	Msg string
}

// Prepare creates and initialized the container to be started later directly
// with lxc.start. We don't use lxc.create (which uses shell scipts for
// templating), instead of we use this method which basically let us do things
// more efficient. It creates the home directory, generates files like lxc.conf
// and mounts the necessary filesystems.
func (v *VM) Prepare(reinitialize bool) <-chan *Step {
	funcs := make([]*StepFunc, 0)
	funcs = append(funcs, &StepFunc{Msg: "Create container", Fn: v.createContainerDir})
	funcs = append(funcs, &StepFunc{Msg: "Mount RBD", Fn: v.mountRBD})

	// remove all except /home on reinitialize
	if reinitialize {
		funcs = append(funcs, &StepFunc{Msg: "Reinitialize", Fn: v.reinitialize})
	}

	funcs = append(funcs, &StepFunc{Msg: "Create overlay", Fn: v.createOverlay})
	funcs = append(funcs, &StepFunc{Msg: "Merging old files", Fn: v.mergeFiles})
	funcs = append(funcs, &StepFunc{Msg: "Mount AUF", Fn: v.mountAufs})
	funcs = append(funcs, &StepFunc{Msg: "Mount PTS", Fn: v.prepareAndMountPts})
	funcs = append(funcs, &StepFunc{Msg: "Add Ebtables rules", Fn: v.addEbtablesRule})
	funcs = append(funcs, &StepFunc{Msg: "Add Static route", Fn: v.addStaticRoute})

	results := make(chan *Step, len(funcs))

	// create the functions one by one and pass back the results via a
	// channel. The channel will be closed if an error results.
	go func() {
		defer func() {
			close(results)
			results = nil
		}()

		for step, current := range funcs {
			start := time.Now()
			err := current.Fn() // invoke our function

			results <- &Step{
				Message:     current.Msg,
				CurrentStep: step + 1,
				TotalStep:   len(funcs),
				ElapsedTime: time.Since(start).Seconds(),
				Err:         err,
			}

			if err != nil {
				// don't put the prepare in an unknown state
				for _ = range v.Unprepare() {
				}
				break
			}
		}

	}()

	return results
}

func (v *VM) createContainerDir() error {
	// write LXC files
	prepareDir(v.File(""), 0)

	if err := v.generateFile(v.File("config"), "config", 0, false); err != nil {
		return err
	}

	if err := v.generateFile(v.File("fstab"), "fstab", 0, false); err != nil {
		return err
	}

	if err := v.generateFile(v.File("ip-address"), "ip-address", 0, false); err != nil {
		return err
	}

	return nil
}

func (v *VM) mountRBD() error {
	if err := v.MountRBD(v.OverlayFile("")); err != nil {
		return err
	}
	return nil
}

func (v *VM) reinitialize() error {
	entries, err := ioutil.ReadDir(v.OverlayFile("/"))
	if err != nil {
		return err
	}

	for _, entry := range entries {
		if entry.Name() != "home" {
			os.RemoveAll(v.OverlayFile("/" + entry.Name()))
		}
	}

	return nil
}

func (v *VM) createOverlay() error {
	// prepare overlay
	prepareDir(v.OverlayFile("/"), RootIdOffset)           // for chown
	prepareDir(v.OverlayFile("/lost+found"), RootIdOffset) // for chown
	prepareDir(v.OverlayFile("/etc"), RootIdOffset)

	if err := v.generateFile(v.OverlayFile("/etc/hostname"), "hostname", RootIdOffset, false); err != nil {
		return err
	}

	if err := v.generateFile(v.OverlayFile("/etc/hosts"), "hosts", RootIdOffset, false); err != nil {
		return err
	}

	if err := v.generateFile(v.OverlayFile("/etc/ldap.conf"), "ldap.conf", RootIdOffset, false); err != nil {
		return err
	}

	return nil
}

func (v *VM) mergeFiles() error {
	v.MergePasswdFile()
	v.MergeGroupFile()

	return nil
}

func (v *VM) mountAufs() error {
	// mount "/var/lib/lxc/vm-{id}/overlay" (rw) and "/var/lib/lxc/vmroot" (ro)
	// under "/var/lib/lxc/vm-{id}/rootfs"
	prepareDir(v.File("rootfs"), RootIdOffset)
	// if out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "overlayfs", "-o", fmt.Sprintf("lowerdir=%s,upperdir=%s", v.LowerdirFile("/"), v.OverlayFile("/")), "overlayfs", v.File("rootfs")).CombinedOutput(); err != nil {
	if out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "aufs", "-o",
		fmt.Sprintf("noplink,br=%s:%s", v.OverlayFile("/"), v.LowerdirFile("/")), "aufs",
		v.File("rootfs")).CombinedOutput(); err != nil {
		return commandError("mount overlay failed.", err, out)
	}

	return nil
}

func (v *VM) prepareAndMountPts() error {
	// mount devpts
	prepareDir(v.PtsDir(), RootIdOffset)
	if out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "devpts", "-o",
		"rw,noexec,nosuid,newinstance,gid="+strconv.Itoa(RootIdOffset+5)+",mode=0620,ptmxmode=0666",
		"devpts", v.PtsDir()).CombinedOutput(); err != nil {
		return commandError("mount devpts failed.", err, out)
	}

	chown(v.PtsDir(), RootIdOffset, RootIdOffset)
	chown(v.PtsDir()+"/ptmx", RootIdOffset, RootIdOffset)

	if v.IP == nil {
		if ip, err := ioutil.ReadFile(v.File("ip-address")); err == nil {
			v.IP = net.ParseIP(string(ip))
		}
	}

	return nil
}

// addEbtablesRule adds entries to restrict IP and MAC
func (v *VM) addEbtablesRule() error {
	if out, err := exec.Command("/sbin/ebtables", "--append", "VMS", "--protocol",
		"IPv4", "--source", v.MAC().String(), "--ip-src", v.IP.String(),
		"--in-interface", v.VEth(), "--jump", "ACCEPT").CombinedOutput(); err != nil {
		return commandError("ebtables rule addition failed.", err, out)
	}
	return nil
}

func (v *VM) addStaticRoute() error {
	if out, err := exec.Command("/sbin/route", "add", v.IP.String(), "lxcbr0").CombinedOutput(); err != nil {
		return commandError("adding route failed.", err, out)
	}
	return nil
}

func UnprepareVM(id bson.ObjectId) error {
	vm := VM{Id: id}

	if err := vm.Shutdown(); err != nil {
		return err
	}

	var err error
	for step := range vm.Unprepare() {
		err = step.Err
	}
	return err
}

// Unprepare is basically the inverse of Prepare. We don't use lxc.destroy
// (which purges the container immediately). Instead we use this method which
// basically let us umount previously mounted disks, remove generated files,
// etc. It doesn't remove the home folder or any newly created system files.
// Those files will be stored in the vmroot.
// Unprepare also doesn't return on errors, instead it silently fails and
// tries to execute the next step until all steps are done.
func (vm *VM) Unprepare() <-chan *Step {
	funcs := make([]*StepFunc, 0)
	funcs = append(funcs, &StepFunc{Msg: "Removing network rules", Fn: vm.removeNetworkRules})
	funcs = append(funcs, &StepFunc{Msg: "Umount PTS", Fn: vm.umountPts})
	funcs = append(funcs, &StepFunc{Msg: "Umount AUFS", Fn: vm.umountAufs})
	funcs = append(funcs, &StepFunc{Msg: "Umount RBD", Fn: vm.umountRBD})
	funcs = append(funcs, &StepFunc{Msg: "Removing lxc/config", Fn: func() error { return os.Remove(vm.File("config")) }})
	funcs = append(funcs, &StepFunc{Msg: "Removing lxc/fstab", Fn: func() error { return os.Remove(vm.File("fstab")) }})
	funcs = append(funcs, &StepFunc{Msg: "Removing lxc/ip-config", Fn: func() error { return os.Remove(vm.File("ip-address")) }})
	funcs = append(funcs, &StepFunc{Msg: "Removing lxc/rootfs", Fn: func() error { return os.Remove(vm.File("rootfs")) }})
	funcs = append(funcs, &StepFunc{Msg: "Removing lxc/rootfs.hold", Fn: func() error { return os.Remove(vm.File("rootfs.hold")) }})
	funcs = append(funcs, &StepFunc{Msg: "Removing lxc folder", Fn: func() error { return os.Remove(vm.File("")) }})

	var lastError error
	results := make(chan *Step, len(funcs))

	// create the functions one by one and pass back the results via a
	// channel. The channel will be closed if an error results.
	go func() {
		defer func() {
			close(results)
			results = nil
		}()

		for step, current := range funcs {
			start := time.Now()
			err := current.Fn() // invoke our function

			if err != nil {
				lastError = err
			}

			results <- &Step{
				Message:     current.Msg,
				CurrentStep: step + 1,
				TotalStep:   len(funcs),
				ElapsedTime: time.Since(start).Seconds(),
				Err:         lastError,
			}

		}
	}()

	return results
}

func (vm *VM) removeNetworkRules() error {
	var lastError error

	if vm.IP == nil {
		if ip, err := ioutil.ReadFile(vm.File("ip-address")); err == nil {
			vm.IP = net.ParseIP(string(ip))
		}
	}

	if vm.IP != nil {
		// remove ebtables entry
		if out, err := exec.Command("/sbin/ebtables", "--delete", "VMS", "--protocol", "IPv4",
			"--source", vm.MAC().String(), "--ip-src", vm.IP.String(), "--in-interface", vm.VEth(),
			"--jump", "ACCEPT").CombinedOutput(); err != nil {
			lastError = commandError("ebtables rule deletion failed.", err, out)
		}

		// remove the static route so it is no longer redistribed by BGP
		if out, err := exec.Command("/sbin/route", "del", vm.IP.String(), "lxcbr0").CombinedOutput(); err != nil {
			lastError = commandError("Removing route failed.", err, out)
		}
	}

	return lastError
}

func (vm *VM) umountPts() error {
	// unmount and unmap everything
	if out, err := exec.Command("/bin/umount", vm.PtsDir()).CombinedOutput(); err != nil {
		return commandError("umount devpts failed.", err, out)
	}
	return nil
}

func (vm *VM) umountAufs() error {
	var lastError error

	//Flush the aufs
	if out, err := exec.Command("/sbin/auplink", vm.File("rootfs"), "flush").CombinedOutput(); err != nil {
		lastError = commandError("AUFS flush failed.", err, out)
	}

	if out, err := exec.Command("/bin/umount", vm.File("rootfs")).CombinedOutput(); err != nil && lastError == nil {
		lastError = commandError("umount overlay failed.", err, out)
	}

	return lastError
}

func (vm *VM) umountRBD() error {
	if err := vm.UnmountRBD(vm.OverlayFile("")); err != nil {
		return err
	}

	return nil
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

// LockRBD is locking the specific image. The lock is propogated to the whole
// cluster. Trying to lock a locked image returns an error.
func (vm *VM) LockRBD() error {
	// lock-id is going to be the VM-Hex ID to find it easily.
	lockID := vm.String()

	arg := []string{"lock", "add", "--pool", VMPool, "--image", vm.String(), lockID}
	if out, err := exec.Command("/usr/bin/rbd", arg...).CombinedOutput(); err != nil {
		return commandError("rbd lock failed.", err, out)
	}

	return nil
}

// getLockerRBD returns the locker id for the given VM. This is needed in
// order unlock a lock.
func (vm *VM) getLockerRBD() (locker string, err error) {
	arg := []string{"lock", "list", "--pool", VMPool, "--image", vm.String()}

	out, err := exec.Command("/usr/bin/rbd", arg...).CombinedOutput()
	if err != nil {
		return "", commandError("rbd lock failed.", err, out)
	}

	shellOut := string(bytes.TrimSpace(out))
	if shellOut == "" {
		return "", errors.New("no lock available")
	}

	lines := strings.Split(shellOut, "\n")
	for _, line := range lines {
		if !strings.HasPrefix(line, "client.") {
			continue
		}

		lockInfo := strings.Split(line, " ")
		if len(lockInfo) != 3 {
			continue
		}

		// returns something like client.123456
		return lockInfo[0], nil
	}

	return "", fmt.Errorf("could not find locker from output: %s\n", string(out))
}

// Unlock unlocks the given image. Trying to unlock on an image without a lock returns an error.
func (vm *VM) UnlockRBD() error {
	// lock-id is going to be the VM-Hex ID to find it easily.
	lockID := vm.String()
	locker, err := vm.getLockerRBD()
	if err != nil {
		return err
	}

	arg := []string{"lock", "rm", "--pool", VMPool, "--image", vm.String(), lockID, locker}
	if out, err := exec.Command("/usr/bin/rbd", arg...).CombinedOutput(); err != nil {
		return commandError("rbd lock failed.", err, out)
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

func (vm *VM) generateFile(p, template string, id int, executable bool) error {
	var mode os.FileMode = 0644
	if executable {
		mode = 0755
	}

	file, err := os.OpenFile(p, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, mode)
	if err != nil {
		return err
	}
	defer file.Close()

	if err := Templates.ExecuteTemplate(file, template, vm); err != nil {
		return err
	}

	if err := file.Chown(id, id); err != nil {
		return err
	}
	if err := file.Chmod(mode); err != nil {
		return err
	}

	return nil
}

// may panic
func chown(p string, uid, gid int) {
	if err := os.Chown(p, uid, gid); err != nil {
		panic(err)
	}
}
