package main

import (
	"errors"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"

	"koding/klient/build/build"
)

var (
	flagEnvironment = flag.String("e", "", "Define environment profile to be included")
	flagBuildNumber = flag.Int("b", 0, "Build number is added to the generated file if specified")
	flagDebug       = flag.Bool("d", false, "Enable debug mode")
)

type pkg struct {
	appName        string
	importPath     string
	files          []string
	version        string
	upstartScript  string
	sysvinitScript string
	ldflags        string
}

func main() {
	flag.Parse()
	if *flagBuildNumber == 0 {
		fmt.Fprintf(os.Stderr, "Please define build number with -b \n")
		os.Exit(1)
	}

	if err := buildKlient(); err != nil {
		fmt.Println(err)
	}
}

func buildKlient() error {
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	importPath := "koding/klient"
	upstartPath := filepath.Join(gopath, "src", importPath, "files/klient.conf")
	sysvinitPath := filepath.Join(gopath, "src", importPath, "files/klient.init")

	symbolvalue := "0.0.1"
	if *flagBuildNumber != 0 {
		symbolvalue = "0.1." + strconv.Itoa(*flagBuildNumber)
	}

	ldflags := fmt.Sprintf("-X koding/klient/config.Version=%s", symbolvalue)
	if *flagEnvironment != "" {
		ldflags += fmt.Sprintf(" -X koding/klient/config.Environment=%s", *flagEnvironment)
	}

	kclient := pkg{
		appName:        "klient",
		importPath:     importPath,
		version:        symbolvalue,
		upstartScript:  upstartPath,
		sysvinitScript: sysvinitPath,
		ldflags:        ldflags,
	}

	return kclient.build()
}

func (p *pkg) build() error {
	fmt.Println("building klient")

	// Now it's time to build
	if runtime.GOOS != "linux" {
		return errors.New("Not supported. Please run on a linux machine.")
	}

	deb := &build.Deb{
		Debug:          *flagDebug,
		AppName:        p.appName,
		Version:        p.version,
		ImportPath:     p.importPath,
		Files:          strings.Join(p.files, ","),
		InstallPrefix:  "opt/kite",
		UpstartScript:  p.upstartScript,
		SysvinitScript: p.sysvinitScript,
		Ldflags:        p.ldflags,
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

	if *flagEnvironment != "" {
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
