// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

package check

import (
	"go/ast"
	"go/build"
	"go/parser"
	"go/token"
	"log"
	"path/filepath"
	"reflect"
)

func ASTFilesForPackage(path string, includeTestFiles bool) (*token.FileSet, []*ast.File) {
	ctx := build.Default
	pkg, err := ctx.Import(path, ".", 0)
	if err != nil {
		var err2 error
		pkg, err2 = ctx.ImportDir(path, 0)
		if err2 != nil {
			log.Fatalf("cannot import package %s\n"+
				"Errors are:\n"+
				"    %s\n"+
				"    %s",
				path, err, err2)
		}
	}
	fset := token.NewFileSet()
	var astFiles []*ast.File
	files := pkg.GoFiles
	if includeTestFiles {
		files = append(files, pkg.TestGoFiles...)
		files = append(files, pkg.XTestGoFiles...)
	}
	for _, f := range files {
		fn := filepath.Join(pkg.Dir, f)
		f, err := parser.ParseFile(fset, fn, nil, 0)
		if err != nil {
			log.Fatalf("cannot parse file '%s'\n"+
				"Error: %s", fn, err)
		}
		astFiles = append(astFiles, f)
	}
	return fset, astFiles
}

func TypeName(v interface{}) string {
	t := reflect.TypeOf(v)
	if t == nil {
		return ""
	}
	if t.Kind() == reflect.Ptr {
		t = t.Elem()
	}
	return t.Name()
}
