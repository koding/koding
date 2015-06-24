package config

import (
	"fmt"
	"io/ioutil"
	"os"
	"reflect"
	"testing"

	"github.com/hashicorp/terraform/config/lang"
	"github.com/hashicorp/terraform/config/lang/ast"
)

func TestInterpolateFuncConcat(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Cases: []testFunctionCase{
			{
				`${concat("foo", "bar")}`,
				"foobar",
				false,
			},

			{
				`${concat("foo")}`,
				"foo",
				false,
			},

			{
				`${concat()}`,
				nil,
				true,
			},
		},
	})
}

func TestInterpolateFuncFile(t *testing.T) {
	tf, err := ioutil.TempFile("", "tf")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	path := tf.Name()
	tf.Write([]byte("foo"))
	tf.Close()
	defer os.Remove(path)

	testFunction(t, testFunctionConfig{
		Cases: []testFunctionCase{
			{
				fmt.Sprintf(`${file("%s")}`, path),
				"foo",
				false,
			},

			// Invalid path
			{
				`${file("/i/dont/exist")}`,
				nil,
				true,
			},

			// Too many args
			{
				`${file("foo", "bar")}`,
				nil,
				true,
			},
		},
	})
}

func TestInterpolateFuncFormat(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Cases: []testFunctionCase{
			{
				`${format("hello")}`,
				"hello",
				false,
			},

			{
				`${format("hello %s", "world")}`,
				"hello world",
				false,
			},

			{
				`${format("hello %d", 42)}`,
				"hello 42",
				false,
			},

			{
				`${format("hello %05d", 42)}`,
				"hello 00042",
				false,
			},

			{
				`${format("hello %05d", 12345)}`,
				"hello 12345",
				false,
			},
		},
	})
}

func TestInterpolateFuncFormatList(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Cases: []testFunctionCase{
			// formatlist requires at least one list
			{
				`${formatlist("hello")}`,
				nil,
				true,
			},
			{
				`${formatlist("hello %s", "world")}`,
				nil,
				true,
			},
			// formatlist applies to each list element in turn
			{
				`${formatlist("<%s>", split(",", "A,B"))}`,
				"<A>" + InterpSplitDelim + "<B>",
				false,
			},
			// formatlist repeats scalar elements
			{
				`${join(", ", formatlist("%s=%s", "x", split(",", "A,B,C")))}`,
				"x=A, x=B, x=C",
				false,
			},
			// Multiple lists are walked in parallel
			{
				`${join(", ", formatlist("%s=%s", split(",", "A,B,C"), split(",", "1,2,3")))}`,
				"A=1, B=2, C=3",
				false,
			},
			// formatlist of lists of length zero/one are repeated, just as scalars are
			{
				`${join(", ", formatlist("%s=%s", split(",", ""), split(",", "1,2,3")))}`,
				"=1, =2, =3",
				false,
			},
			{
				`${join(", ", formatlist("%s=%s", split(",", "A"), split(",", "1,2,3")))}`,
				"A=1, A=2, A=3",
				false,
			},
			// Mismatched list lengths generate an error
			{
				`${formatlist("%s=%2s", split(",", "A,B,C,D"), split(",", "1,2,3"))}`,
				nil,
				true,
			},
		},
	})
}

func TestInterpolateFuncJoin(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Cases: []testFunctionCase{
			{
				`${join(",")}`,
				nil,
				true,
			},

			{
				`${join(",", "foo")}`,
				"foo",
				false,
			},

			/*
				TODO
				{
					`${join(",", "foo", "bar")}`,
					"foo,bar",
					false,
				},
			*/

			{
				fmt.Sprintf(`${join(".", "%s")}`,
					fmt.Sprintf(
						"foo%sbar%sbaz",
						InterpSplitDelim,
						InterpSplitDelim)),
				"foo.bar.baz",
				false,
			},
		},
	})
}

func TestInterpolateFuncReplace(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Cases: []testFunctionCase{
			// Regular search and replace
			{
				`${replace("hello", "hel", "bel")}`,
				"bello",
				false,
			},

			// Search string doesn't match
			{
				`${replace("hello", "nope", "bel")}`,
				"hello",
				false,
			},

			// Regular expression
			{
				`${replace("hello", "/l/", "L")}`,
				"heLLo",
				false,
			},

			{
				`${replace("helo", "/(l)/", "$1$1")}`,
				"hello",
				false,
			},

			// Bad regexp
			{
				`${replace("helo", "/(l/", "$1$1")}`,
				nil,
				true,
			},
		},
	})
}

func TestInterpolateFuncLength(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Cases: []testFunctionCase{
			// Raw strings
			{
				`${length("")}`,
				"0",
				false,
			},
			{
				`${length("a")}`,
				"1",
				false,
			},
			{
				`${length(" ")}`,
				"1",
				false,
			},
			{
				`${length(" a ,")}`,
				"4",
				false,
			},
			{
				`${length("aaa")}`,
				"3",
				false,
			},

			// Lists
			{
				`${length(split(",", "a"))}`,
				"1",
				false,
			},
			{
				`${length(split(",", "foo,"))}`,
				"2",
				false,
			},
			{
				`${length(split(",", ",foo,"))}`,
				"3",
				false,
			},
			{
				`${length(split(",", "foo,bar"))}`,
				"2",
				false,
			},
			{
				`${length(split(".", "one.two.three.four.five"))}`,
				"5",
				false,
			},
		},
	})
}

func TestInterpolateFuncSplit(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Cases: []testFunctionCase{
			{
				`${split(",")}`,
				nil,
				true,
			},

			{
				`${split(",", "foo")}`,
				"foo",
				false,
			},

			{
				`${split(",", ",,,")}`,
				fmt.Sprintf(
					"%s%s%s",
					InterpSplitDelim,
					InterpSplitDelim,
					InterpSplitDelim),
				false,
			},

			{
				`${split(",", "foo,")}`,
				fmt.Sprintf(
					"%s%s",
					"foo",
					InterpSplitDelim),
				false,
			},

			{
				`${split(",", ",foo,")}`,
				fmt.Sprintf(
					"%s%s%s",
					InterpSplitDelim,
					"foo",
					InterpSplitDelim),
				false,
			},

			{
				`${split(".", "foo.bar.baz")}`,
				fmt.Sprintf(
					"foo%sbar%sbaz",
					InterpSplitDelim,
					InterpSplitDelim),
				false,
			},
		},
	})
}

func TestInterpolateFuncLookup(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Vars: map[string]ast.Variable{
			"var.foo.bar": ast.Variable{
				Value: "baz",
				Type:  ast.TypeString,
			},
		},
		Cases: []testFunctionCase{
			{
				`${lookup("foo", "bar")}`,
				"baz",
				false,
			},

			// Invalid key
			{
				`${lookup("foo", "baz")}`,
				nil,
				true,
			},

			// Too many args
			{
				`${lookup("foo", "bar", "baz")}`,
				nil,
				true,
			},
		},
	})
}

func TestInterpolateFuncKeys(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Vars: map[string]ast.Variable{
			"var.foo.bar": ast.Variable{
				Value: "baz",
				Type:  ast.TypeString,
			},
			"var.foo.qux": ast.Variable{
				Value: "quack",
				Type:  ast.TypeString,
			},
			"var.str": ast.Variable{
				Value: "astring",
				Type:  ast.TypeString,
			},
		},
		Cases: []testFunctionCase{
			{
				`${keys("foo")}`,
				fmt.Sprintf(
					"bar%squx",
					InterpSplitDelim),
				false,
			},

			// Invalid key
			{
				`${keys("not")}`,
				nil,
				true,
			},

			// Too many args
			{
				`${keys("foo", "bar")}`,
				nil,
				true,
			},

			// Not a map
			{
				`${keys("str")}`,
				nil,
				true,
			},
		},
	})
}

func TestInterpolateFuncValues(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Vars: map[string]ast.Variable{
			"var.foo.bar": ast.Variable{
				Value: "quack",
				Type:  ast.TypeString,
			},
			"var.foo.qux": ast.Variable{
				Value: "baz",
				Type:  ast.TypeString,
			},
			"var.str": ast.Variable{
				Value: "astring",
				Type:  ast.TypeString,
			},
		},
		Cases: []testFunctionCase{
			{
				`${values("foo")}`,
				fmt.Sprintf(
					"quack%sbaz",
					InterpSplitDelim),
				false,
			},

			// Invalid key
			{
				`${values("not")}`,
				nil,
				true,
			},

			// Too many args
			{
				`${values("foo", "bar")}`,
				nil,
				true,
			},

			// Not a map
			{
				`${values("str")}`,
				nil,
				true,
			},
		},
	})
}

func TestInterpolateFuncElement(t *testing.T) {
	testFunction(t, testFunctionConfig{
		Cases: []testFunctionCase{
			{
				fmt.Sprintf(`${element("%s", "1")}`,
					"foo"+InterpSplitDelim+"baz"),
				"baz",
				false,
			},

			{
				`${element("foo", "0")}`,
				"foo",
				false,
			},

			// Invalid index should wrap vs. out-of-bounds
			{
				fmt.Sprintf(`${element("%s", "2")}`,
					"foo"+InterpSplitDelim+"baz"),
				"foo",
				false,
			},

			// Too many args
			{
				fmt.Sprintf(`${element("%s", "0", "2")}`,
					"foo"+InterpSplitDelim+"baz"),
				nil,
				true,
			},
		},
	})
}

type testFunctionConfig struct {
	Cases []testFunctionCase
	Vars  map[string]ast.Variable
}

type testFunctionCase struct {
	Input  string
	Result interface{}
	Error  bool
}

func testFunction(t *testing.T, config testFunctionConfig) {
	for i, tc := range config.Cases {
		ast, err := lang.Parse(tc.Input)
		if err != nil {
			t.Fatalf("%d: err: %s", i, err)
		}

		out, _, err := lang.Eval(ast, langEvalConfig(config.Vars))
		if (err != nil) != tc.Error {
			t.Fatalf("%d: err: %s", i, err)
		}

		if !reflect.DeepEqual(out, tc.Result) {
			t.Fatalf(
				"%d: bad output for input: %s\n\nOutput: %#v\nExpected: %#v",
				i, tc.Input, out, tc.Result)
		}
	}
}
