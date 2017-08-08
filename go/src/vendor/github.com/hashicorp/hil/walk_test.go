package hil

import (
	"fmt"
	"reflect"
	"testing"
)

func TestInterpolationWalker_detect(t *testing.T) {
	cases := []struct {
		Input  interface{}
		Result []string
	}{
		{
			Input: map[string]interface{}{
				"foo": "$${var.foo}",
			},
			Result: []string{
				"Literal(TypeString, ${var.foo})",
			},
		},

		{
			Input: map[string]interface{}{
				"foo": "${var.foo}",
			},
			Result: []string{
				"Variable(var.foo)",
			},
		},

		{
			Input: map[string]interface{}{
				"foo": "${aws_instance.foo.*.num}",
			},
			Result: []string{
				"Variable(aws_instance.foo.*.num)",
			},
		},

		{
			Input: map[string]interface{}{
				"foo": "${lookup(var.foo)}",
			},
			Result: []string{
				"Call(lookup, Variable(var.foo))",
			},
		},

		{
			Input: map[string]interface{}{
				"foo": `${file("test.txt")}`,
			},
			Result: []string{
				"Call(file, Literal(TypeString, test.txt))",
			},
		},

		{
			Input: map[string]interface{}{
				"foo": `${file("foo/bar.txt")}`,
			},
			Result: []string{
				"Call(file, Literal(TypeString, foo/bar.txt))",
			},
		},

		{
			Input: map[string]interface{}{
				"foo": `${join(",", foo.bar.*.id)}`,
			},
			Result: []string{
				"Call(join, Literal(TypeString, ,), Variable(foo.bar.*.id))",
			},
		},

		{
			Input: map[string]interface{}{
				"foo": `${concat("localhost", ":8080")}`,
			},
			Result: []string{
				"Call(concat, Literal(TypeString, localhost), Literal(TypeString, :8080))",
			},
		},
	}

	for i, tc := range cases {
		t.Run(fmt.Sprintf("#%d", i), func(t *testing.T) {
			var actual []string
			detectFn := func(data *WalkData) error {
				actual = append(actual, fmt.Sprintf("%s", data.Root))
				return nil
			}

			if err := Walk(tc.Input, detectFn); err != nil {
				t.Fatalf("err: %s", err)
			}

			if !reflect.DeepEqual(actual, tc.Result) {
				t.Fatalf("%d: bad:\n\n%#v", i, actual)
			}
		})
	}
}

func TestInterpolationWalker_replace(t *testing.T) {
	cases := []struct {
		Input  interface{}
		Output interface{}
		Value  string
	}{
		{
			Input: map[string]interface{}{
				"foo": "$${var.foo}",
			},
			Output: map[string]interface{}{
				"foo": "bar",
			},
			Value: "bar",
		},

		{
			Input: map[string]interface{}{
				"foo": "hi, ${var.foo}",
			},
			Output: map[string]interface{}{
				"foo": "bar",
			},
			Value: "bar",
		},

		{
			Input: map[string]interface{}{
				"foo": map[string]interface{}{
					"${var.foo}": "bar",
				},
			},
			Output: map[string]interface{}{
				"foo": map[string]interface{}{
					"bar": "bar",
				},
			},
			Value: "bar",
		},

		/*
			{
				Input: map[string]interface{}{
					"foo": []interface{}{
						"${var.foo}",
						"bing",
					},
				},
				Output: map[string]interface{}{
					"foo": []interface{}{
						"bar",
						"baz",
						"bing",
					},
				},
				Value: NewStringList([]string{"bar", "baz"}).String(),
			},

			{
				Input: map[string]interface{}{
					"foo": []interface{}{
						"${var.foo}",
						"bing",
					},
				},
				Output: map[string]interface{}{},
				Value:  NewStringList([]string{UnknownVariableValue, "baz"}).String(),
			},
		*/
	}

	for i, tc := range cases {
		fn := func(data *WalkData) error {
			data.Replace = true
			data.ReplaceValue = tc.Value
			return nil
		}

		if err := Walk(tc.Input, fn); err != nil {
			t.Fatalf("err: %s", err)
		}

		if !reflect.DeepEqual(tc.Input, tc.Output) {
			t.Fatalf("%d: bad:\n\nexpected:%#v\ngot:%#v", i, tc.Output, tc.Input)
		}
	}
}
