package virt

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"
)

func (vm *VM) createSnapshot() (string, error) {
	snapName := fmt.Sprintf("%d", time.Now().Unix())
	out, err := exec.Command("/usr/bin/rbd", "--pool", "vms", "snap", "create", "--snap", snapName, vm.String()).CombinedOutput()
	if err != nil {
		return "", commandError("", err, out)
	}
	return snapName, err
}

func (vm *VM) deleteSnapshot(targetSnapshot string) error {
	if targetSnapshot == "" {
		return errors.New("Target snapshot cannot be empty.")
	}
	return exec.Command("/usr/bin/rbd", "--pool", "vms", "snap", "rm", "vms/"+vm.String()+"@"+targetSnapshot).Run()
}

func (vm *VM) listOfSnapshots() ([]string, error) {
	out, err := exec.Command("/usr/bin/rbd", "--pool", "vms", "snap", "ls", vm.String()).CombinedOutput()
	result := []string{}
	if err != nil {
		return result, err
	}
	rawSnapsString := string(out)
	if rawSnapsString == "" {
		return result, nil
	}
	var rawSnapStringsArr []string = strings.Split(rawSnapsString, "\n")
	for _, s := range rawSnapStringsArr[1 : len(rawSnapStringsArr)-1] {
		result = append(result, strings.Fields(s)[1])
	}
	return result, nil
}

func (vm *VM) exportImageFromSnapshot(snapshot, pathToExport string) error {
	if err := os.MkdirAll(pathToExport, 0755); err != nil {
		if !os.IsExist(err) {
			return err
		}
	}
	err := exec.Command("/usr/bin/rbd", "--pool", "vms", "export", "--snap", snapshot, vm.String(), pathToExport+"/"+snapshot+".img").Run()
	return err
}

func (vm *VM) Backup() error {
	localPathToExport = fmt.Sprintf("/tmp/snapshot_exports/%s", vm.String())

	var exportSnapErr, deleteSnapErr error

	snapName, createSnapErr := vm.createSnapshot()
	if createSnapErr != nil {
		createSnapErr = commandError("Create snapshot: "+snapName+"failed for vm: "+vm.String()+".", createSnapErr, nil)
	} else {
		if exportSnapErr = vm.exportImageFromSnapshot(snapName, localPathToExport); exportSnapErr != nil {
			exportSnapErr = commandError(fmt.Sprintf("Exporting snapshot:%s failed for vm: "+vm.String()+".", snapName), exportSnapErr, nil)
		}
	}
	if deleteSnapErr = vm.deleteSnapshot(snapName); deleteSnapErr != nil {
		deleteSnapErr = commandError(fmt.Sprintf("Deleting snapshot:%s failed for vm: "+vm.String()+".", snapName), deleteSnapErr, nil)
	}
	return combineErrors(createSnapErr, exportSnapErr, deleteSnapErr)
}

func combineErrors(errArr ...error) error {
	result := ""
	for _, err := range errArr {
		if err != nil {
			result += err.Error() + "\n"
		}
	}
	if result == "" {
		return nil
	}
	return errors.New(result)
}
