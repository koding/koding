package main

import (
	"encoding/json"
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

	// change our upstartscript because it's a template
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
		upstartScript: configUpstart,
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

	file, err := ioutil.TempFile(".", "gopackage_")
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
	fmt.Printf("building '%s' for config '%s' and regions '%s'\n", p.appName, *profile, *region)

	// prepare config folder
	tempDir, err := ioutil.TempDir(".", "gopackage_")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tempDir)

	configDir := filepath.Join(tempDir, "config")
	os.MkdirAll(configDir, 0755)

	// koding-config-manager needs it
	err = ioutil.WriteFile("VERSION", []byte(p.version), 0755)
	if err != nil {
		return err
	}
	defer os.Remove("VERSION")

	// create config and include into config folder
	config, err := exec.Command("node", "-e", "require('koding-config-manager').printJson('main."+*profile+"')").CombinedOutput()
	if err != nil {
		return err
	}

	// prettify content of "config"
	var d map[string]interface{}
	if err := json.Unmarshal(config, &d); err != nil {
		return err
	}

	config, err = json.MarshalIndent(d, "", "  ")
	if err != nil {
		return err
	}

	configFile := filepath.Join(configDir, fmt.Sprintf("main.%s.json", *profile))
	err = ioutil.WriteFile(configFile, config, 0644)
	if err != nil {
		return err
	}

	p.files = append(p.files, configDir)

	// Now it's time to build
	if runtime.GOOS != "linux" {
		return errors.New("Not supported. Please run on a linux machine.")
	}

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

	// rename file to see for which region and env it is created
	oldname := debFile
	newname := fmt.Sprintf("%s_%s_%s-%s_%s.deb", p.appName, p.version, *profile, *region, deb.Arch)

	if err := os.Rename(oldname, newname); err != nil {
		return err
	}

	fmt.Printf("success '%s' is ready. Some helpful commands for you:\n\n", newname)
	fmt.Printf("  show deb content   : dpkg -c %s\n", newname)
	fmt.Printf("  show basic info    : dpkg -f %s\n", newname)
	fmt.Printf("  install to machine : dpkg -i %s\n\n", newname)

	return nil
}
