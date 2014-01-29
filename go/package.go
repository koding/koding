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
	appName       string
	importPath    string
	files         []string
	version       string
	upstartScript string
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
		appName:    "kontrolproxy",
		importPath: "koding/kontrol/kontrolproxy",
		files: []string{
			filepath.Join(gopath, "src", "koding/kontrol/kontrolproxy/files"),
		},
		version:       "0.0.1",
		upstartScript: filepath.Join(gopath, "src", "koding/kontrol/kontrolproxy/files/kontrolproxy.conf"),
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
		err = ioutil.WriteFile(configFile, config, 0644)
		if err != nil {
			return err
		}

	}

	// include config dir too
	p.files = append(p.files, configDir)

	if runtime.GOOS == "linux" {
		deb := &build.Deb{
			AppName:       p.appName,
			Version:       p.version,
			ImportPath:    p.importPath,
			Files:         strings.Join(p.files, ","),
			InstallPrefix: "opt/kite",
			UpstartScript: p.upstartScript,
		}

		debFile, err := deb.Build()
		if err != nil {
			log.Println("linux:", err)
		}

		fmt.Printf("success: '%s' is ready\n", debFile)
	} else {
		fmt.Println("Not supported. Run on a linux machine.")
	}

	return nil
}
