package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"koding/kite/kd/build"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

type pkg struct {
	importPath string
	files      []string
	version    string
}

func main() {
	err := buildPackages()
	if err != nil {
		log.Println(err)
	}
}

func buildPackages() error {
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	kontrolproxy := pkg{
		importPath: "koding/kontrol/kontrolproxy",
		files: []string{
			filepath.Join(gopath, "src", "koding/kontrol/kontrolproxy/files"),
		},
		version: "0.0.1",
	}

	return kontrolproxy.build()
}

func (p *pkg) build() error {
	fmt.Printf("building package: '%s'\n", p.importPath)

	// prepare config folder
	tempDir, err := ioutil.TempDir(".", "gopackage_")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tempDir)

	configDir := filepath.Join(tempDir, "config")
	os.MkdirAll(configDir, 0755)

	profiles := []string{
		"vagrant",
		"staging",
		"sjc-production",
	}

	err = ioutil.WriteFile("VERSION", []byte(p.version), 0755)
	if err != nil {
		return err
	}
	defer os.Remove("VERSION")

	for _, profile := range profiles {
		config, err := exec.Command("node", "-e", "require('koding-config-manager').printJson('main."+profile+"')").CombinedOutput()
		if err != nil {
			return err
		}

		configFile := filepath.Join(configDir, fmt.Sprintf("main.%s.json", profile))
		err = ioutil.WriteFile(configFile, config, 0755)
		if err != nil {
			return err
		}

	}

	// include config dir too
	p.files = append(p.files, configDir)

	b := build.NewBuild()
	b.ImportPath = p.importPath
	b.Files = strings.Join(p.files, ",")

	// initializes b.AppName
	err = b.InitializeAppName()
	if err != nil {
		return err
	}

	b.Output = fmt.Sprintf("%s-%s.%s-%s", b.AppName, b.Version, runtime.GOOS, runtime.GOARCH)

	if runtime.GOOS == "linux" {
		debfile, err := b.Linux()
		if err != nil {
			return err
		}

		fmt.Println("package  :", debfile, "ready")
	} else {
		fmt.Println("linux build is disabled. Run on a linux machine.")
	}

	tarFile, err := b.TarGzFile()
	if err != nil {
		return err
	}
	fmt.Println("tar file :", tarFile, "ready")

	return nil
}
