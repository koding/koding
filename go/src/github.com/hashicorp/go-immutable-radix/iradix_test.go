package iradix

import (
	"reflect"
	"sort"
	"testing"

	"github.com/hashicorp/uuid"
)

func CopyTree(t *Tree) *Tree {
	nt := &Tree{
		root: CopyNode(t.root),
		size: t.size,
	}
	return nt
}

func CopyNode(n *Node) *Node {
	nn := &Node{}
	if n.prefix != nil {
		nn.prefix = make([]byte, len(n.prefix))
		copy(nn.prefix, n.prefix)
	}
	if n.leaf != nil {
		nn.leaf = CopyLeaf(n.leaf)
	}
	if len(n.edges) != 0 {
		nn.edges = make([]edge, len(n.edges))
		for idx, edge := range n.edges {
			nn.edges[idx].label = edge.label
			nn.edges[idx].node = CopyNode(edge.node)
		}
	}
	return nn
}

func CopyLeaf(l *leafNode) *leafNode {
	ll := &leafNode{
		key: l.key,
		val: l.val,
	}
	return ll
}

func TestRadix_HugeTxn(t *testing.T) {
	r := New()

	// Insert way more nodes than the cache can fit
	txn1 := r.Txn()
	var expect []string
	for i := 0; i < defaultModifiedCache*100; i++ {
		gen := uuid.GenerateUUID()
		txn1.Insert([]byte(gen), i)
		expect = append(expect, gen)
	}
	r = txn1.Commit()
	sort.Strings(expect)

	// Collect the output, should be sorted
	var out []string
	fn := func(k []byte, v interface{}) bool {
		out = append(out, string(k))
		return false
	}
	r.Root().Walk(fn)

	// Verify the match
	if len(out) != len(expect) {
		t.Fatalf("length mis-match: %d vs %d", len(out), len(expect))
	}
	for i := 0; i < len(out); i++ {
		if out[i] != expect[i] {
			t.Fatalf("mis-match: %v %v", out[i], expect[i])
		}
	}
}

func TestRadix(t *testing.T) {
	var min, max string
	inp := make(map[string]interface{})
	for i := 0; i < 1000; i++ {
		gen := uuid.GenerateUUID()
		inp[gen] = i
		if gen < min || i == 0 {
			min = gen
		}
		if gen > max || i == 0 {
			max = gen
		}
	}

	r := New()
	rCopy := CopyTree(r)
	for k, v := range inp {
		newR, _, _ := r.Insert([]byte(k), v)
		if !reflect.DeepEqual(r, rCopy) {
			t.Errorf("r: %#v rc: %#v", r, rCopy)
			t.Errorf("r: %#v rc: %#v", r.root, rCopy.root)
			t.Fatalf("structure modified %d", newR.Len())
		}
		r = newR
		rCopy = CopyTree(r)
	}

	if r.Len() != len(inp) {
		t.Fatalf("bad length: %v %v", r.Len(), len(inp))
	}

	for k, v := range inp {
		out, ok := r.Get([]byte(k))
		if !ok {
			t.Fatalf("missing key: %v", k)
		}
		if out != v {
			t.Fatalf("value mis-match: %v %v", out, v)
		}
	}

	// Check min and max
	outMin, _, _ := r.Root().Minimum()
	if string(outMin) != min {
		t.Fatalf("bad minimum: %v %v", outMin, min)
	}
	outMax, _, _ := r.Root().Maximum()
	if string(outMax) != max {
		t.Fatalf("bad maximum: %v %v", outMax, max)
	}

	// Copy the full tree before delete
	orig := r
	origCopy := CopyTree(r)

	for k, v := range inp {
		tree, out, ok := r.Delete([]byte(k))
		r = tree
		if !ok {
			t.Fatalf("missing key: %v", k)
		}
		if out != v {
			t.Fatalf("value mis-match: %v %v", out, v)
		}
	}
	if r.Len() != 0 {
		t.Fatalf("bad length: %v", r.Len())
	}

	if !reflect.DeepEqual(orig, origCopy) {
		t.Fatalf("structure modified")
	}
}

func TestRoot(t *testing.T) {
	r := New()
	r, _, ok := r.Delete(nil)
	if ok {
		t.Fatalf("bad")
	}
	r, _, ok = r.Insert(nil, true)
	if ok {
		t.Fatalf("bad")
	}
	val, ok := r.Get(nil)
	if !ok || val != true {
		t.Fatalf("bad: %v %#v", val)
	}
	r, val, ok = r.Delete(nil)
	if !ok || val != true {
		t.Fatalf("bad: %v", val)
	}
}

func TestDelete(t *testing.T) {
	r := New()
	s := []string{"", "A", "AB"}

	for _, ss := range s {
		r, _, _ = r.Insert([]byte(ss), true)
	}

	var ok bool
	for _, ss := range s {
		r, _, ok = r.Delete([]byte(ss))
		if !ok {
			t.Fatalf("bad %q", ss)
		}
	}
}

func TestLongestPrefix(t *testing.T) {
	r := New()

	keys := []string{
		"",
		"foo",
		"foobar",
		"foobarbaz",
		"foobarbazzip",
		"foozip",
	}
	for _, k := range keys {
		r, _, _ = r.Insert([]byte(k), nil)
	}
	if r.Len() != len(keys) {
		t.Fatalf("bad len: %v %v", r.Len(), len(keys))
	}

	type exp struct {
		inp string
		out string
	}
	cases := []exp{
		{"a", ""},
		{"abc", ""},
		{"fo", ""},
		{"foo", "foo"},
		{"foob", "foo"},
		{"foobar", "foobar"},
		{"foobarba", "foobar"},
		{"foobarbaz", "foobarbaz"},
		{"foobarbazzi", "foobarbaz"},
		{"foobarbazzip", "foobarbazzip"},
		{"foozi", "foo"},
		{"foozip", "foozip"},
		{"foozipzap", "foozip"},
	}
	root := r.Root()
	for _, test := range cases {
		m, _, ok := root.LongestPrefix([]byte(test.inp))
		if !ok {
			t.Fatalf("no match: %v", test)
		}
		if string(m) != test.out {
			t.Fatalf("mis-match: %v %v", m, test)
		}
	}
}

func TestWalkPrefix(t *testing.T) {
	r := New()

	keys := []string{
		"foobar",
		"foo/bar/baz",
		"foo/baz/bar",
		"foo/zip/zap",
		"zipzap",
	}
	for _, k := range keys {
		r, _, _ = r.Insert([]byte(k), nil)
	}
	if r.Len() != len(keys) {
		t.Fatalf("bad len: %v %v", r.Len(), len(keys))
	}

	type exp struct {
		inp string
		out []string
	}
	cases := []exp{
		exp{
			"f",
			[]string{"foobar", "foo/bar/baz", "foo/baz/bar", "foo/zip/zap"},
		},
		exp{
			"foo",
			[]string{"foobar", "foo/bar/baz", "foo/baz/bar", "foo/zip/zap"},
		},
		exp{
			"foob",
			[]string{"foobar"},
		},
		exp{
			"foo/",
			[]string{"foo/bar/baz", "foo/baz/bar", "foo/zip/zap"},
		},
		exp{
			"foo/b",
			[]string{"foo/bar/baz", "foo/baz/bar"},
		},
		exp{
			"foo/ba",
			[]string{"foo/bar/baz", "foo/baz/bar"},
		},
		exp{
			"foo/bar",
			[]string{"foo/bar/baz"},
		},
		exp{
			"foo/bar/baz",
			[]string{"foo/bar/baz"},
		},
		exp{
			"foo/bar/bazoo",
			[]string{},
		},
		exp{
			"z",
			[]string{"zipzap"},
		},
	}

	root := r.Root()
	for _, test := range cases {
		out := []string{}
		fn := func(k []byte, v interface{}) bool {
			out = append(out, string(k))
			return false
		}
		root.WalkPrefix([]byte(test.inp), fn)
		sort.Strings(out)
		sort.Strings(test.out)
		if !reflect.DeepEqual(out, test.out) {
			t.Fatalf("mis-match: %v %v", out, test.out)
		}
	}
}

func TestWalkPath(t *testing.T) {
	r := New()

	keys := []string{
		"foo",
		"foo/bar",
		"foo/bar/baz",
		"foo/baz/bar",
		"foo/zip/zap",
		"zipzap",
	}
	for _, k := range keys {
		r, _, _ = r.Insert([]byte(k), nil)
	}
	if r.Len() != len(keys) {
		t.Fatalf("bad len: %v %v", r.Len(), len(keys))
	}

	type exp struct {
		inp string
		out []string
	}
	cases := []exp{
		exp{
			"f",
			[]string{},
		},
		exp{
			"foo",
			[]string{"foo"},
		},
		exp{
			"foo/",
			[]string{"foo"},
		},
		exp{
			"foo/ba",
			[]string{"foo"},
		},
		exp{
			"foo/bar",
			[]string{"foo", "foo/bar"},
		},
		exp{
			"foo/bar/baz",
			[]string{"foo", "foo/bar", "foo/bar/baz"},
		},
		exp{
			"foo/bar/bazoo",
			[]string{"foo", "foo/bar", "foo/bar/baz"},
		},
		exp{
			"z",
			[]string{},
		},
	}

	root := r.Root()
	for _, test := range cases {
		out := []string{}
		fn := func(k []byte, v interface{}) bool {
			out = append(out, string(k))
			return false
		}
		root.WalkPath([]byte(test.inp), fn)
		sort.Strings(out)
		sort.Strings(test.out)
		if !reflect.DeepEqual(out, test.out) {
			t.Fatalf("mis-match: %v %v", out, test.out)
		}
	}
}

func TestIteratePrefix(t *testing.T) {
	r := New()

	keys := []string{
		"foo/bar/baz",
		"foo/baz/bar",
		"foo/zip/zap",
		"foobar",
		"zipzap",
	}
	for _, k := range keys {
		r, _, _ = r.Insert([]byte(k), nil)
	}
	if r.Len() != len(keys) {
		t.Fatalf("bad len: %v %v", r.Len(), len(keys))
	}

	type exp struct {
		inp string
		out []string
	}
	cases := []exp{
		exp{
			"",
			keys,
		},
		exp{
			"f",
			[]string{
				"foo/bar/baz",
				"foo/baz/bar",
				"foo/zip/zap",
				"foobar",
			},
		},
		exp{
			"foo",
			[]string{
				"foo/bar/baz",
				"foo/baz/bar",
				"foo/zip/zap",
				"foobar",
			},
		},
		exp{
			"foob",
			[]string{"foobar"},
		},
		exp{
			"foo/",
			[]string{"foo/bar/baz", "foo/baz/bar", "foo/zip/zap"},
		},
		exp{
			"foo/b",
			[]string{"foo/bar/baz", "foo/baz/bar"},
		},
		exp{
			"foo/ba",
			[]string{"foo/bar/baz", "foo/baz/bar"},
		},
		exp{
			"foo/bar",
			[]string{"foo/bar/baz"},
		},
		exp{
			"foo/bar/baz",
			[]string{"foo/bar/baz"},
		},
		exp{
			"foo/bar/bazoo",
			[]string{},
		},
		exp{
			"z",
			[]string{"zipzap"},
		},
	}

	root := r.Root()
	for idx, test := range cases {
		iter := root.Iterator()
		if test.inp != "" {
			iter.SeekPrefix([]byte(test.inp))
		}

		// Consume all the keys
		out := []string{}
		for {
			key, _, ok := iter.Next()
			if !ok {
				break
			}
			out = append(out, string(key))
		}
		if !reflect.DeepEqual(out, test.out) {
			t.Fatalf("mis-match: %d %v %v", idx, out, test.out)
		}
	}
}

func TestMergeChildNilEdges(t *testing.T) {
	r := New()
	r, _, _ = r.Insert([]byte("foobar"), 42)
	r, _, _ = r.Insert([]byte("foozip"), 43)
	r, _, _ = r.Delete([]byte("foobar"))

	root := r.Root()
	out := []string{}
	fn := func(k []byte, v interface{}) bool {
		out = append(out, string(k))
		return false
	}
	root.Walk(fn)

	expect := []string{"foozip"}
	sort.Strings(out)
	sort.Strings(expect)
	if !reflect.DeepEqual(out, expect) {
		t.Fatalf("mis-match: %v %v", out, expect)
	}
}

func TestMergeChildVisibility(t *testing.T) {
	r := New()
	r, _, _ = r.Insert([]byte("foobar"), 42)
	r, _, _ = r.Insert([]byte("foobaz"), 43)
	r, _, _ = r.Insert([]byte("foozip"), 10)

	txn1 := r.Txn()
	txn2 := r.Txn()

	// Ensure we get the expected value foobar and foobaz
	if val, ok := txn1.Get([]byte("foobar")); !ok || val != 42 {
		t.Fatalf("bad: %v", val)
	}
	if val, ok := txn1.Get([]byte("foobaz")); !ok || val != 43 {
		t.Fatalf("bad: %v", val)
	}
	if val, ok := txn2.Get([]byte("foobar")); !ok || val != 42 {
		t.Fatalf("bad: %v", val)
	}
	if val, ok := txn2.Get([]byte("foobaz")); !ok || val != 43 {
		t.Fatalf("bad: %v", val)
	}

	// Delete of foozip will cause a merge child between the
	// "foo" and "ba" nodes.
	if val, ok := txn2.Delete([]byte("foozip")); !ok || val != 10 {
		t.Fatalf("bad: %v", val)
	}

	// Insert of "foobaz" will update the slice of the "fooba" node
	// in-place to point to the new "foobaz" node. This in-place update
	// will cause the visibility of the update to leak into txn1 (prior
	// to the fix).
	if val, ok := txn2.Insert([]byte("foobaz"), 44); !ok || val != 43 {
		t.Fatalf("bad: %v", val)
	}

	// Ensure we get the expected value foobar and foobaz
	if val, ok := txn1.Get([]byte("foobar")); !ok || val != 42 {
		t.Fatalf("bad: %v", val)
	}
	if val, ok := txn1.Get([]byte("foobaz")); !ok || val != 43 {
		t.Fatalf("bad: %v", val)
	}
	if val, ok := txn2.Get([]byte("foobar")); !ok || val != 42 {
		t.Fatalf("bad: %v", val)
	}
	if val, ok := txn2.Get([]byte("foobaz")); !ok || val != 44 {
		t.Fatalf("bad: %v", val)
	}

	// Commit txn2
	r = txn2.Commit()

	// Ensure we get the expected value foobar and foobaz
	if val, ok := txn1.Get([]byte("foobar")); !ok || val != 42 {
		t.Fatalf("bad: %v", val)
	}
	if val, ok := txn1.Get([]byte("foobaz")); !ok || val != 43 {
		t.Fatalf("bad: %v", val)
	}
	if val, ok := r.Get([]byte("foobar")); !ok || val != 42 {
		t.Fatalf("bad: %v", val)
	}
	if val, ok := r.Get([]byte("foobaz")); !ok || val != 44 {
		t.Fatalf("bad: %v", val)
	}
}
