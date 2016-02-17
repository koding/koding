package main

import (
	"fmt"

	"github.com/codegangsta/cli"
	"github.com/koding/kite"
	"koding/klient/remote/req"
)

// UnmountCommand unmounts a previously mounted folder by machine name.
func UnmountCommand(c *cli.Context) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "unmount")
		return 1
	}

	var name = c.Args().First()

	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		log.Errorf("Error creating klient client. err:%s", err)
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(GenericInternalError))
		return 1
	}

	if err := k.Dial(); err != nil {
		log.Errorf("Error dialing klient client. err:%s", err)
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(GenericInternalError))
		return 1
	}

	infos, err := getListOfMachines(k)
	if err != nil {
		log.Errorf("Failed to get list of machines on mount. err:%s", err)
		// Using internal error here, because a list error would be confusing to the
		// user.
		fmt.Println(GenericInternalError)
		return 1
	}

	info, ok := getMachineFromName(infos, name)
	if ok && len(info.MountedPaths) > 0 {
		name = info.VMName
		if err := Unlock(info.MountedPaths[0]); err != nil {
			fmt.Printf("Warning: unlocking failed: %s", err)
		}
	}

	// unmount using mount name
	if err := unmount(k, name, ""); err != nil {
		log.Errorf("Error unmounting. err:%s", err)
		fmt.Print(defaultHealthChecker.CheckAllFailureOrMessagef(FailedToUnmount))
		return 1
	}

	fmt.Println("Unmount success.")

	return 0
}

func unmount(kite *kite.Client, name, path string) error {
	if err := Unlock(path); err != nil {
		log.Warningf("Failed to unlock mount. err:%s", err)
		fmt.Println(FailedToUnlockMount)
	}

	req := req.UnmountFolder{
		Name:      name,
		LocalPath: path,
	}

	// currently there's no return response to care about
	_, err := kite.Tell("remote.unmountFolder", req)
	return err
}
