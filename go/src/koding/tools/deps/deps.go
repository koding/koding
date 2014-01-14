package deps

import (
	"encoding/json"
	"errors"
	"fmt"
	"go/build"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path"
	"runtime"
	"sort"
	"strings"

	"github.com/fatih/set"
)

const (
	depsGoPath    = "gonew"
	gopackageFile = "gopackage.json"
)

type Deps struct {
	// Packages is written as the importPath of a given package(s).
	Packages []string `json:"packages"`

	// GoVersion defines the Go version needed at least as a minumum.
	GoVersion string `json:"goVersion"`

	// Dependencies defines the dependency of the given Packages. If multiple
	// packages are defined, each dependency will point to the HEAD unless
	// changed manually.
	Dependencies []string `json:"dependencies"`

	// currentGoPath, is taken from current GOPATH environment variable
	currentGoPath string

	// tmpGoPath is used to fetch dependencies of the given Packages
	tmpGoPath string
}

func LoadDeps(pkgs ...string) (*Deps, error) {
	packages, err := listPackages(pkgs...)
	if err != nil {
		fmt.Println(err)
	}

	// get all dependencies for applications defined above
	dependencies := set.New()
	for _, pkg := range packages {
		for _, imp := range pkg.Deps {
			dependencies.Add(imp)
		}
	}

	// clean up deps
	// 1. remove std lib paths
	// 2. remove libs beginning with "koding...", because they already
	context := build.Default
	thirdPartyDeps := make([]string, 0)

	for _, importPath := range dependencies.StringSlice() {
		p, err := context.Import(importPath, ".", build.AllowBinary)
		if err != nil {
			log.Println(err)
		}

		// do not include std lib
		if p.Goroot {
			continue
		}

		// do not include koding packages
		if strings.HasPrefix(importPath, "koding") {
			continue
		}

		thirdPartyDeps = append(thirdPartyDeps, importPath)
	}

	sort.Strings(thirdPartyDeps)

	deps := &Deps{
		Packages:     pkgs,
		Dependencies: thirdPartyDeps,
		GoVersion:    runtime.Version(),
	}

	err = deps.populateGoPaths()
	if err != nil {
		return nil, err
	}

	return deps, nil
}

func (d *Deps) populateGoPaths() error {
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return errors.New("GOPATH is not set")
	}

	pwd, err := os.Getwd()
	if err != nil {
		return err
	}

	d.currentGoPath = gopath
	d.tmpGoPath = path.Join(pwd, depsGoPath)
	return nil
}

func (d *Deps) InstallDeps() error {
	// expand current path
	if d.tmpGoPath != d.currentGoPath {
		os.Setenv("GOPATH", fmt.Sprintf("%s:%s", d.tmpGoPath, d.currentGoPath))
	}

	os.Setenv("GOBIN", fmt.Sprintf("%s/bin", d.tmpGoPath))

	for _, pkg := range d.Packages {
		fmt.Println("go install -v", pkg)
		cmd := exec.Command("go", []string{"install", "-v", pkg}...)
		cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr

		err := cmd.Run()
		if err != nil {
			log.Println(err)
		}
	}

	return nil
}

func goPackagePath() string {
	pwd, err := os.Getwd()
	if err != nil {
		return ""
	}

	return path.Join(pwd, gopackageFile)
}

func (d *Deps) WriteJSON() error {
	data, err := json.MarshalIndent(d, "", "  ")
	if err != nil {
		return err
	}

	err = ioutil.WriteFile(goPackagePath(), data, 0755)
	if err != nil {
		return err
	}

	return nil
}

func ReadJson() (*Deps, error) {
	data, err := ioutil.ReadFile(goPackagePath())
	if err != nil {
		return nil, err
	}

	d := new(Deps)
	err = json.Unmarshal(data, d)
	if err != nil {
		return nil, err
	}

	err = d.populateGoPaths()
	if err != nil {
		return nil, err
	}

	return d, nil
}

func (d *Deps) GetDeps() error {
	os.MkdirAll(d.tmpGoPath, 0755)
	os.Setenv("GOPATH", d.tmpGoPath)

	for _, pkg := range d.Dependencies {
		fmt.Println("go get", pkg)
		cmd := exec.Command("go", []string{"get", "-d", pkg}...)
		cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr

		err := cmd.Run()
		if err != nil {
			log.Println(err)
		}
	}

	return nil
}
