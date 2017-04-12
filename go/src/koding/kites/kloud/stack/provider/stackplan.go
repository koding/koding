package provider

import (
	"bytes"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/utils"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
)

var defaultLog = logging.NewCustom("stackplan", false)

// credPermissions defines the permission grid for the given method
var credPermissions = map[string][]string{
	"bootstrap":    {"owner"},
	"plan":         {"user", "owner"},
	"apply":        {"user", "owner"},
	"authenticate": {"user", "owner"},
}

// DialState describes state of a single dial.
type DialState struct {
	Label   string // the vm label
	KiteID  string // the kite ID being checked
	KiteURL string // last resolved URL or empty
	State   string // either "kontrol", "dial", "ping" or "provider"
	Err     error  // underlying error
}

// DialError describes an error of DialKlients.
type DialError struct {
	States []*DialState
}

// Error implements the built-in error interface.
func (de *DialError) Error() string {
	var buf bytes.Buffer

	fmt.Fprintf(&buf, "Failed to dial the following kites:\n\n")

	for _, s := range de.States {
		fmt.Fprintf(&buf, "  * %s: %s (id=%q, url=%q, state=%q)\n", s.Label, s.Err, s.KiteID, s.KiteURL, s.State)
	}

	return buf.String()
}

// Err returns de if it contains at least 1 failed state.
func (de *DialError) Err() error {
	for _, s := range de.States {
		if s.Err != nil {
			return de
		}
	}

	return nil
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

	Log logging.Logger // used for logging

	KlientTimeout time.Duration // when zero-value, DefaultKlientTimeout is used

	// OnDial, when non-nil, is called to perform additional check
	// for DialKlients method.
	OnDial func(*kite.Client) error

	// SessionFunc is used to build a session value from the context.
	//
	// When nil, session.FromContext is used by default.
	SessionFunc func(context.Context) (*session.Session, error)
}

// MachinesFromState builds a list of machines from Terraform state value.
//
// It ignores any other resources than those specified by p.ResourceType
// and p.Provider.
func (p *Planner) MachinesFromState(state *terraform.State, klients map[string]*DialState,
	metas map[string]map[string]interface{}) (map[string]*stack.Machine, error) {
	if len(state.Modules) == 0 {
		return nil, errors.New("state modules is empty")
	}

	p.Log.Debug("MachinesFromState: state=%#v, klients=%#v", state, klients)

	machines := make(map[string]*stack.Machine)

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
				if !strings.ContainsAny(key, "#.") && val != "" {
					attrs[key] = val
				}
			}

			state, ok := klients[label]
			if !ok {
				return nil, fmt.Errorf("no klient state found for %q %s", label, p.ResourceType)
			}

			machine := &stack.Machine{
				Provider:    p.Provider,
				Label:       label,
				Attributes:  attrs,
				QueryString: state.KiteID,
				RegisterURL: state.KiteURL,
				State:       machinestate.Running,
				StateReason: "Created with kloud.apply",
			}

			if meta, ok := metas[label]; ok && len(meta) != 0 {
				machine.Meta = meta
			}

			if state.Err != nil {
				machine.State = machinestate.Stopped
				machine.StateReason = fmt.Sprintf("Stopped due to dial failure: %s", state.Err)
			}

			machines[machine.Label] = machine
		}
	}

	return machines, nil
}

// MachinesFromPlan builds a list of machines from Terraform plan result.
//
// It ignores any other resources than those specified by p.ResourceType
// and p.Provider.
func (p *Planner) MachinesFromPlan(plan *terraform.Plan) (stack.Machines, error) {
	if plan.Diff == nil {
		return nil, errors.New("plan diff is empty")
	}

	if len(plan.Diff.Modules) == 0 {
		return nil, errors.New("plan diff module is empty")
	}

	machines := make(stack.Machines)

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
			for key, val := range r.Attributes {
				if !strings.ContainsAny(key, "#.") && val.New != "" {
					attrs[key] = val.New
				}
			}

			machines[label] = &stack.Machine{
				Provider:   provider,
				Label:      label,
				Attributes: attrs,
			}
		}
	}

	return machines, nil
}

func (p *Planner) checkSingleKlient(k *kite.Kite, label, kiteID string) *DialState {
	kiteID, err := utils.QueryString(kiteID)
	if err != nil {
		return &DialState{
			Label:  label,
			KiteID: kiteID,
			State:  "dial",
			Err:    err,
		}
	}

	start := time.Now()

	c, err := klient.NewWithTimeout(k, kiteID, p.klientTimeout())
	if err == klient.ErrDialingFailed {
		return &DialState{
			Label:   label,
			KiteID:  kiteID,
			KiteURL: c.Client.URL,
			State:   "dial",
			Err:     err,
		}
	}

	if err != nil {
		return &DialState{
			Label:  label,
			KiteID: kiteID,
			State:  "kontrol",
			Err:    err,
		}
	}

	defer c.Close()

	left := p.klientTimeout() - time.Now().Sub(start)

	err = c.PingTimeout(max(left, klient.DefaultTimeout))
	if err != nil {
		return &DialState{
			Label:  label,
			KiteID: kiteID,
			State:  "ping",
			Err:    err,
		}
	}

	if p.OnDial != nil {
		err = p.OnDial(c.Client)
	}

	return &DialState{
		Label:   label,
		KiteID:  kiteID,
		KiteURL: c.Client.URL,
		State:   "provider",
		Err:     err,
	}
}

// DialKlients checks connectivity to all klient kites given by the kiteIDs
// parameter.
//
// It returns RegisterURLs mapped to each kite's query string.
func (p *Planner) DialKlients(ctx context.Context, kiteIDs stack.KiteMap) (map[string]*DialState, error) {
	sess, err := p.session(ctx)
	if err != nil {
		return nil, err
	}

	var (
		wg   sync.WaitGroup
		mu   sync.Mutex // protects multierror and outputs
		urls = make(map[string]*DialState, len(kiteIDs))
		de   = &DialError{}
	)

	for l, k := range kiteIDs {
		wg.Add(1)

		go func(label, kiteID string) {
			defer wg.Done()
			state := p.checkSingleKlient(sess.Kite, label, kiteID)

			mu.Lock()
			if state.Err != nil {
				de.States = append(de.States, state)
			}
			urls[label] = state
			mu.Unlock()
		}(l, k)
	}

	wg.Wait()

	return urls, de.Err()
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

// FlattenValues converts the values of a map[string][]string to a []string slice.
func FlattenValues(kv map[string][]string) []string {
	values := []string{}

	for _, val := range kv {
		values = append(values, val...)
	}

	return values
}

func max(d, t time.Duration) time.Duration {
	if d > t {
		return d
	}
	return t
}
