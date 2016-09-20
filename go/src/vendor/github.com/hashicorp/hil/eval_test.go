package hil

import (
	"reflect"
	"strconv"
	"testing"

	"github.com/hashicorp/hil/ast"
)

func TestEval(t *testing.T) {
	cases := []struct {
		Input      string
		Scope      *ast.BasicScope
		Error      bool
		Result     interface{}
		ResultType EvalType
	}{
		{
			Input:      "Hello World",
			Scope:      nil,
			Result:     "Hello World",
			ResultType: TypeString,
		},
		{
			"${var.alist}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"var.alist": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "Hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "World",
							},
						},
					},
				},
			},
			false,
			[]interface{}{"Hello", "World"},
			TypeList,
		},
		{
			"${var.alist[1]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"var.alist": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "Hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "World",
							},
						},
					},
				},
			},
			false,
			"World",
			TypeString,
		},
		{
			"${var.alist[1]} ${var.alist[0]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"var.alist": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "Hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "World",
							},
						},
					},
				},
			},
			false,
			"World Hello",
			TypeString,
		},
		{
			"${var.alist} ${var.alist}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"var.alist": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "Hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "World",
							},
						},
					},
				},
			},
			true,
			nil,
			TypeInvalid,
		},
		{
			`${foo}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeMap,
						Value: map[string]ast.Variable{
							"foo": ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							"bar": ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
				},
			},
			false,
			map[string]interface{}{
				"foo": "hello",
				"bar": "world",
			},
			TypeMap,
		},
		{
			`${foo["bar"]}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeMap,
						Value: map[string]ast.Variable{
							"foo": ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							"bar": ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
				},
			},
			false,
			"world",
			TypeString,
		},
		{
			`${foo["bar"]} ${foo["foo"]}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeMap,
						Value: map[string]ast.Variable{
							"foo": ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							"bar": ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
				},
			},
			false,
			"world hello",
			TypeString,
		},
		{
			`${foo} ${foo}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeMap,
						Value: map[string]ast.Variable{
							"foo": ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							"bar": ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
				},
			},
			true,
			nil,
			TypeInvalid,
		},
		{
			`${foo} ${bar}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type:  ast.TypeString,
						Value: "Hello",
					},
					"bar": ast.Variable{
						Type:  ast.TypeString,
						Value: "World",
					},
				},
			},
			false,
			"Hello World",
			TypeString,
		},
		{
			`${foo} ${bar}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type:  ast.TypeString,
						Value: "Hello",
					},
					"bar": ast.Variable{
						Type:  ast.TypeInt,
						Value: 4,
					},
				},
			},
			false,
			"Hello 4",
			TypeString,
		},
		{
			`${foo}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeMap,
						Value: map[string]ast.Variable{
							"foo": ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							"bar": ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
				},
			},
			false,
			map[string]interface{}{
				"foo": "hello",
				"bar": "world",
			},
			TypeMap,
		},
		{
			"${var.alist}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"var.alist": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "Hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "World",
							},
						},
					},
				},
			},
			false,
			[]interface{}{
				"Hello",
				"World",
			},
			TypeList,
		},
	}

	for _, tc := range cases {
		node, err := Parse(tc.Input)
		if err != nil {
			t.Fatalf("Error: %s\n\nInput: %s", err, tc.Input)
		}

		result, err := Eval(node, &EvalConfig{GlobalScope: tc.Scope})
		if err != nil != tc.Error {
			t.Fatalf("Error: %s\n\nInput: %s", err, tc.Input)
		}
		if tc.ResultType != TypeInvalid && result.Type != tc.ResultType {
			t.Fatalf("Bad: %s\n\nInput: %s", result.Type, tc.Input)
		}
		if !reflect.DeepEqual(result.Value, tc.Result) {
			t.Fatalf("\n     Bad: %#v\nExpected: %#v\n\nInput: %s", result.Value, tc.Result, tc.Input)
		}
	}
}

func TestEvalInternal(t *testing.T) {
	cases := []struct {
		Input      string
		Scope      *ast.BasicScope
		Error      bool
		Result     interface{}
		ResultType ast.Type
	}{
		{
			"foo",
			nil,
			false,
			"foo",
			ast.TypeString,
		},

		{
			"foo ${bar}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"bar": ast.Variable{
						Value: "baz",
						Type:  ast.TypeString,
					},
				},
			},
			false,
			"foo baz",
			ast.TypeString,
		},

		{
			"${var.alist}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"var.alist": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "Hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "World",
							},
						},
					},
				},
			},
			false,
			[]ast.Variable{
				ast.Variable{
					Type:  ast.TypeString,
					Value: "Hello",
				},
				ast.Variable{
					Type:  ast.TypeString,
					Value: "World",
				},
			},
			ast.TypeList,
		},

		{
			"foo ${-29}",
			nil,
			false,
			"foo -29",
			ast.TypeString,
		},

		{
			"foo ${42+1}",
			nil,
			false,
			"foo 43",
			ast.TypeString,
		},

		{
			"foo ${42-1}",
			nil,
			false,
			"foo 41",
			ast.TypeString,
		},

		{
			"foo ${42*2}",
			nil,
			false,
			"foo 84",
			ast.TypeString,
		},

		{
			"foo ${42/2}",
			nil,
			false,
			"foo 21",
			ast.TypeString,
		},

		{
			"foo ${42/0}",
			nil,
			true,
			"foo ",
			ast.TypeInvalid,
		},

		{
			"foo ${42%4}",
			nil,
			false,
			"foo 2",
			ast.TypeString,
		},

		{
			"foo ${42%0}",
			nil,
			true,
			"foo ",
			ast.TypeInvalid,
		},

		{
			"foo ${42.0+1.0}",
			nil,
			false,
			"foo 43",
			ast.TypeString,
		},

		{
			"foo ${42.0+1}",
			nil,
			false,
			"foo 43",
			ast.TypeString,
		},

		{
			"foo ${42+1.0}",
			nil,
			false,
			"foo 43",
			ast.TypeString,
		},

		{
			"foo ${42+2*2}",
			nil,
			false,
			"foo 88",
			ast.TypeString,
		},

		{
			"foo ${42+(2*2)}",
			nil,
			false,
			"foo 46",
			ast.TypeString,
		},

		{
			"foo ${-bar}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"bar": ast.Variable{
						Value: 41,
						Type:  ast.TypeInt,
					},
				},
			},
			false,
			"foo -41",
			ast.TypeString,
		},

		{
			"foo ${bar+1}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"bar": ast.Variable{
						Value: 41,
						Type:  ast.TypeInt,
					},
				},
			},
			false,
			"foo 42",
			ast.TypeString,
		},

		{
			"foo ${bar+1}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"bar": ast.Variable{
						Value: "41",
						Type:  ast.TypeString,
					},
				},
			},
			false,
			"foo 42",
			ast.TypeString,
		},

		{
			"foo ${bar+baz}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"bar": ast.Variable{
						Value: "41",
						Type:  ast.TypeString,
					},
					"baz": ast.Variable{
						Value: "1",
						Type:  ast.TypeString,
					},
				},
			},
			false,
			"foo 42",
			ast.TypeString,
		},

		{
			"foo ${rand()}",
			&ast.BasicScope{
				FuncMap: map[string]ast.Function{
					"rand": ast.Function{
						ReturnType: ast.TypeString,
						Callback: func([]interface{}) (interface{}, error) {
							return "42", nil
						},
					},
				},
			},
			false,
			"foo 42",
			ast.TypeString,
		},

		{
			`foo ${rand("foo", "bar")}`,
			&ast.BasicScope{
				FuncMap: map[string]ast.Function{
					"rand": ast.Function{
						ReturnType:   ast.TypeString,
						Variadic:     true,
						VariadicType: ast.TypeString,
						Callback: func(args []interface{}) (interface{}, error) {
							var result string
							for _, a := range args {
								result += a.(string)
							}
							return result, nil
						},
					},
				},
			},
			false,
			"foo foobar",
			ast.TypeString,
		},

		{
			`${foo["bar"]}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
				},
			},
			true,
			nil,
			ast.TypeInvalid,
		},

		{
			`${foo["bar"]}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeMap,
						Value: map[string]ast.Variable{
							"foo": ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							"bar": ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
				},
			},
			false,
			"world",
			ast.TypeString,
		},

		{
			`${foo[var.key]}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeMap,
						Value: map[string]ast.Variable{
							"foo": ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							"bar": ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
					"var.key": ast.Variable{
						Type:  ast.TypeString,
						Value: "bar",
					},
				},
			},
			false,
			"world",
			ast.TypeString,
		},

		{
			`${foo[bar[var.keyint]]}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeMap,
						Value: map[string]ast.Variable{
							"foo": ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							"bar": ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
					"bar": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "i dont exist",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "bar",
							},
						},
					},
					"var.keyint": ast.Variable{
						Type:  ast.TypeInt,
						Value: 1,
					},
				},
			},
			false,
			"world",
			ast.TypeString,
		},

		{
			`${foo["bar"]} ${bar[1]}`,
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeMap,
						Value: map[string]ast.Variable{
							"foo": ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							"bar": ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
					"bar": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 10,
							},
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 20,
							},
						},
					},
				},
			},
			false,
			"world 20",
			ast.TypeString,
		},

		{
			"${foo[0]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
				},
			},
			false,
			"hello",
			ast.TypeString,
		},

		{
			"${foo[bar]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
					"bar": ast.Variable{
						Type:  ast.TypeInt,
						Value: 1,
					},
				},
			},
			false,
			"world",
			ast.TypeString,
		},

		{
			"${foo[bar[1]]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
					"bar": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 1,
							},
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 0,
							},
						},
					},
				},
			},
			false,
			"hello",
			ast.TypeString,
		},

		{
			"aaa ${foo} aaa",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type:  ast.TypeInt,
						Value: 42,
					},
				},
			},
			false,
			"aaa 42 aaa",
			ast.TypeString,
		},

		{
			"aaa ${foo[1]} aaa",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 42,
							},
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 24,
							},
						},
					},
				},
			},
			false,
			"aaa 24 aaa",
			ast.TypeString,
		},

		{
			"aaa ${foo[1]} - ${foo[0]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 42,
							},
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 24,
							},
						},
					},
				},
			},
			false,
			"aaa 24 - 42",
			ast.TypeString,
		},

		{
			"${var.foo} ${var.foo[0]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"var.foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
				},
			},
			true,
			nil,
			ast.TypeInvalid,
		},

		{
			"${var.foo[0]} ${var.foo[1]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"var.foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeString,
								Value: "hello",
							},
							ast.Variable{
								Type:  ast.TypeString,
								Value: "world",
							},
						},
					},
				},
			},
			false,
			"hello world",
			ast.TypeString,
		},

		{
			"${foo[1]} ${foo[0]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 42,
							},
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 24,
							},
						},
					},
				},
			},
			false,
			"24 42",
			ast.TypeString,
		},

		{
			"${foo[1-3]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 42,
							},
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 24,
							},
						},
					},
				},
			},
			true,
			nil,
			ast.TypeInvalid,
		},

		{
			"${foo[2]}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"foo": ast.Variable{
						Type: ast.TypeList,
						Value: []ast.Variable{
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 42,
							},
							ast.Variable{
								Type:  ast.TypeInt,
								Value: 24,
							},
						},
					},
				},
			},
			true,
			nil,
			ast.TypeInvalid,
		},

		// Testing implicit type conversions

		{
			"foo ${bar}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"bar": ast.Variable{
						Value: 42,
						Type:  ast.TypeInt,
					},
				},
			},
			false,
			"foo 42",
			ast.TypeString,
		},

		{
			`foo ${foo("42")}`,
			&ast.BasicScope{
				FuncMap: map[string]ast.Function{
					"foo": ast.Function{
						ArgTypes:   []ast.Type{ast.TypeInt},
						ReturnType: ast.TypeString,
						Callback: func(args []interface{}) (interface{}, error) {
							return strconv.FormatInt(int64(args[0].(int)), 10), nil
						},
					},
				},
			},
			false,
			"foo 42",
			ast.TypeString,
		},

		// Multiline
		{
			"foo ${42+\n1.0}",
			nil,
			false,
			"foo 43",
			ast.TypeString,
		},

		// String vars should be able to implictly convert to floats
		{
			"${1.5 * var.foo}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"var.foo": ast.Variable{
						Value: "42",
						Type:  ast.TypeString,
					},
				},
			},
			false,
			"63",
			ast.TypeString,
		},

		// Unary
		{
			"foo ${-46}",
			nil,
			false,
			"foo -46",
			ast.TypeString,
		},

		{
			"foo ${-46 + 5}",
			nil,
			false,
			"foo -41",
			ast.TypeString,
		},

		{
			"foo ${46 + -5}",
			nil,
			false,
			"foo 41",
			ast.TypeString,
		},

		{
			"foo ${-bar}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"bar": ast.Variable{
						Value: 41,
						Type:  ast.TypeInt,
					},
				},
			},
			false,
			"foo -41",
			ast.TypeString,
		},

		{
			"foo ${5 + -bar}",
			&ast.BasicScope{
				VarMap: map[string]ast.Variable{
					"bar": ast.Variable{
						Value: 41,
						Type:  ast.TypeInt,
					},
				},
			},
			false,
			"foo -36",
			ast.TypeString,
		},
	}

	for _, tc := range cases {
		node, err := Parse(tc.Input)
		if err != nil {
			t.Fatalf("Error: %s\n\nInput: %s", err, tc.Input)
		}

		out, outType, err := internalEval(node, &EvalConfig{GlobalScope: tc.Scope})
		if err != nil != tc.Error {
			t.Fatalf("Error: %s\n\nInput: %s", err, tc.Input)
		}
		if tc.ResultType != ast.TypeInvalid && outType != tc.ResultType {
			t.Fatalf("Bad: %s\n\nInput: %s", outType, tc.Input)
		}
		if !reflect.DeepEqual(out, tc.Result) {
			t.Fatalf("Bad: %#v\n\nInput: %s", out, tc.Input)
		}
	}
}
