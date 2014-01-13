package deps

import (
	"fmt"
	"go/build"
	"log"
	"os"
	"os/exec"
	"path"
	"sort"
	"strings"
	"sync"

	"github.com/fatih/set"
)

type Deps struct {
	// if multiple, revision will be always pointing to HEAD
	// Packages is written as the importPath of a given package.
	Packages     []string
	Dependencies []string
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
	}

	return deps, nil
}

func (d *Deps) GetDeps() error {
	pwd, err := os.Getwd()
	if err != nil {
		return err
	}

	godir := "gonew"
	gopathDir := path.Join(pwd, godir)
	os.MkdirAll(gopathDir, 0755)
	os.Setenv("GOPATH", gopathDir)

	var wg sync.WaitGroup

	results := make(chan string, 0)

	for _, pkg := range d.Dependencies {
		wg.Add(1)

		go func(pkg string) {
			defer wg.Done()
			cmd := exec.Command("go", []string{"get", "-d", pkg}...)
			cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr

			var res string
			err := cmd.Run()
			if err != nil {
				res = fmt.Sprintf("fetching error %s", err)
			} else {
				res = pkg
			}

			results <- res
		}(pkg)
	}

	go func() {
		for res := range results {
			fmt.Println(res)
		}
	}()

	wg.Wait()

	return nil
}
