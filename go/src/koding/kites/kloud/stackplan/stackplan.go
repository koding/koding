package stackplan

import (
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/utils"

	multierror "github.com/hashicorp/go-multierror"
	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite/protocol"
	"golang.org/x/net/context"
)

// credPermissions defines the permission grid for the given method
var (
	credPermissions = map[string][]string{
		"bootstrap":    []string{"owner"},
		"plan":         []string{"user", "owner"},
		"apply":        []string{"user", "owner"},
		"authenticate": []string{"user", "owner"},
	}
)

// Machine represents a jComputeStack.machine value.
type Machine struct {
	Provider        string            `json:"provider"`
	Label           string            `json:"label"`
	Region          string            `json:"region"`
	QueryString     string            `json:"queryString,omitempty"`
	HostQueryString string            `json:"hostQueryString,omitempty"`
	Attributes      map[string]string `json:"attributes"`
}

// KiteMap maps resource names to kite IDs they own.
type KiteMap map[string]string

// Stack is struct that contains all necessary information Apply needs to
// perform successfully.
type Stack struct {
	// Machines is a list of jMachine identifiers.
	Machines []string

	// Credentials maps jCredential provider to identifiers.
	Credentials map[string][]string

	// Template is a raw Terraform template.
	Template string
}

// Machines is a list of machines.
type Machines struct {
	Machines []Machine `json:"machines"`
}

// Credential represents jCredential{Datas} value. Meta is of a provider-specific
// type, defined by a ctor func in MetaFuncs map.
type Credential struct {
	Provider   string
	Identifier string
	Meta       interface{}
}

// String implememts the fmt.Stringer interface.
func (m *Machines) String() string {
	var txt string
	for i, machine := range m.Machines {
		txt += fmt.Sprintf("[%d] %+v\n", i, machine)
	}
	return txt
}

func (m *Machines) AppendRegion(region string) {
	for i, machine := range m.Machines {
		machine.Region = region
		m.Machines[i] = machine
	}
}

func (m *Machines) AppendQueryString(queryStrings map[string]string) {
	for i, machine := range m.Machines {
		queryString := queryStrings[machine.Label]
		machine.QueryString = protocol.Kite{ID: queryString}.String()
		m.Machines[i] = machine
	}
}

func (m *Machines) AppendHostQueryString(s string) {
	for i, machine := range m.Machines {
		machine.HostQueryString = utils.QueryString(s)
		m.Machines[i] = machine
	}
}

// WithLabel returns the machine with the associated label
func (m *Machines) WithLabel(label string) (Machine, error) {
	for _, machine := range m.Machines {
		if machine.Label == label {
			return machine, nil
		}
	}

	return Machine{}, fmt.Errorf("couldn't find machine with label '%s", label)
}

// DefaultKlientTimeout specifies the maximum time we're going to try to
// connect to klient before timing out.
var DefaultKlientTimeout = 5 * time.Minute

// Planner is used to build kloud machines from Terraform resources,
// like plan result or state file.
//
// It is also used for checking connectivity with klient running
// on those machines.
type Planner struct {
	Provider     string // Terraform provider name
	ResourceType string // Terraform resource type

	KlientTimeout time.Duration // when zero-value, DefaultKlientTimeout is used

	// SessionFunc is used to build a session value from the context.
	//
	// When nil, session.FromContext is used by default.
	SessionFunc func(context.Context) (*session.Session, error)
}

// MachinesFromState builds a list of machines from Terraform state value.
//
// It ignores any other resources than those specified by p.ResourceType
// and p.Provider.
func (p *Planner) MachinesFromState(state *terraform.State) (*Machines, error) {
	if len(state.Modules) == 0 {
		return nil, errors.New("state modules is empty")
	}

	var out Machines

	for _, m := range state.Modules {
		for resource, r := range m.Resources {
			if r.Primary == nil {
				continue
			}

			provider, resourceType, label, err := parseResource(resource)
			if err != nil {
				return nil, err
			}

			if resourceType != p.ResourceType || provider != p.Provider {
				continue
			}

			attrs := make(map[string]string, len(r.Primary.Attributes))
			for key, val := range r.Primary.Attributes {
				attrs[key] = val
			}

			out.Machines = append(out.Machines, Machine{
				Provider:   provider,
				Label:      label,
				Attributes: attrs,
			})
		}
	}

	return &out, nil
}

// MachinesFromPlan builds a list of machines from Terraform plan result.
//
// It ignores any other resources than those specified by p.ResourceType
// and p.Provider.
func (p *Planner) MachinesFromPlan(plan *terraform.Plan) (*Machines, error) {
	if plan.Diff == nil {
		return nil, errors.New("plan diff is empty")
	}

	if len(plan.Diff.Modules) == 0 {
		return nil, errors.New("plan diff module is empty")
	}

	var out Machines

	for _, d := range plan.Diff.Modules {
		if d.Resources == nil {
			continue
		}

		for providerResource, r := range d.Resources {
			if len(r.Attributes) == 0 {
				continue
			}

			provider, resourceType, label, err := parseResource(providerResource)
			if err != nil {
				return nil, err
			}

			if resourceType != p.ResourceType || provider != p.Provider {
				continue
			}

			attrs := make(map[string]string, len(r.Attributes))
			for name, a := range r.Attributes {
				attrs[name] = a.New
			}

			out.Machines = append(out.Machines, Machine{
				Provider:   provider,
				Label:      label,
				Attributes: attrs,
			})
		}
	}

	return &out, nil
}

// CheckKlients checks connectivity to all klient kites given by the kiteIDs
// parameter.
func (p *Planner) CheckKlients(ctx context.Context, kiteIDs KiteMap) error {
	sess, err := p.session(ctx)
	if err != nil {
		return err
	}

	var wg sync.WaitGroup
	var mu sync.Mutex // protects multierror and outputs
	var multiErrors error

	check := func(label, kiteId string) error {
		queryString := protocol.Kite{ID: kiteId}.String()

		sess.Log.Debug("[%s] Checking connectivity to %q", label, kiteId)

		klientRef, err := klient.NewWithTimeout(sess.Kite, queryString, p.klientTimeout())
		if err != nil {
			return err
		}
		defer klientRef.Close()

		return klientRef.Ping()
	}

	for l, k := range kiteIDs {
		wg.Add(1)
		go func(label, kiteId string) {
			if err := check(label, kiteId); err != nil {
				mu.Lock()
				multiErrors = multierror.Append(multiErrors,
					fmt.Errorf("Couldn't check '%s:%s'", label, kiteId))
				mu.Unlock()
			}
			wg.Done()
		}(l, k)
	}

	wg.Wait()

	return multiErrors
}

func (p *Planner) klientTimeout() time.Duration {
	if p.KlientTimeout != 0 {
		return p.KlientTimeout
	}
	return DefaultKlientTimeout
}

func (p *Planner) session(ctx context.Context) (*session.Session, error) {
	if p.SessionFunc != nil {
		return p.SessionFunc(ctx)
	}

	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	return sess, nil
}

func parseResource(resource string) (string, string, string, error) {
	// resource is in the form of "aws_instance.foo.bar"
	splitted := strings.SplitN(resource, "_", 2)
	if len(splitted) < 2 {
		return "", "", "", fmt.Errorf("provider resource is unknown: %v", splitted)
	}

	resourceSplitted := strings.SplitN(splitted[1], ".", 2)

	provider := splitted[0]             // aws
	resourceType := resourceSplitted[0] // instance
	label := resourceSplitted[1]        // foo.bar

	return provider, resourceType, label, nil
}

// isVariable checkes whether the given string is a template variable, such as:
// "${var.region}"
func IsVariable(v string) bool {
	return len(v) != 0 && v[0] == '$'
}

// ParseAccountID parses an AWS arn string to get the Account ID
//
// The function assumes arn string comes from an IAM resource, as
// it treats region empty.
//
// For details see:
//
//   http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns
//
func ParseAccountID(arn string) (string, error) {
	// example arn string: "arn:aws:iam::213456789:user/username"
	// returns: 213456789.
	splitted := strings.Split(strings.TrimPrefix(arn, "arn:aws:iam::"), ":")
	if len(splitted) != 2 {
		return "", fmt.Errorf("Couldn't parse arn string: %s", arn)
	}

	return splitted[0], nil
}

// FlattenValues converts the values of a map[string][]string to a []string slice.
func FlattenValues(kv map[string][]string) []string {
	values := []string{}

	for _, val := range kv {
		values = append(values, val...)
	}

	return values
}
