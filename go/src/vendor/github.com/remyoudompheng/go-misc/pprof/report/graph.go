package report

import (
	"fmt"
	"io"
	"math"
	"text/template"
)

const (
	NODE_FRACTION = .005
	EDGE_FRACTION = .001
)

type GraphDrawer struct {
	NodeFraction float64
	EdgeFraction float64
}

type Node struct {
	Id      int
	Sym     string
	Self    int64
	Cumul   int64
	Callees map[string]int64
}

func (n *Node) Leaf() bool { return len(n.Callees) == 0 }

type Graph map[string]Node

func (g Graph) Nodes() (ns []Node) {
	for _, n := range g {
		ns = append(ns, n)
	}
	return
}

type Edge struct {
	Node1, Node2 int
	Count        int64
}

func (g Graph) Edges() (e []Edge) {
	for _, n := range g {
		for n2, c := range n.Callees {
			e = append(e, Edge{Node1: n.Id, Node2: g[n2].Id, Count: c})
		}
	}
	return
}

func (r *Reporter) GraphByFunc(col int) Graph {
	g := make(Graph)
	count := 1
	for a, v := range r.stats {
		name := r.Resolver.Resolve(a)
		n, ok := g[name]
		if !ok {
			count++
			n.Id = count
			n.Sym = name
		}
		n.Self += v.Self[col]
		n.Cumul += v.Cumul[col]
		if len(v.Callees) > 0 && n.Callees == nil {
			n.Callees = make(map[string]int64, len(v.Callees))
		}
		for b, w := range v.Callees {
			bname := r.Resolver.Resolve(b)
			n.Callees[bname] += w[col]
		}
		g[name] = n
	}
	return g
}

type GraphReport struct {
	Prog  string
	Total int64
	Unit  string
	Graph Graph

	NodeFrac float64
	EdgeFrac float64
}

func (g *GraphReport) WriteTo(w io.Writer) error {
	err := graphvizTpl.Execute(w, g)
	return err
}

func (g *GraphReport) Nodes() (ns []Node) {
	min := int64(float64(g.Total) * g.NodeFrac)
	println("min =", min)
	for _, n := range g.Graph.Nodes() {
		if n.Cumul >= min {
			ns = append(ns, n)
		}
	}
	return
}

func (g *GraphReport) Edges() (e []Edge) {
	minN := int64(float64(g.Total) * g.NodeFrac)
	minE := int64(float64(g.Total) * g.EdgeFrac)
	for _, n := range g.Graph {
		if n.Cumul < minN {
			continue
		}
		for n2, c := range n.Callees {
			if g.Graph[n2].Cumul >= minN && c >= minE {
				e = append(e, Edge{Node1: n.Id, Node2: g.Graph[n2].Id, Count: c})
			}
		}
	}
	return
}

const graphvizTplText = `
digraph "{{.Prog}}; {{.Total}} {{.Unit}}" {
    node [width=0.375,height=0.25];
    Legend [shape=box,fontsize=24,shape=plaintext,
            label="Total {{.Unit}}: {{.Total}}\l"];
    {{ range $node := $.Nodes }}
    N{{$node.Id}} [shape=box,
        fontsize={{fontsize $node.Self $.Total}},
        label="{{$node.Sym}}\n"+
              "{{$node.Self}} ({{percent $node.Self $.Total}})\r"+
              {{if not $node.Leaf}}
              "of {{$node.Cumul}} ({{percent $node.Cumul $.Total}})\r"];
              {{else}}""];{{end}}
    {{end}}
    {{ range $edge := $.Edges }}
    N{{$edge.Node1}} -> N{{$edge.Node2}} [label={{$edge.Count}}];{{ end }}
}
`

var graphvizTpl = template.Must(template.New("dot").
	Funcs(template.FuncMap{
	"percent":  percent,
	"fontsize": fontsize,
	"edgesize": edgesize}).
	Parse(graphvizTplText))

func percent(self, total int64) string {
	p := 100 * float64(self) / float64(total)
	return fmt.Sprintf("%.1f %%", p)
}

func fontsize(self, total int64) float64 {
	return 8 + 50*math.Sqrt(float64(self)/float64(total))
}

func edgesize(self, total int64) float64 {
	return 0
}
