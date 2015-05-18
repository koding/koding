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

	_, err = exec.Command("tar", "-cf", outputFileName, folderName).Output()
	return err
}

func untarFile(fileName, outputFolder string) error {
	isExist, err := exists(fileName)
	if err != nil {
		return err
	}

	if !isExist {
		return ErrFolderNotFound
	}

	_, err = exec.Command("tar", "-xf", fileName, "-C", outputFolder).Output()
	return err
}

func exists(name string) (bool, error) {
	var err error
	if _, err = os.Stat(name); os.IsNotExist(err) {
		return false, nil
	}

	return true, err
}
