package terraform

import (
	"fmt"
	"strings"

	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/terraform/config"
	"github.com/hashicorp/terraform/dag"
	"github.com/hashicorp/terraform/dot"
)

// GraphNodeProvider is an interface that nodes that can be a provider
// must implement. The ProviderName returned is the name of the provider
// they satisfy.
type GraphNodeProvider interface {
	ProviderName() string
	ProviderConfig() *config.RawConfig
}

// GraphNodeCloseProvider is an interface that nodes that can be a close
// provider must implement. The CloseProviderName returned is the name of
// the provider they satisfy.
type GraphNodeCloseProvider interface {
	CloseProviderName() string
}

// GraphNodeProviderConsumer is an interface that nodes that require
// a provider must implement. ProvidedBy must return the name of the provider
// to use.
type GraphNodeProviderConsumer interface {
	ProvidedBy() []string
}

// DisableProviderTransformer "disables" any providers that are only
// depended on by modules.
type DisableProviderTransformer struct{}

func (t *DisableProviderTransformer) Transform(g *Graph) error {
	for _, v := range g.Vertices() {
		// We only care about providers
		pn, ok := v.(GraphNodeProvider)
		if !ok || pn.ProviderName() == "" {
			continue
		}

		// Go through all the up-edges (things that depend on this
		// provider) and if any is not a module, then ignore this node.
		nonModule := false
		for _, sourceRaw := range g.UpEdges(v).List() {
			source := sourceRaw.(dag.Vertex)
			cn, ok := source.(graphNodeConfig)
			if !ok {
				nonModule = true
				break
			}

			if cn.ConfigType() != GraphNodeConfigTypeModule {
				nonModule = true
				break
			}
		}
		if nonModule {
			// We found something that depends on this provider that
			// isn't a module, so skip it.
			continue
		}

		// Disable the provider by replacing it with a "disabled" provider
		disabled := &graphNodeDisabledProvider{GraphNodeProvider: pn}
		if !g.Replace(v, disabled) {
			panic(fmt.Sprintf(
				"vertex disappeared from under us: %s",
				dag.VertexName(v)))
		}
	}

	return nil
}

// ProviderTransformer is a GraphTransformer that maps resources to
// providers within the graph. This will error if there are any resources
// that don't map to proper resources.
type ProviderTransformer struct{}

func (t *ProviderTransformer) Transform(g *Graph) error {
	// Go through the other nodes and match them to providers they need
	var err error
	m := providerVertexMap(g)
	for _, v := range g.Vertices() {
		if pv, ok := v.(GraphNodeProviderConsumer); ok {
			for _, p := range pv.ProvidedBy() {
				target := m[p]
				if target == nil {
					err = multierror.Append(err, fmt.Errorf(
						"%s: provider %s couldn't be found",
						dag.VertexName(v), p))
					continue
				}

				g.Connect(dag.BasicEdge(v, target))
			}
		}
	}

	return err
}

// CloseProviderTransformer is a GraphTransformer that adds nodes to the
// graph that will close open provider connections that aren't needed anymore.
// A provider connection is not needed anymore once all depended resources
// in the graph are evaluated.
type CloseProviderTransformer struct{}

func (t *CloseProviderTransformer) Transform(g *Graph) error {
	pm := providerVertexMap(g)
	cpm := closeProviderVertexMap(g)
	var err error
	for _, v := range g.Vertices() {
		if pv, ok := v.(GraphNodeProviderConsumer); ok {
			for _, p := range pv.ProvidedBy() {
				source := cpm[p]

				if source == nil {
					// Create a new graphNodeCloseProvider and add it to the graph
					source = &graphNodeCloseProvider{ProviderNameValue: p}
					g.Add(source)

					// Close node needs to depend on provider
					provider, ok := pm[p]
					if !ok {
						err = multierror.Append(err, fmt.Errorf(
							"%s: provider %s couldn't be found for closing",
							dag.VertexName(v), p))
						continue
					}
					g.Connect(dag.BasicEdge(source, provider))

					// Make sure we also add the new graphNodeCloseProvider to the map
					// so we don't create and add any duplicate graphNodeCloseProviders.
					cpm[p] = source
				}

				// Close node depends on all nodes provided by the provider
				g.Connect(dag.BasicEdge(source, v))
			}
		}
	}

	return err
}

// MissingProviderTransformer is a GraphTransformer that adds nodes
// for missing providers into the graph. Specifically, it creates provider
// configuration nodes for all the providers that we support. These are
// pruned later during an optimization pass.
type MissingProviderTransformer struct {
	// Providers is the list of providers we support.
	Providers []string
}

func (t *MissingProviderTransformer) Transform(g *Graph) error {
	// Create a set of our supported providers
	supported := make(map[string]struct{}, len(t.Providers))
	for _, v := range t.Providers {
		supported[v] = struct{}{}
	}

	// Get the map of providers we already have in our graph
	m := providerVertexMap(g)

	// Go through all the provider consumers and make sure we add
	// that provider if it is missing.
	for _, v := range g.Vertices() {
		pv, ok := v.(GraphNodeProviderConsumer)
		if !ok {
			continue
		}

		for _, p := range pv.ProvidedBy() {
			if _, ok := m[p]; ok {
				// This provider already exists as a configure node
				continue
			}

			// If the provider has an alias in it, we just want the type
			ptype := p
			if idx := strings.IndexRune(p, '.'); idx != -1 {
				ptype = p[:idx]
			}

			if _, ok := supported[ptype]; !ok {
				// If we don't support the provider type, skip it.
				// Validation later will catch this as an error.
				continue
			}

			// Add our own missing provider node to the graph
			m[p] = g.Add(&graphNodeMissingProvider{ProviderNameValue: p})
		}
	}

	return nil
}

// PruneProviderTransformer is a GraphTransformer that prunes all the
// providers that aren't needed from the graph. A provider is unneeded if
// no resource or module is using that provider.
type PruneProviderTransformer struct{}

func (t *PruneProviderTransformer) Transform(g *Graph) error {
	for _, v := range g.Vertices() {
		// We only care about the providers
		if pn, ok := v.(GraphNodeProvider); !ok || pn.ProviderName() == "" {
			continue
		}

		// Does anything depend on this? If not, then prune it.
		if s := g.UpEdges(v); s.Len() == 0 {
			g.Remove(v)
		}
	}

	return nil
}

func providerVertexMap(g *Graph) map[string]dag.Vertex {
	m := make(map[string]dag.Vertex)
	for _, v := range g.Vertices() {
		if pv, ok := v.(GraphNodeProvider); ok {
			m[pv.ProviderName()] = v
		}
	}

	return m
}

func closeProviderVertexMap(g *Graph) map[string]dag.Vertex {
	m := make(map[string]dag.Vertex)
	for _, v := range g.Vertices() {
		if pv, ok := v.(GraphNodeCloseProvider); ok {
			m[pv.CloseProviderName()] = v
		}
	}

	return m
}

type graphNodeDisabledProvider struct {
	GraphNodeProvider
}

// GraphNodeEvalable impl.
func (n *graphNodeDisabledProvider) EvalTree() EvalNode {
	var resourceConfig *ResourceConfig

	return &EvalOpFilter{
		Ops: []walkOperation{walkInput, walkValidate, walkRefresh, walkPlan, walkApply, walkDestroy},
		Node: &EvalSequence{
			Nodes: []EvalNode{
				&EvalInterpolate{
					Config: n.ProviderConfig(),
					Output: &resourceConfig,
				},
				&EvalBuildProviderConfig{
					Provider: n.ProviderName(),
					Config:   &resourceConfig,
					Output:   &resourceConfig,
				},
				&EvalSetProviderConfig{
					Provider: n.ProviderName(),
					Config:   &resourceConfig,
				},
			},
		},
	}
}

// GraphNodeFlattenable impl.
func (n *graphNodeDisabledProvider) Flatten(p []string) (dag.Vertex, error) {
	return &graphNodeDisabledProviderFlat{
		graphNodeDisabledProvider: n,
		PathValue:                 p,
	}, nil
}

func (n *graphNodeDisabledProvider) Name() string {
	return fmt.Sprintf("%s (disabled)", dag.VertexName(n.GraphNodeProvider))
}

// GraphNodeDotter impl.
func (n *graphNodeDisabledProvider) DotNode(name string, opts *GraphDotOpts) *dot.Node {
	return dot.NewNode(name, map[string]string{
		"label": n.Name(),
		"shape": "diamond",
	})
}

// GraphNodeDotterOrigin impl.
func (n *graphNodeDisabledProvider) DotOrigin() bool {
	return true
}

// GraphNodeDependable impl.
func (n *graphNodeDisabledProvider) DependableName() []string {
	return []string{"provider." + n.ProviderName()}
}

// GraphNodeProvider impl.
func (n *graphNodeDisabledProvider) ProviderName() string {
	return n.GraphNodeProvider.ProviderName()
}

// GraphNodeProvider impl.
func (n *graphNodeDisabledProvider) ProviderConfig() *config.RawConfig {
	return n.GraphNodeProvider.ProviderConfig()
}

// Same as graphNodeDisabledProvider, but for flattening
type graphNodeDisabledProviderFlat struct {
	*graphNodeDisabledProvider

	PathValue []string
}

func (n *graphNodeDisabledProviderFlat) Name() string {
	return fmt.Sprintf(
		"%s.%s", modulePrefixStr(n.PathValue), n.graphNodeDisabledProvider.Name())
}

func (n *graphNodeDisabledProviderFlat) Path() []string {
	return n.PathValue
}

func (n *graphNodeDisabledProviderFlat) ProviderName() string {
	return fmt.Sprintf(
		"%s.%s", modulePrefixStr(n.PathValue),
		n.graphNodeDisabledProvider.ProviderName())
}

// GraphNodeDependable impl.
func (n *graphNodeDisabledProviderFlat) DependableName() []string {
	return []string{n.Name()}
}

func (n *graphNodeDisabledProviderFlat) DependentOn() []string {
	var result []string

	// If we're in a module, then depend on our parent's provider
	if len(n.PathValue) > 1 {
		prefix := modulePrefixStr(n.PathValue[:len(n.PathValue)-1])
		if prefix != "" {
			prefix += "."
		}

		result = append(result, fmt.Sprintf(
			"%s%s",
			prefix, n.graphNodeDisabledProvider.Name()))
	}

	return result
}

type graphNodeCloseProvider struct {
	ProviderNameValue string
}

func (n *graphNodeCloseProvider) Name() string {
	return fmt.Sprintf("provider.%s (close)", n.ProviderNameValue)
}

// GraphNodeEvalable impl.
func (n *graphNodeCloseProvider) EvalTree() EvalNode {
	return CloseProviderEvalTree(n.ProviderNameValue)
}

// GraphNodeDependable impl.
func (n *graphNodeCloseProvider) DependableName() []string {
	return []string{n.Name()}
}

func (n *graphNodeCloseProvider) CloseProviderName() string {
	return n.ProviderNameValue
}

// GraphNodeDotter impl.
func (n *graphNodeCloseProvider) DotNode(name string, opts *GraphDotOpts) *dot.Node {
	if !opts.Verbose {
		return nil
	}
	return dot.NewNode(name, map[string]string{
		"label": n.Name(),
		"shape": "diamond",
	})
}

type graphNodeMissingProvider struct {
	ProviderNameValue string
}

func (n *graphNodeMissingProvider) Name() string {
	return fmt.Sprintf("provider.%s", n.ProviderNameValue)
}

// GraphNodeEvalable impl.
func (n *graphNodeMissingProvider) EvalTree() EvalNode {
	return ProviderEvalTree(n.ProviderNameValue, nil)
}

// GraphNodeDependable impl.
func (n *graphNodeMissingProvider) DependableName() []string {
	return []string{n.Name()}
}

func (n *graphNodeMissingProvider) ProviderName() string {
	return n.ProviderNameValue
}

func (n *graphNodeMissingProvider) ProviderConfig() *config.RawConfig {
	return nil
}

// GraphNodeDotter impl.
func (n *graphNodeMissingProvider) DotNode(name string, opts *GraphDotOpts) *dot.Node {
	return dot.NewNode(name, map[string]string{
		"label": n.Name(),
		"shape": "diamond",
	})
}

// GraphNodeDotterOrigin impl.
func (n *graphNodeMissingProvider) DotOrigin() bool {
	return true
}

// GraphNodeFlattenable impl.
func (n *graphNodeMissingProvider) Flatten(p []string) (dag.Vertex, error) {
	return &graphNodeMissingProviderFlat{
		graphNodeMissingProvider: n,
		PathValue:                p,
	}, nil
}

// Same as graphNodeMissingProvider, but for flattening
type graphNodeMissingProviderFlat struct {
	*graphNodeMissingProvider

	PathValue []string
}

func (n *graphNodeMissingProviderFlat) Name() string {
	return fmt.Sprintf(
		"%s.%s", modulePrefixStr(n.PathValue), n.graphNodeMissingProvider.Name())
}

func (n *graphNodeMissingProviderFlat) Path() []string {
	return n.PathValue
}

func (n *graphNodeMissingProviderFlat) ProviderName() string {
	return fmt.Sprintf(
		"%s.%s", modulePrefixStr(n.PathValue),
		n.graphNodeMissingProvider.ProviderName())
}

// GraphNodeDependable impl.
func (n *graphNodeMissingProviderFlat) DependableName() []string {
	return []string{n.Name()}
}

func (n *graphNodeMissingProviderFlat) DependentOn() []string {
	var result []string

	// If we're in a module, then depend on our parent's provider
	if len(n.PathValue) > 1 {
		prefix := modulePrefixStr(n.PathValue[:len(n.PathValue)-1])
		if prefix != "" {
			prefix += "."
		}

		result = append(result, fmt.Sprintf(
			"%s%s",
			prefix, n.graphNodeMissingProvider.Name()))
	}

	return result
}
