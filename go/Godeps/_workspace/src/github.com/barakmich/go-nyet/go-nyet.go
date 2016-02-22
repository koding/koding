package main

import (
	"flag"
	"fmt"
	"go/ast"
	"go/build"
	"go/parser"
	"go/token"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"golang.org/x/tools/go/types"
)

var debug = flag.Bool("debug", false, "Enable debug printing.")
var exitWith = flag.Int("exitWith", 1, "Error code to exit with, if there are errors")
var hasErrors = false

type fileMetadata struct {
	pkg      *pkg
	f        *ast.File
	fset     *token.FileSet
	src      []byte
	filename string
}

func usage() {
	fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
	fmt.Fprintf(os.Stderr, "\tgo-nyet [flags] # runs on package in current directory\n")
	fmt.Fprintf(os.Stderr, "\tgo-nyet [flags] package\n")
	fmt.Fprintf(os.Stderr, "\tgo-nyet [flags] directory\n")
	fmt.Fprintf(os.Stderr, "\tgo-nyet [flags] files... # must be a single package\n")
	fmt.Fprintf(os.Stderr, "Flags:\n")
	flag.PrintDefaults()
}

func main() {
	flag.Usage = usage
	flag.Parse()

	switch flag.NArg() {
	case 0:
		doDir(".")
	case 1:
		arg := flag.Arg(0)
		if strings.HasSuffix(arg, "/...") && isDir(arg[:len(arg)-4]) {
			for _, dirname := range allPackagesInFS(arg) {
				doDir(dirname)
			}
		} else if isDir(arg) {
			doDir(arg)
		} else if exists(arg) {
			doFiles(arg)
		} else {
			for _, pkgname := range importPaths([]string{arg}) {
				doPackage(pkgname)
			}
		}
	default:
		doFiles(flag.Args()...)
	}
}

func isDir(filename string) bool {
	fi, err := os.Stat(filename)
	return err == nil && fi.IsDir()
}

func exists(filename string) bool {
	_, err := os.Stat(filename)
	return err == nil
}

// pkg represents a package being checked.
type pkg struct {
	fset  *token.FileSet
	files map[string]*fileMetadata

	typesPkg  *types.Package
	typesInfo *types.Info
}

func doFiles(filenames ...string) {
	files := make(map[string][]byte)
	for _, filename := range filenames {
		src, err := ioutil.ReadFile(filename)
		if err != nil {
			if *debug {
				fmt.Fprintln(os.Stderr, err)
			}
			continue
		}
		files[filename] = src
	}

	pkg := &pkg{
		fset:  token.NewFileSet(),
		files: make(map[string]*fileMetadata),
		typesInfo: &types.Info{
			Types: make(map[ast.Expr]types.TypeAndValue),
		},
	}
	var pkgName string
	for filename, src := range files {
		if *debug {
			fmt.Println("Checking file", filename, "...")
		}
		f, err := parser.ParseFile(pkg.fset, filename, src, parser.ParseComments)
		if err != nil {
			fmt.Printf("%s: %s\n", filename, err)
			return
		}
		if pkgName == "" {
			pkgName = f.Name.Name
		} else if f.Name.Name != pkgName {
			fmt.Printf("%s is in package %s, not %s", filename, f.Name.Name, pkgName)
			return
		}
		file := fileMetadata{
			pkg:      pkg,
			f:        f,
			fset:     pkg.fset,
			src:      src,
			filename: filename,
		}
		CheckNoShadow(file)
		CheckNoAssignUnused(file)
	}
}

func doDir(dirname string) {
	pkg, err := build.ImportDir(dirname, 0)
	doImportedPackage(pkg, err)
}

func doPackage(pkgname string) {
	pkg, err := build.Import(pkgname, ".", 0)
	doImportedPackage(pkg, err)
}

func doImportedPackage(pkg *build.Package, err error) {
	if err != nil {
		if _, nogo := err.(*build.NoGoError); nogo {
			// Don't complain if the failure is due to no Go source files.
			return
		}
		fmt.Fprintln(os.Stderr, err)
		return
	}

	var files []string
	files = append(files, pkg.GoFiles...)
	files = append(files, pkg.CgoFiles...)
	files = append(files, pkg.TestGoFiles...)
	files = append(files, pkg.SFiles...)

	doLocalFiles(pkg, files...)
	doLocalFiles(pkg, pkg.XTestGoFiles...)
}

func doLocalFiles(pkg *build.Package, files ...string) {
	if pkg.Dir != "." {
		for i, f := range files {
			files[i] = filepath.Join(pkg.Dir, f)
		}
	}

	doFiles(files...)
}
