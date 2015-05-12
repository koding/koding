// varcheck
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
	"os"

	"golang.org/x/tools/go/types"
	"honnef.co/go/importer"

	"github.com/kisielk/gotool"
	"github.com/opennota/check"
)

var (
	reportExported = flag.Bool("e", false, "Report exported variables and constants")
)

type visitor struct {
	pkg        *types.Package
	info       types.Info
	m          map[types.Object]int
	insideFunc bool
}

func (v *visitor) decl(obj types.Object) {
	if _, ok := v.m[obj]; !ok {
		v.m[obj] = 0
	}
}

func (v *visitor) use(obj types.Object) {
	if _, ok := v.m[obj]; ok {
		v.m[obj]++
	} else {
		v.m[obj] = 1
	}
}

func (v *visitor) Visit(node ast.Node) ast.Visitor {
	switch node := node.(type) {
	case *ast.Ident:
		v.use(v.info.Uses[node])

	case *ast.ValueSpec:
		if !v.insideFunc {
			for _, ident := range node.Names {
				if ident.Name != "_" {
					v.decl(v.info.Defs[ident])
				}
			}
		}
		for _, val := range node.Values {
			ast.Walk(v, val)
		}
		return nil

	case *ast.FuncDecl:
		if node.Body != nil {
			v.insideFunc = true
			ast.Walk(v, node.Body)
			v.insideFunc = false
		}

		return nil
	}

	return v
}

func main() {
	flag.Parse()
	exitStatus := 0
	importPaths := gotool.ImportPaths(flag.Args())
	if len(importPaths) == 0 {
		importPaths = []string{"."}
	}
	for _, pkgPath := range importPaths {
		visitor := &visitor{
			info: types.Info{
				Defs: make(map[*ast.Ident]types.Object),
				Uses: make(map[*ast.Ident]types.Object),
			},

			m: make(map[types.Object]int),
		}
		fset, astFiles := check.ASTFilesForPackage(pkgPath, false)
		imp := importer.New()
		// Preliminary cgo support.
		imp.Config = importer.Config{UseGcFallback: true}
		config := types.Config{Import: imp.Import}
		var err error
		visitor.pkg, err = config.Check(pkgPath, fset, astFiles, &visitor.info)
		if err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", pkgPath, err)
			continue
		}
		for _, f := range astFiles {
			ast.Walk(visitor, f)
		}
		for obj, useCount := range visitor.m {
			if useCount == 0 && (*reportExported || !ast.IsExported(obj.Name())) {
				pos := fset.Position(obj.Pos())
				fmt.Printf("%s:%d: %s\n", pos.Filename, pos.Line, obj.Name())
				exitStatus = 1
			}
		}
	}
	os.Exit(exitStatus)
}
