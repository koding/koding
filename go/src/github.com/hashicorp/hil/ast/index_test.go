package ast

import (
	"testing"
)

func TestIndexType_string(t *testing.T) {
	i := &Index{
		Target: &VariableAccess{Name: "foo"},
		Key: &LiteralNode{
			Typex: TypeInt,
			Value: 1,
		},
	}

	scope := &BasicScope{
		VarMap: map[string]Variable{
			"foo": Variable{
				Type: TypeList,
				Value: []Variable{
					Variable{
						Type:  TypeString,
						Value: "Hello",
					},
					Variable{
						Type:  TypeString,
						Value: "World",
					},
				},
			},
		},
	}

	actual, err := i.Type(scope)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if actual != TypeString {
		t.Fatalf("bad: %s", actual)
	}
}

func TestIndexType_int(t *testing.T) {
	i := &Index{
		Target: &VariableAccess{Name: "foo"},
		Key: &LiteralNode{
			Typex: TypeInt,
			Value: 1,
		},
	}

	scope := &BasicScope{
		VarMap: map[string]Variable{
			"foo": Variable{
				Type: TypeList,
				Value: []Variable{
					Variable{
						Type:  TypeInt,
						Value: 34,
					},
					Variable{
						Type:  TypeInt,
						Value: 54,
					},
				},
			},
		},
	}

	actual, err := i.Type(scope)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if actual != TypeInt {
		t.Fatalf("bad: %s", actual)
	}
}

func TestIndexType_nonHomogenous(t *testing.T) {
	i := &Index{
		Target: &VariableAccess{Name: "foo"},
		Key: &LiteralNode{
			Typex: TypeInt,
			Value: 1,
		},
	}

	scope := &BasicScope{
		VarMap: map[string]Variable{
			"foo": Variable{
				Type: TypeList,
				Value: []Variable{
					Variable{
						Type:  TypeString,
						Value: "Hello",
					},
					Variable{
						Type:  TypeInt,
						Value: 43,
					},
				},
			},
		},
	}

	_, err := i.Type(scope)
	if err == nil {
		t.Fatalf("expected error")
	}
}
