package importer // import "honnef.co/go/importer"

import (
	"fmt"
	"go/ast"
	"go/build"
	"go/parser"
	"go/token"
	"os"
	"strings"

	"golang.org/x/tools/go/gcimporter"
	"golang.org/x/tools/go/types"
)

type Config struct {
	UseGcFallback bool // Whether to fall back to GcImport when presented with a package that imports "C"
}

type Importer struct {
	cycleSeen   map[string]bool
	cyclesStack []string
	Imports     map[string]*types.Package // All packages imported by Importer
	Fallbacks   []string                  // List of imports that we had to fall back to GcImport for
	Config      Config                    // Configuration for the importer
}

func New() *Importer {
	return &Importer{
		Imports: make(map[string]*types.Package),
	}
}

// Import implements the Importer type from go/types.
func (imp *Importer) Import(imports map[string]*types.Package, path string) (pkg *types.Package, err error) {
	imp.cycleSeen = make(map[string]bool)
	imp.cyclesStack = nil
	return imp.realImport(imports, path)
}

func (imp *Importer) realImport(imports map[string]*types.Package, path string) (pkg *types.Package, err error) {
	// types.Importer does not seem to be designed for recursive
	// parsing like we're doing here. Specifically, each nested import
	// will maintain its own imports map. This will lead to duplicate
	// imports and in turn packages, which will lead to funny errors
	// such as "cannot pass argument ip (variable of type net.IP) to
	// variable of type net.IP"
	//
	// To work around this, we keep a global imports map, allImports,
	// to which we add all nested imports, and which we use as the
	// cache, instead of imports.
	//
	// Since all nested imports will also use this importer, there
	// should be no way to end up with duplicate imports.

	// We first try to use GcImport directly. This has the downside of
	// using possibly out-of-date packages, but it has the upside of
	// not having to parse most of the Go standard library.

	imported := func(pkg *types.Package) {
		// We don't use imports, but per API we have to add the package.
		imports[pkg.Path()] = pkg
		imp.Imports[pkg.Path()] = pkg
	}

	buildPkg, buildErr := build.Import(path, ".", 0)
	// If we found no build dir, assume we're dealing with installed
	// but no source. If we found a build dir, only use GcImport if
	// it's in GOROOT. This way we always use up-to-date code for
	// normal packages but avoid parsing the standard library.
	if (buildErr == nil && buildPkg.Goroot) || buildErr != nil {
		pkg, err = gcimporter.Import(imp.Imports, path)
		if err == nil {
			imported(pkg)
			return pkg, nil
		}
	}

	// See if we already imported this package
	if pkg = imp.Imports[path]; pkg != nil && pkg.Complete() {
		return pkg, nil
	}

	// allImports failed, try to use go/build
	if buildErr != nil {
		return nil, fmt.Errorf("build.Import failed: %s", buildErr)
	}

	// TODO check if the .a file is up to date and use it instead
	fileSet := token.NewFileSet()

	isGoFile := func(d os.FileInfo) bool {
		allFiles := make([]string, 0, len(buildPkg.GoFiles)+len(buildPkg.CgoFiles))
		allFiles = append(allFiles, buildPkg.GoFiles...)
		allFiles = append(allFiles, buildPkg.CgoFiles...)

		for _, file := range allFiles {
			if file == d.Name() {
				return true
			}
		}
		return false
	}
	pkgs, err := parser.ParseDir(fileSet, buildPkg.Dir, isGoFile, 0)
	if err != nil {
		return nil, err
	}

	delete(pkgs, "documentation")
	var astPkg *ast.Package
	var name string
	for name, astPkg = range pkgs {
		// Use the first non-main package, or the only package we
		// found.
		//
		// NOTE(dh) I can't think of a reason why there should be
		// multiple packages in a single directory, but ParseDir
		// accommodates for that possibility.
		if len(pkgs) == 1 || name != "main" {
			break
		}
	}

	if astPkg == nil {
		return nil, fmt.Errorf("can't find import: %s", name)
	}

	var ff []*ast.File
	for _, f := range astPkg.Files {
		ff = append(ff, f)
	}

	if imp.cycleSeen[path] {
		return nil, fmt.Errorf("import cycle %s -> %s", strings.Join(imp.cyclesStack, " -> "), path)
	}
	imp.cycleSeen[path] = true
	imp.cyclesStack = append(imp.cyclesStack, path)

	context := types.Config{
		Import: imp.realImport,
	}

	pkg, err = context.Check(name, fileSet, ff, nil)
	if err != nil {
		// As a special case, if type checking failed due cgo, try
		// again by using GcImport. That way we can extract all
		// required type information, but we risk importing an
		// outdated version.
		if imp.Config.UseGcFallback && strings.Contains(err.Error(), `cannot find package "C" in`) {
			gcPkg, gcErr := gcimporter.Import(imp.Imports, path)
			if gcErr == nil {
				imported(gcPkg)
				imp.Fallbacks = append(imp.Fallbacks, path)
				return gcPkg, nil
			}
		}
		return pkg, err
	}

	imports[path] = pkg
	imp.Imports[path] = pkg
	return pkg, nil
}
