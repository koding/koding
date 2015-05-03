package main

import (
	"fmt"
	"go/ast"
	"go/build"
	"go/parser"
	"go/token"
	"io/ioutil"
	_ "path"
	"path/filepath"
	"strings"

	"flag"

	_ "golang.org/x/tools/go/gcimporter"
	"golang.org/x/tools/go/types"
	"os"
)

var debug = flag.Bool("debug", false, "Enable debug printing.")
var exitWith = flag.Int("exitWith", 1, "Error code to exit with, if there are errors")
var hasErrors = false

type fileMetadata struct {
	info *types.Info
	name string
	fset *token.FileSet
	file *ast.File
}

func recMain(s string) {
	dir := strings.TrimSuffix(s, "...")
	st, err := os.Stat(dir)
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(*exitWith)
	}
	if !st.IsDir() {
		fmt.Println("Non-directory ending in ...")
		os.Exit(*exitWith)
	}
	dirRec(dir)
}

func main() {
	flag.Parse()
	if len(flag.Args()) < 1 {
		fmt.Println("No path given")
		os.Exit(*exitWith)
	}
	for _, arg := range flag.Args() {
		if strings.HasSuffix(arg, "...") {
			recMain(arg)
			continue
		}
		st, err := os.Stat(arg)
		if err != nil {
			fmt.Println("Error:", err)
			os.Exit(*exitWith)
		}
		if st.IsDir() {
			doPackageDir(arg, "")
		} else {
			abs, _ := filepath.Abs(arg)
			doPackageDir(filepath.Dir(arg), abs)
		}
	}
	if hasErrors {
		os.Exit(*exitWith)
	}
}

// prefixDirectory places the directory name on the beginning of each name in the list.
func prefixDirectory(directory string, names []string) {
	if directory != "." {
		for i, name := range names {
			names[i] = filepath.Join(directory, name)
		}
	}
}

func doPackageDir(directory string, file string) {
	pkg, err := build.Default.ImportDir(directory, 0)
	if err != nil {
		// If it's just that there are no go source files, that's fine.
		if _, nogo := err.(*build.NoGoError); nogo {
			return
		}
		// Non-fatal: we are doing a recursive walk and there may be other directories.
		fmt.Printf("cannot process directory %s: %s\n", directory, err)
		return
	}
	var names []string
	names = append(names, pkg.GoFiles...)
	names = append(names, pkg.CgoFiles...)
	names = append(names, pkg.TestGoFiles...) // These are also in the "foo" package.
	names = append(names, pkg.SFiles...)
	prefixDirectory(directory, names)
	doPackage(directory, names, file)
	// Is there also a "foo_test" package? If so, do that one as well.
	if len(pkg.XTestGoFiles) > 0 {
		names = pkg.XTestGoFiles
		prefixDirectory(directory, names)
		doPackage(directory, names, file)
	}
}

type packageMetadata struct {
	path     string
	files    []*fileMetadata
	typesPkg *types.Package
}

func doPackage(directory string, names []string, singlefile string) {
	var files []*fileMetadata
	var astFiles []*ast.File
	if *debug {
		fmt.Println("Checking directory", directory, "...")
	}
	fs := token.NewFileSet()
	for _, name := range names {
		data, err := ioutil.ReadFile(name)
		if err != nil {
			// Warn but continue to next package.
			fmt.Printf("%s: %s\n", name, err)
			return
		}
		var parsedFile *ast.File
		if strings.HasSuffix(name, ".go") {
			parsedFile, err = parser.ParseFile(fs, name, data, 0)
			if err != nil {
				fmt.Printf("%s: %s\n", name, err)
				return
			}
			astFiles = append(astFiles, parsedFile)
		}
		files = append(files, &fileMetadata{fset: fs, name: name, file: parsedFile})
	}
	if len(astFiles) == 0 {
		return
	}
	pkg := new(packageMetadata)
	pkg.path = astFiles[0].Name.Name
	pkg.files = files
	info := types.Info{
		Types: make(map[ast.Expr]types.TypeAndValue),
	}
	config := new(types.Config)
	_, err := config.Check(pkg.path, fs, astFiles, &info)
	if err != nil {
		if *debug {
			fmt.Println("Error package checker:", err)
		}

	}
	for _, file := range pkg.files {
		if singlefile != "" {
			abs, _ := filepath.Abs(file.name)
			if abs != singlefile {
				continue
			}
		}
		file.info = &info
		CheckNoShadow(*file, file.file)
		CheckNoAssignUnused(*file, file.file)
	}
}

func visit(path string, f os.FileInfo, err error) error {
	if err != nil {
		fmt.Println("Walk error:", err)
		return err
	}
	if !f.IsDir() {
		return nil
	}
	doPackageDir(path, "")
	return nil
}

func dirRec(path string) {
	filepath.Walk(path, visit)
}
