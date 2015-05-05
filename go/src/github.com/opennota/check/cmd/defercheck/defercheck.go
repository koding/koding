// defercheck
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

package main

import (
	"flag"
	"fmt"
	"go/ast"
	"go/token"
	"os"

	"github.com/kisielk/gotool"
	"github.com/opennota/check"
)

type visitor struct {
	fset     *token.FileSet
	m        map[*ast.Object][]string
	funcName string
}

var exitStatus int

func (v *visitor) Visit(node ast.Node) ast.Visitor {
	switch node := node.(type) {
	case *ast.FuncDecl:
		v.funcName = node.Name.Name
		v.m = make(map[*ast.Object][]string)

	case *ast.DeferStmt:
		if sel, ok := node.Call.Fun.(*ast.SelectorExpr); ok {
			if ident, ok := sel.X.(*ast.Ident); ok {
				if selectors, ok := v.m[ident.Obj]; !ok {
					v.m[ident.Obj] = []string{sel.Sel.Name}
				} else {
					found := false
					for _, selname := range selectors {
						if selname == sel.Sel.Name {
							pos := v.fset.Position(node.Pos())
							fmt.Printf("%s:%d: Repeating defer %s.%s() inside function %s\n",
								pos.Filename, pos.Line,
								ident.Name, selname, v.funcName)
							found = true
							exitStatus = 1
							break
						}
					}
					if !found {
						v.m[ident.Obj] = append(selectors, sel.Sel.Name)
					}
				}
			}
		}
	}
	return v
}

func main() {
	flag.Parse()
	exitStatus = 0
	importPaths := gotool.ImportPaths(flag.Args())
	if len(importPaths) == 0 {
		importPaths = []string{"."}
	}
	for _, pkgPath := range importPaths {
		visitor := &visitor{}
		fset, astFiles := check.ASTFilesForPackage(pkgPath, false)
		visitor.fset = fset
		for _, f := range astFiles {
			ast.Walk(visitor, f)
		}
	}
	os.Exit(exitStatus)
}
