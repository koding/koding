package deps

import (
	"errors"
	"fmt"
	"go/build"
	"log"
	"os"
	"os/exec"
	"path"
	"sort"
	"strings"

	"github.com/fatih/set"
)

const depsGoPath = "gonew"

type Deps struct {
	// Packages is written as the importPath of a given package(s).
	Packages []string

	// Dependencies defines the dependency of the given Packages. If multiple
	// packages are defined, each dependency will point to the HEAD unless
	// changed manually.
	Dependencies []string

	// currentGoPath, is taken from current GOPATH environment variable
	currentGoPath string

	// tmpGoPath is used to fetch dependencies of the given Packages
	tmpGoPath string
}

func LoadDeps(pkgs ...string) (*Deps, error) {
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return nil, errors.New("GOPATH is not set")
	}

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

	pwd, err := os.Getwd()
	if err != nil {
		return nil, err
	}

	deps := &Deps{
		Packages:      pkgs,
		Dependencies:  thirdPartyDeps,
		currentGoPath: gopath,
		tmpGoPath:     path.Join(pwd, depsGoPath),
	}

	return deps, nil
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
