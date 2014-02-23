package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"koding/tools/config"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"text/template"

	"github.com/koding/kite/cmd/build"
)

var (
	profile = flag.String("c", "", "Define config profile to be included")
	region  = flag.String("r", "", "Define region profile to be included")

	// Proxy only
	proxy = flag.String("p", "", "Select user proxy or koding proxy")
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
	if *profile == "" || *region == "" {
		fmt.Println("Please define config -c and region -r")
		os.Exit(1)
	}

	fmt.Println(*profile, *region, *proxy)

	err := buildPackages()
	if err != nil {
		fmt.Println(err)
	}
}

func buildPackages() error {
	if err := buildKontrolProxy(); err != nil {
		return err
	}

	if err := buildOsKite(); err != nil {
		return err
	}

	return nil
}

func buildOsKite() error {
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	oskitePath := "koding/kites/os"
	temps := struct {
		Profile string
		Region  string
	}{
		Profile: *profile,
		Region:  *region,
	}

	var files = make([]string, 0)
	files = append(files, filepath.Join(gopath, "src", oskitePath, "files"))

	// change our upstartscript because it's a template
	oskiteUpstart := filepath.Join(gopath, "src", oskitePath, "files/oskite.conf")
	configUpstart, err := prepareUpstart(oskiteUpstart, temps)
	if err != nil {
		return err
	}
	defer os.Remove(configUpstart)

	oskite := pkg{
		appName:       "oskite",
		importPath:    oskitePath,
		files:         files,
		version:       "0.0.5",
		upstartScript: configUpstart,
	}

	return oskite.build()
}

func buildKontrolProxy() error {
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	kdproxyPath := "koding/kontrol/kontrolproxy"

	// include certs
	if *proxy == "" {
		return errors.New("Please define proxy target. Example: -p koding or -p user")
	}

	temps := struct {
		Profile   string
		Region    string
		UserProxy string
	}{
		Profile: *profile,
		Region:  *region,
	}

	var files = make([]string, 0)
	switch *proxy {
	case "koding":
		files = append(files, "certs/koding_com_cert.pem", "certs/koding_com_key.pem")
	case "y":
		files = append(files, "certs/y_koding_com_cert.pem", "certs/y_koding_com_key.pem")
	case "x":
		files = append(files, "certs/x_koding_com_cert.pem", "certs/x_koding_com_key.pem")
	case "user":
		temps.UserProxy = "-v"
		files = append(files, "certs/kd_io_cert.pem", "certs/kd_io_key.pem")
	default:
		return errors.New("-p can accept either user or koding")
	}

	files = append(files, filepath.Join(gopath, "src", kdproxyPath, "files"))

	// change our upstartscript because it's a template
	kdproxyUpstart := filepath.Join(gopath, "src", kdproxyPath, "files/kontrolproxy.conf")
	configUpstart, err := prepareUpstart(kdproxyUpstart, temps)
	if err != nil {
		return err
	}
	defer os.Remove(configUpstart)

	kontrolproxy := pkg{
		appName:       "kontrolproxy",
		importPath:    kdproxyPath,
		files:         files,
		version:       "0.0.2",
		upstartScript: configUpstart,
	}

	return kontrolproxy.build()
}

func (p *pkg) build() error {
	fmt.Printf("building '%s' for config '%s' and region '%s'\n", p.appName, *profile, *region)

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

	c, err := config.ReadConfigManager(*profile)
	if err != nil {
		return err
	}

	configPretty, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return err
	}

	configFile := filepath.Join(configDir, fmt.Sprintf("main.%s.json", *profile))
	err = ioutil.WriteFile(configFile, configPretty, 0644)
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

func prepareUpstart(path string, v interface{}) (string, error) {
	file, err := ioutil.TempFile(".", "gopackage_")
	if err != nil {
		return "", err
	}
	defer file.Close()

	t, err := template.ParseFiles(path)
	if err != nil {
		return "", err
	}

	if err := t.Execute(file, v); err != nil {
		return "", err
	}

	return file.Name(), nil
}
