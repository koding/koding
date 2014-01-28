package main

import (
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

	err := doPackage()
	if err != nil {
		log.Println(err)
	} else {
		fmt.Println("package build is successful")
	}

}

func doPackage() error {
	// prepare config folder
	tempDir, err := ioutil.TempDir(".", "gopackage_")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tempDir)

	configDir := filepath.Join(tempDir, "config")
	config, err := exec.Command("node", "-e", "require('koding-config-manager').printJson('main."+*profile+"')").CombinedOutput()
	if err != nil {
		return err
	}

	configFile := filepath.Join(configDir, fmt.Sprintf("main.%s.json", *profile))
	err = ioutil.WriteFile(configFile, config, 0755)
	if err != nil {
		return err
	}

	kontrolproxy := pkg{
		importPath: "koding/kontrol/kontrolproxy", // TODO read from GOPATH!
		files: []string{
			"go/src/koding/kontrol/kontrolproxy/files",
			configDir,
		},
	}

	b := build.NewBuild()
	b.ImportPath = kontrolproxy.importPath
	b.Files = strings.Join(kontrolproxy.files, ",")

	err = b.InitializeAppName()
	if err != nil {
		return err
	}

	err = b.Do()
	if err != nil {
		return err
	}

	return nil
}
