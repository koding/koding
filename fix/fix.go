package fix

import (
	"errors"
	"fmt"
	"os/exec"
	"path/filepath"
)

func Run(username string) error {
	replaceErr := replaceKey("root", DeployPublicKey)
	if err := replaceKey("ubuntu", DeployPublicKey); err != nil {
		replaceErr = err
	}

	fmt.Printf("replaceErr = %+v\n", replaceErr)
	return errors.New("not implemented yet")
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
	err := runAsSudo(createFile)
	if err != nil {
		return err
	}

	overrideKey := fmt.Sprintf("echo '%s' > %s", key, path)
	if err := runAsSudo(overrideKey); err != nil {
		return err
	}

	chmod := fmt.Sprintf("chmod 0600 %[1]s && chown -R %[2]s:%[2]s %[3]s", path, username, filepath.Dir(path))
	if err := runAsSudo(chmod); err != nil {
		return err
	}

	return err
}

func runAsSudo(cmd string) error {
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

	DeployPrivateKey = `-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----`
)
