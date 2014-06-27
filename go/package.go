package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"koding/oskite"
	"koding/terminal"
	"koding/tools/build"
	"koding/tools/config"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"text/template"

	"github.com/koding/kite/reverseproxy"
)

var (
	flagProfile     = flag.String("c", "", "Define config profile to be included")
	flagRegion      = flag.String("r", "", "Define region profile to be included")
	flagEnvironment = flag.String("e", "", "Define environment profile to be included")
	flagHost        = flag.String("h", "", "Define hostname for kite reveseproxy")
	flagApp         = flag.String("a", "", "App to be build")
	flagBuildNumber = flag.Int("b", 0, "Build number is added to the generated file if specified")

	// kontrolproxy specific flags
	flagProxy = flag.String("p", "", "Select user proxy or koding proxy") // Proxy only

	flagDisableUpstart = flag.Bool("u", false, "Disable including upstart script")
	flagDebug          = flag.Bool("d", false, "Enable debug mode")

	packages = map[string]func() error{
		"oskite":       buildOsKite,
		"kontrolproxy": buildKontrolProxy,
		"reverseproxy": buildProxyKite,
		"terminal":     buildTerminal,
		"kontrol":      buildKontrol,
		"klient":       buildKlient,
	}
)

type pkg struct {
	appName       string
	importPath    string
	files         []string
	version       string
	upstartScript string
	symbolname    string
	symbolvalue   string
}

func main() {
	flag.Parse()
	if *flagApp == "" {
		fmt.Printf("Please define package with -a to be build. Available apps:\n%s\n", packageList())
		os.Exit(1)
	}

	build, ok := packages[*flagApp]
	if !ok {
		log.Fatal("package to be build is not available")
	}

	if err := build(); err != nil {
		fmt.Println(err)
	}
}

func packageList() string {
	pkgs := "\n"
	count := 1
	for pkg := range packages {
		pkgs += strconv.Itoa(count) + ". " + pkg + "\n"
		count++
	}

	return pkgs
}

func buildProxyKite() error {
	if *flagEnvironment == "" || *flagRegion == "" || *flagHost == "" {
		return errors.New("Please define environment -e , region -r and host -h")
	}

	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	importPath := "github.com/koding/kite/reverseproxy/reverseproxy"
	upstartPath := filepath.Join(gopath, "src/koding/kites/reverseproxy/files/reverseproxy.conf")

	temps := struct {
		Environment string
		Region      string
		Host        string
	}{
		Environment: *flagEnvironment,
		Region:      *flagRegion,
		Host:        *flagHost,
	}

	files := []string{}
	files = append(files, "certs/koding_com_cert.pem", "certs/koding_com_key.pem")

	// change our upstartscript because it's a template
	configUpstart, err := prepareUpstart(upstartPath, temps)
	if err != nil {
		return err
	}
	defer os.Remove(configUpstart)

	kiteproxy := pkg{
		appName:       *flagApp,
		importPath:    importPath,
		files:         files,
		version:       reverseproxy.Version,
		upstartScript: configUpstart,
	}

	return kiteproxy.build()
}

func buildKlient() error {
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	importPath := "koding/kites/klient"
	upstartPath := filepath.Join(gopath, "src", importPath, "files/klient.conf")

	symbolvalue := "0.0.1"
	if *flagBuildNumber != 0 {
		symbolvalue = "0.1." + strconv.Itoa(*flagBuildNumber)
	}

	kclient := pkg{
		appName:       *flagApp,
		importPath:    importPath,
		version:       symbolvalue,
		upstartScript: upstartPath,
		symbolname:    "koding/kites/klient/protocol.Version",
		symbolvalue:   symbolvalue,
	}

	return kclient.build()
}

func buildKontrol() error {
	if *flagProfile == "" || *flagRegion == "" {
		return errors.New("Please define config -c and region -r")
	}

	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	kontrolPath := "koding/kites/kontrol"
	temps := struct {
		Profile string
		Region  string
	}{
		Profile: *flagProfile,
		Region:  *flagRegion,
	}

	var files = make([]string, 0)
	files = append(files, filepath.Join(gopath, "src", kontrolPath, "files"))

	// change our upstartscript because it's a template
	var configUpstart string
	var err error
	if !*flagDisableUpstart {
		kontrolUpstart := filepath.Join(gopath, "src", kontrolPath, "files/kontrol.conf")
		configUpstart, err = prepareUpstart(kontrolUpstart, temps)
		if err != nil {
			return err
		}
		defer os.Remove(configUpstart)
	}

	term := pkg{
		appName:       *flagApp,
		importPath:    kontrolPath,
		files:         files,
		version:       "0.1.0",
		upstartScript: configUpstart,
	}

	return term.build()
}

func buildTerminal() error {
	if *flagProfile == "" || *flagRegion == "" {
		return errors.New("Please define config -c and region -r")
	}

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
	var configUpstart string
	var err error
	if !*flagDisableUpstart {
		terminalUpstart := filepath.Join(gopath, "src", terminalPackage, "files/terminal.conf")
		configUpstart, err = prepareUpstart(terminalUpstart, temps)
		if err != nil {
			return err
		}
		defer os.Remove(configUpstart)
	}

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
	if *flagProfile == "" || *flagRegion == "" {
		return errors.New("Please define config -c and region -r")
	}

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
	var configUpstart string
	var err error
	if !*flagDisableUpstart {
		oskiteUpstart := filepath.Join(gopath, "src", oskitePackage, "files/oskite.conf")
		configUpstart, err = prepareUpstart(oskiteUpstart, temps)
		if err != nil {
			return err
		}
		defer os.Remove(configUpstart)
	}

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
	if *flagProfile == "" || *flagRegion == "" {
		return errors.New("Please define config -c and region -r")
	}

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
	var configUpstart string
	var err error
	if !*flagDisableUpstart {
		kdproxyUpstart := filepath.Join(gopath, "src", kdproxyPath, "files/kontrolproxy.conf")
		configUpstart, err = prepareUpstart(kdproxyUpstart, temps)
		if err != nil {
			return err
		}
		defer os.Remove(configUpstart)
	}

	kontrolproxy := pkg{
		appName:       *flagApp,
		importPath:    kdproxyPath,
		files:         files,
		version:       "0.0.9",
		upstartScript: configUpstart,
	}

	return kontrolproxy.build()
}

func (p *pkg) build() error {
	if *flagProfile == "" || *flagRegion == "" {
		fmt.Printf("building '%s'\n", *flagApp)
	} else {
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
	}

	// Now it's time to build
	if runtime.GOOS != "linux" {
		return errors.New("Not supported. Please run on a linux machine.")
	}

	deb := &build.Deb{
		Debug:         *flagDebug,
		AppName:       p.appName,
		Version:       p.version,
		ImportPath:    p.importPath,
		Files:         strings.Join(p.files, ","),
		InstallPrefix: "opt/kite",
		UpstartScript: p.upstartScript,
		SymbolName:    p.symbolname,
		SymbolValue:   p.symbolvalue,
	}

	debFile, err := deb.Build()
	if err != nil {
		log.Println("linux:", err)
	}

	// customize our created file with the passed arguments
	oldname := debFile

	newname := p.appName + "_" + p.version
	if *flagBuildNumber != 0 {
		// http://semver.org/ see build-number paragraph
		newname = p.appName + "_0.1." + strconv.Itoa(*flagBuildNumber)
	}

	if *flagProfile != "" && *flagRegion != "" {
		newname += fmt.Sprintf("_%s-%s_%s.deb", *flagProfile, *flagRegion, deb.Arch)
	} else if *flagEnvironment != "" {
		newname += fmt.Sprintf("_%s_%s.deb", *flagEnvironment, deb.Arch)
	} else {
		newname += fmt.Sprintf("_%s.deb", deb.Arch)
	}

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
