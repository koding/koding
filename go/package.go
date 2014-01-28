package main

import (
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"koding/kite/kd/build"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

var (
	profile = flag.String("c", "", "Configuration profile from file")
)

type pkg struct {
	importPath string
	files      []string
}

func main() {
	flag.Parse()
	if *profile == "" {
		log.Fatalln("Please define config with -c, that is going to be included with the package.")
	}

	err := buildPackages()
	if err != nil {
		log.Println(err)
	} else {
		fmt.Println("package build is successful")
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
	}

	return kontrolproxy.build()
}

func (p *pkg) build() error {

	// prepare config folder
	tempDir, err := ioutil.TempDir(".", "gopackage_")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tempDir)

	configDir := filepath.Join(tempDir, "config")
	os.MkdirAll(configDir, 0755)

	config, err := exec.Command("node", "-e", "require('koding-config-manager').printJson('main."+*profile+"')").CombinedOutput()
	if err != nil {
		return err
	}

	configFile := filepath.Join(configDir, fmt.Sprintf("main.%s.json", *profile))
	err = ioutil.WriteFile(configFile, config, 0755)
	if err != nil {
		return err
	}

	// include config dir too
	p.files = append(p.files, configDir)

	b := build.NewBuild()
	b.ImportPath = p.importPath
	b.Files = strings.Join(p.files, ",")

	err = b.InitializeAppName()
	if err != nil {
		return err
	}

	err = b.TarGzFile()
	if err != nil {
		return err
	}

	return nil
}
