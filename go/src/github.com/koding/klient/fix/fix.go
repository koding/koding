// Package fix is used to fix certain aspects of a User VM. To use it import it
// and call the Run() function
package fix

import (
	"errors"
	"fmt"
	"os/exec"
	"path/filepath"
	"runtime"
)

func Run(username string) error {
	if runtime.GOOS != "linux" {
		return errors.New("Fix is only supported for darwin")
	}

	replaceErr := replaceKey("root", DeployPublicKey)
	if err := replaceKey("ubuntu", DeployPublicKey); err != nil {
		replaceErr = err
	}

	return replaceErr
}

func replaceKey(username, key string) error {
	path := "/.ssh/authorized_keys"
	switch username {
	case "root":
		path = filepath.Join("/root", path)
	case "ubuntu":
		path = filepath.Join("/home/ubuntu", path)
	}

	// create path folder and the file if it doesn't exists
	createFile := fmt.Sprintf("mkdir -p %s && touch %s || exit", filepath.Dir(path), path)
	err := RunAsSudo(createFile)
	if err != nil {
		return err
	}

	overrideKey := fmt.Sprintf("echo '%s' > %s", key, path)
	if err := RunAsSudo(overrideKey); err != nil {
		return err
	}

	chmod := fmt.Sprintf("chmod 0600 %[1]s && chown -R %[2]s:%[2]s %[3]s", path, username, filepath.Dir(path))
	if err := RunAsSudo(chmod); err != nil {
		return err
	}

	return err
}

func RunAsSudo(cmd string) error {
	out, err := exec.Command("/usr/bin/sudo", "-i", "--", "/bin/bash", "-c", cmd).CombinedOutput()
	if err != nil {
		return fmt.Errorf("err: '%s': out: '%s'", err, string(out))
	}

	return nil
}

// RSA key pair we are going to override with. Keys are from
// github.com/koding/credential/private_keys/kloud
var (
	DeployPublicKey = `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwAxo9snzynloid3J1pif7obIYHqWcjr1Q2/QTHkjDP3sC/4wMhIGxBAs07YkaUEZ0je1cH9IIU07KbFsOg4Rx9MlOVouhJ8GsjxuYTSGs1WzeLJ4oGLrMIwipEK+RhiA8kEyGKyKGQLTbrbHSzXYF4S8lxJaitE7Vfg4yNZEb8x5G1Wysi/GewanvQDytn5UhOBUqVU4PTeVi/D1YeVrXKtol7hTNRtsw1aRUIGnqskEp4LkuQKCY71rcfbIkjfa/GsaF04/4My0+DBIZAYOkgghDA8ROZPFyvB75JDrJGVG/keh3DtX4sl/XjGjTvOBosRVesCK13RtDpEe6sYS0rtg1iCqv5bimxbKAqBqHJkOjPB7Xo+7I5k1dvVm49Ktq6hFHMzGA/2cnotIYE9KHeAjnnYdBxjygSb7f8pnV4FfFkJ9m42GdRXy+lYewEXHz99GT84ExdpuNrI1mDobDyRDPmBJqmvlq6U8mxwBz0pXjRbpYJxe4iyCkEqTbCK5T8YHSBp4OE201Fkub4Z/bOlhG0WTBq2otHxx61AcscH+cSPZHaDSi8ebUGwWM4E8E5Hu0DXuCP3+1tcvct9FQxpvMVHG2zo+jHTlxSkfzvzPhGjWJbFloEG0Ri2cJAkfO0q7H/i2aPPyC4Ez8brRz+eoNujGBVk+KZG2a4ITfEQ== hello@koding.com`
)
