// fuzzgcexpr generates random arithmetic expressions and tests
// for appropriate compilation.
package main

import (
	"bytes"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
	"reflect"
	"time"

	"go/ast"
	"go/parser"
	"go/printer"
	"go/token"
	"text/template"
)

type Value struct {
	val  reflect.Value
	expr ast.Expr
	sgn  bool
}

var dummy = token.NewFileSet()

func (v Value) Decl() string {
	t := v.val.Type().String()
	val := &ast.BasicLit{
		Kind:  token.INT,
		Value: fmt.Sprint(v.Value()),
	}
	stmt := &ast.AssignStmt{
		Lhs: []ast.Expr{v.expr},
		Tok: token.DEFINE,
		Rhs: []ast.Expr{cvtExpr(t, val)},
	}
	buf := new(bytes.Buffer)
	printer.Fprint(buf, dummy, stmt)
	return buf.String()
}

func (v Value) String() string {
	buf := new(bytes.Buffer)
	printer.Fprint(buf, dummy, v.expr)
	return buf.String()
}

func (v Value) Value() int64 {
	if v.sgn {
		return v.val.Int()
	}
	return int64(v.val.Uint())
}

var stypes = []reflect.Type{
	reflect.TypeOf(int(0)),
	reflect.TypeOf(int8(0)),
	reflect.TypeOf(int16(0)),
	reflect.TypeOf(int32(0)),
	reflect.TypeOf(int64(0)),
}

var utypes = []reflect.Type{
	reflect.TypeOf(uint(0)),
	reflect.TypeOf(uint8(0)),
	reflect.TypeOf(uint16(0)),
	reflect.TypeOf(uint32(0)),
	reflect.TypeOf(uint64(0)),
	reflect.TypeOf(uintptr(0)),
}

func cvtExpr(typ string, expr ast.Expr) *ast.CallExpr {
	f := ast.NewIdent(typ)
	return &ast.CallExpr{Fun: f, Args: []ast.Expr{expr}}
}

var ops = []token.Token{
	token.ADD,
	token.SUB,
	token.MUL,
	token.AND,
}

func opVal(op token.Token, a, b int64) (v int64) {
	switch op {
	case token.ADD:
		v = a + b
	case token.SUB:
		v = a - b
	case token.MUL:
		v = a * b
	case token.AND:
		v = a & b
	}
	return
}

func Op(op token.Token, a, b Value) Value {
	ta, tb := a.val.Type(), b.val.Type()
	expr := &ast.BinaryExpr{Op: op, X: a.expr, Y: b.expr}
	if tb != ta {
		expr.Y = cvtExpr(ta.String(), expr.Y)
	}
	val := reflect.New(ta).Elem()
	v := opVal(op, a.Value(), b.Value())
	if a.sgn {
		val.SetInt(v)
	} else {
		val.SetUint(uint64(v))
	}
	if rand.Intn(2) == 1 && op != token.SUB {
		expr.X, expr.Y = expr.Y, expr.X
	}
	return Value{val, expr, a.sgn}
}

var id int

func randTree(n int) (tree Value, atoms []Value) {
	if n == 1 {
		id++
		name := fmt.Sprintf("v%d", id)
		sgn := rand.Intn(2) == 1
		var t reflect.Type
		switch types {
		case "int":
			sgn = true
			t = reflect.TypeOf(0)
		case "byte":
			sgn = false
			t = reflect.TypeOf(byte(0))
		default:
			if sgn {
				t = stypes[rand.Intn(len(stypes))]
			} else {
				t = utypes[rand.Intn(len(utypes))]
			}
		}
		val := reflect.New(t).Elem()
		if sgn {
			val.SetInt(1)
		} else {
			val.SetUint(1)
		}
		tree = Value{val, ast.NewIdent(name), sgn}
		return tree, []Value{tree}
	}

	na := 1 + rand.Intn(n-1) // 0 < na < n
	if linear {
		na = 1 + rand.Intn(2)*(n-2)
	}
	nb := n - na
	t1, atoms1 := randTree(na)
	t2, atoms2 := randTree(nb)
	op := ops[rand.Intn(len(ops))]
	tree = Op(op, t1, t2)
	atoms = append(atoms, atoms1...)
	atoms = append(atoms, atoms2...)
	return
}

var srcTpl = template.Must(template.New("src").Parse(`
package main

import "fmt"

func main() {
	{{ range $atom := $.Atoms }}
	{{ $atom.Decl }}{{ end }}
	result := {{ $.Tree }}
	fmt.Println(int64(result), int64({{ $.Tree.Value }}))
}
`))

// generate produces a source file with a random
// arithmetic expression.
func generate(n int) []byte {
	type Data struct {
		Tree  Value
		Atoms []Value
	}
	var data Data
	data.Tree, data.Atoms = randTree(n)
	buf := new(bytes.Buffer)
	srcTpl.Execute(buf, data)
	// gofmt.
	fs := token.NewFileSet()
	f, err := parser.ParseFile(fs, "dummy.go", buf, 0)
	if err != nil {
		panic(err)
	}
	buf.Reset()
	printer.Fprint(buf, fs, f)
	return buf.Bytes()
}

var linear bool
var types string

func main() {
	var random bool
	var outdir string
	var n int
	flag.BoolVar(&random, "random", false, "be random")
	flag.StringVar(&types, "type", "int", "only this type")
	flag.BoolVar(&linear, "linear", false, "produce linear trees")
	flag.StringVar(&outdir, "out", "tmp", "output directory")
	flag.IntVar(&n, "n", 25, "expression size")
	flag.Parse()
	if random {
		rand.Seed(time.Now().UnixNano())
	}
	os.MkdirAll(outdir, 0755)
	for i := 0; i < 10; i++ {
		id = 0
		data := generate(n)
		f, err := os.Create(filepath.Join(outdir, fmt.Sprintf("dummy%02d.go", i+1)))
		if err != nil {
			panic(err)
		}
		f.Write(data)
		f.Close()
	}
}
