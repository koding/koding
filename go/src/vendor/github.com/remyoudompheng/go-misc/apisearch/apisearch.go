// apisearch searches in API files produced by go api.
//
// Usage: apisearch [-f apifile.txt] -e pattern
// pattern is a function signature where single runes are placeholders.
// - func (a, b, b) bool matches func (*int32, int32, int32) bool
// - func (*a) unsafe.Pointer matches func (*unsafe.Pointer) unsafe.Pointer
// - func ([]a, a) int matches func ([]float64, float64) int
package main

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"go/ast"
	"go/parser"
	"go/printer"
	"go/token"
	"io"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

func main() {
	var pattern, filename string
	flag.StringVar(&pattern, "e", "", "pattern to look up")
	flag.StringVar(&filename, "f", filepath.Join(runtime.GOROOT(), "api", "go1.txt"), "filename to search in")
	flag.Parse()
	if pattern == "" {
		flag.Usage()
		return
	}
	log.SetFlags(0)

	pat, err := ParsePattern(pattern)
	if err != nil {
		log.Fatalf("cannot parse pattern: %s", err)
	}
	log.Printf("using pattern: %s", printNode(pat))

	log.Printf("looking in %q\n", filename)
	r, err := os.Open(filename)
	if err != nil {
		log.Fatalf("cannot open %s: %s", filename, err)
	}
	defer r.Close()

	// scan := bufio.NewScanner(r)
	scan := bufio.NewReader(r)
	for { // scan.Scan()
		line, err := scan.ReadString('\n') // scan.Text()
		switch err {
		case io.EOF:
			return
		case nil:
		default:
			log.Fatalf("I/O error: %s", err)
		}
		line = strings.TrimSpace(line)
		pkg, name, kind, val := SplitApi(line)
		if kind == "func" && Match(pat, val) {
			// print matches to Stdout.
			fmt.Printf("%s.%s: %s\n", pkg, name, val)
		}
	}
	//err = scan.Err()
	//if err != nil {
	//	log.Fatal(err)
	//}
}

func printNode(node ast.Node) string {
	buf := new(bytes.Buffer)
	printer.Fprint(buf, token.NewFileSet(), node)
	return buf.String()
}

func ParsePattern(pat string) (ast.Expr, error) {
	// Must be a type.
	file, err := parser.ParseFile(token.NewFileSet(), "", "package p; type _ "+pat, 0)
	if err != nil {
		return nil, err
	}
	return file.Decls[0].(*ast.GenDecl).Specs[0].(*ast.TypeSpec).Type, nil
}

func SplitApi(line string) (pkg, name, kind, val string) {
	parts := strings.SplitN(line, ", ", 2)
	pkg = strings.Fields(parts[0])[1]
	rhs := strings.SplitN(parts[1], " ", 2)
	kind = rhs[0]
	switch kind {
	case "func":
		par := strings.Index(rhs[1], "(")
		name = rhs[1][:par]
		val = "func " + rhs[1][par:]
	default:
		name = strings.Fields(rhs[1])[0]
		val = rhs[1]
	}
	return
}

func Match(pattern ast.Expr, sig string) bool {
	sigt, err := ParsePattern(sig)
	if err != nil {
		log.Fatalf("could not parse %q: %s", sig, err)
	}
	bindings := make(map[rune]string)
	var match func(pattern, x ast.Expr) bool
	match = func(pattern, x ast.Expr) bool {
		switch pat := pattern.(type) {
		case *ast.Ident:
			if len(pat.Name) < 4 && len([]rune(pat.Name)) == 1 {
				for _, c := range pat.Name {
					if bind, ok := bindings[c]; ok {
						return bind == printNode(x)
					} else {
						bindings[c] = printNode(x)
						return true
					}
				}
			}
			x, ok := x.(*ast.Ident)
			if !ok {
				return false
			}
			return pat.Name == x.Name
		case *ast.SelectorExpr:
			x, ok := x.(*ast.SelectorExpr)
			return ok && match(pat.X, x.X) && pat.Sel.Name == x.Sel.Name
		case *ast.ArrayType:
			x, ok := x.(*ast.ArrayType)
			if !ok {
				return false
			}
			// TODO: arrays.
			if pat.Len == nil {
				return x.Len == nil && match(pat.Elt, x.Elt)
			}
		case *ast.FuncType:
			x, ok := x.(*ast.FuncType)
			if !ok {
				return false
			}
			if pat.Params.NumFields() != x.Params.NumFields() ||
				pat.Results.NumFields() != x.Results.NumFields() {
				return false
			}
			var left, right []*ast.Field
			if pat.Params != nil {
				left = append(left, pat.Params.List...)
				right = append(right, x.Params.List...)
			}
			if pat.Results != nil {
				left = append(left, pat.Results.List...)
				right = append(right, x.Results.List...)
			}
			for i, fpat := range left {
				fx := right[i]
				if fpat.Names != nil || fx.Names != nil {
					log.Fatalf("did not expect arg names in matching %s and %s",
						printNode(pat), printNode(x))
				}
				if !match(fpat.Type, fx.Type) {
					return false
				}
			}
			return true
		case *ast.Ellipsis:
			x, ok := x.(*ast.Ellipsis)
			return ok && match(pat.Elt, x.Elt)
		case *ast.InterfaceType:
			x, ok := x.(*ast.InterfaceType)
			if !ok {
				return false
			}
			// TODO: non-empty interfaces.
			if pat.Methods.NumFields() == 0 {
				// interface{}
				return x.Methods.NumFields() == 0
			}
		case *ast.StarExpr:
			x, ok := x.(*ast.StarExpr)
			return ok && match(pat.X, x.X)
		case *ast.ChanType:
			x, ok := x.(*ast.ChanType)
			return ok && pat.Dir == x.Dir && match(pat.Value, x.Value)
		case *ast.MapType:
			x, ok := x.(*ast.MapType)
			return ok && match(pat.Key, x.Key) && match(pat.Value, x.Value)
		}
		// TODO: structs, parenExprs
		log.Fatalf("Match %T is not implemented", pattern)
		return false
	}
	return match(pattern, sigt)
}
