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
	"runtime"
	"strings"
	"text/template"
)

var (
	profile = flag.String("c", "", "Define config profile to be included")
	region  = flag.String("r", "", "Define region profile to be included")
)

type pkg struct {
	appName       string
	importPath    string
	files         []string
	version       string
	upstartScript string
}

func main() {
	flag.Parse()

	if flag.NFlag() != 2 {
		fmt.Println("Please define config -c and region -r")
		os.Exit(1)
	}

	err := buildPackages()
	if err != nil {
		fmt.Println(err)
	}
}

func buildPackages() error {
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	kdproxyPath := "koding/kontrol/kontrolproxy/"
	kdproxyUpstart := filepath.Join(gopath, "src", kdproxyPath, "files/kontrolproxy.conf")

	configUpstart, err := prepareUpstart(kdproxyUpstart)
	if err != nil {
		return err
	}
	defer os.Remove(configUpstart)

	kontrolproxy := pkg{
		appName:    "kontrolproxy",
		importPath: kdproxyPath,
		files: []string{
			filepath.Join(gopath, "src", kdproxyPath, "files"),
		},
		version:       "0.0.1",
		upstartScript: filepath.Join(gopath, "src", kdproxyPath, "files/kontrolproxy.conf"),
	}

	return kontrolproxy.build()
}

func prepareUpstart(path string) (string, error) {
	temps := struct {
		Profile string
		Region  string
	}{
		*profile,
		*region,
	}

	file, err := ioutil.TempFile(".", "go-package")
	if err != nil {
		return "", err
	}
	defer file.Close()

	t, err := template.ParseFiles(path)
	if err != nil {
		return "", err
	}

	if err := t.Execute(file, temps); err != nil {
		return "", err
	}

	return file.Name(), nil
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

	// koding-config-manager needs it
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

	// include config dir
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
