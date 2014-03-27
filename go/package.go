package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"koding/oskite"
	"koding/terminal"
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
	flagProfile = flag.String("c", "", "Define config profile to be included")
	flagRegion  = flag.String("r", "", "Define region profile to be included")
	flagApp     = flag.String("a", "", "App to be build")
	flagProxy   = flag.String("p", "", "Select user proxy or koding proxy") // Proxy only

	packages = map[string]func() error{
		"oskite":       buildOsKite,
		"kontrolproxy": buildKontrolProxy,
	}
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
	if *flagProfile == "" || *flagRegion == "" {
		fmt.Println("Please define config -c and region -r")
		os.Exit(1)
	}

	if *flagApp == "" {
		fmt.Printf("Please define package with -a to be build. Available apps:\n%s\n", packageList())
		os.Exit(1)
	}

	err := buildPackages(*flagApp)
	if err != nil {
		fmt.Println(err)
	}
}

func packageList() []string {
	pkgList := make([]string, 0, len(packages))
	for pkg := range packages {
		pkgList = append(pkgList, pkg)
	}

	return pkgList
}

func buildPackages(pkgName string) error {
	switch pkgName {
	case "oskite":
		return buildOsKite()
	case "kontrolproxy":
		return buildKontrolProxy()
	case "terminal":
		return buildTerminal()
	default:
		return errors.New("package to be build is not available")
	}
}

func buildTerminal() error {
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	terminalPath := "koding/kites/terminal"
	terminalPackage := "koding/terminal"
	temps := struct {
		Profile string
		Region  string
	}{
		Profile: *flagProfile,
		Region:  *flagRegion,
	}

	var files = make([]string, 0)
	files = append(files, filepath.Join(gopath, "src", terminalPackage, "files"))

	// change our upstartscript because it's a template
	terminalUpstart := filepath.Join(gopath, "src", terminalPackage, "files/terminal.conf")
	configUpstart, err := prepareUpstart(terminalUpstart, temps)
	if err != nil {
		return err
	}
	defer os.Remove(configUpstart)

	term := pkg{
		appName:       *flagApp,
		importPath:    terminalPath,
		files:         files,
		version:       terminal.TERMINAL_VERSION,
		upstartScript: configUpstart,
	}

	return term.build()
}

func buildOsKite() error {
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	oskitePath := "koding/kites/os"
	oskitePackage := "koding/oskite"
	temps := struct {
		Profile string
		Region  string
	}{
		Profile: *flagProfile,
		Region:  *flagRegion,
	}

	var files = make([]string, 0)
	files = append(files, filepath.Join(gopath, "src", oskitePackage, "files"))
	files = append(files, filepath.Join(gopath, "bin-vagrant/vmtool")) // TODO add it to the list of importPaths

	// change our upstartscript because it's a template
	oskiteUpstart := filepath.Join(gopath, "src", oskitePackage, "files/oskite.conf")
	configUpstart, err := prepareUpstart(oskiteUpstart, temps)
	if err != nil {
		return err
	}
	defer os.Remove(configUpstart)

	oskite := pkg{
		appName:       *flagApp,
		importPath:    oskitePath,
		files:         files,
		version:       oskite.OSKITE_VERSION,
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

	temps := struct {
		Profile   string
		Region    string
		UserProxy string
	}{
		Profile: *flagProfile,
		Region:  *flagRegion,
	}

	var files = make([]string, 0)
	switch *flagProxy {
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
		return errors.New("Please define certs to be included with -p. Available certs: [user | koding | x | y]")
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
		appName:       *flagApp,
		importPath:    kdproxyPath,
		files:         files,
		version:       "0.0.5",
		upstartScript: configUpstart,
	}

	return kontrolproxy.build()
}

func (p *pkg) build() error {
	fmt.Printf("building '%s' for config '%s' and region '%s'\n", *flagApp, *flagProfile, *flagRegion)

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

	c, err := config.ReadConfigManager(*flagProfile)
	if err != nil {
		return err
	}

	configPretty, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return err
	}

	configFile := filepath.Join(configDir, fmt.Sprintf("main.%s.json", *flagProfile))
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
	newname := fmt.Sprintf("%s_%s_%s-%s_%s.deb", p.appName, p.version, *flagProfile, *flagRegion, deb.Arch)

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
