package ast

import (
	"reflect"
	"strings"
	"testing"

	"github.com/hashicorp/hcl/hcl/token"
)

func TestObjectListFilter(t *testing.T) {
	var cases = []struct {
		Filter []string
		Input  []*ObjectItem
		Output []*ObjectItem
	}{
		{
			[]string{"foo"},
			[]*ObjectItem{
				&ObjectItem{
					Keys: []*ObjectKey{
						&ObjectKey{
							Token: token.Token{Type: token.STRING, Text: `"foo"`},
						},
					},
				},
			},
			[]*ObjectItem{
				&ObjectItem{
					Keys: []*ObjectKey{},
				},
			},
		},

		{
			[]string{"foo"},
			[]*ObjectItem{
				&ObjectItem{
					Keys: []*ObjectKey{
						&ObjectKey{Token: token.Token{Type: token.STRING, Text: `"foo"`}},
						&ObjectKey{Token: token.Token{Type: token.STRING, Text: `"bar"`}},
					},
				},
				&ObjectItem{
					Keys: []*ObjectKey{
						&ObjectKey{Token: token.Token{Type: token.STRING, Text: `"baz"`}},
					},
				},
			},
			[]*ObjectItem{
				&ObjectItem{
					Keys: []*ObjectKey{
						&ObjectKey{Token: token.Token{Type: token.STRING, Text: `"bar"`}},
					},
				},
			},
		},
	}

	for _, tc := range cases {
		input := &ObjectList{Items: tc.Input}
		expected := &ObjectList{Items: tc.Output}
		if actual := input.Filter(tc.Filter...); !reflect.DeepEqual(actual, expected) {
			t.Fatalf("in order: input, expected, actual\n\n%#v\n\n%#v\n\n%#v", input, expected, actual)
		}
	}
}

func TestRewrite(t *testing.T) {
	items := []*ObjectItem{
		&ObjectItem{
			Keys: []*ObjectKey{
				&ObjectKey{Token: token.Token{Type: token.STRING, Text: `"foo"`}},
				&ObjectKey{Token: token.Token{Type: token.STRING, Text: `"bar"`}},
			},
		},
		&ObjectItem{
			Keys: []*ObjectKey{
				&ObjectKey{Token: token.Token{Type: token.STRING, Text: `"baz"`}},
			},
		},
	}

	node := &ObjectList{Items: items}

	suffix := "_example"
	node = Rewrite(node, func(n Node) Node {
		switch i := n.(type) {
		case *ObjectKey:
			i.Token.Text = i.Token.Text + suffix
			n = i
		}
		return n
	}).(*ObjectList)

	Walk(node, func(n Node) bool {
		switch i := n.(type) {
		case *ObjectKey:
			if !strings.HasSuffix(i.Token.Text, suffix) {
				t.Errorf("Token '%s' should have suffix: %s", i.Token.Text, suffix)
			}
		}
		return true
	})

}
