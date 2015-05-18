package gather

import (
	"os"
	"os/exec"
)

func tarFolder(folderName, outputFileName string) error {
	isExist, err := exists(folderName)
	if err != nil {
		return err
	}

	if !isExist {
		return ErrFolderNotFound
	}

	_, err = exec.Command("tar", "-cvf", outputFileName, folderName).Output()
	return err
}

func exists(name string) (bool, error) {
	var err error
	if _, err = os.Stat(name); os.IsNotExist(err) {
		return false, nil
	}

	return true, err
}

func createFolder(folderName string) error {
	return os.Mkdir(folderName, 0777)
}
