package stackplan

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/klient"
	pUser "koding/kites/kloud/scripts/provisionklient/userdata"

	multierror "github.com/hashicorp/go-multierror"
	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite/protocol"
	uuid "github.com/satori/go.uuid"
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

// Machine
type Machine struct {
	Provider    string            `json:"provider"`
	Label       string            `json:"label"`
	Region      string            `json:"region"`
	QueryString string            `json:"queryString,omitempty"`
	Attributes  map[string]string `json:"attributes"`
}

// KiteMap
type KiteMap map[string]string

// Stack is struct that contains all necessary information Apply needs to
// perform successfully.
type Stack struct {
	// jMachine ids
	Machines []string

	// jCredential provider to identifiers
	Credentials map[string][]string

	// Terraform template
	Template string
}

// Machines
type Machines struct {
	Machines []Machine `json:"machines"`
}

// Credential
type Credential struct {
	Provider   string
	Identifier string
	Meta       interface{}
}

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

// WithLabel returns the machine with the associated label
func (m *Machines) WithLabel(label string) (Machine, error) {
	for _, machine := range m.Machines {
		if machine.Label == label {
			return machine, nil
		}
	}

	return Machine{}, fmt.Errorf("couldn't find machine with label '%s", label)
}

func MachinesFromState(state *terraform.State) (*Machines, error) {
	if state.Modules == nil {
		return nil, errors.New("state modules is empty")
	}

	out := &Machines{
		Machines: make([]Machine, 0),
	}

	for _, m := range state.Modules {
		for resource, r := range m.Resources {
			if r.Primary == nil {
				continue
			}

			provider, resourceType, label, err := parseResource(resource)
			if err != nil {
				return nil, err
			}

			if resourceType == "instance" && provider != "aws" {
				continue
			}

			if resourceType == "build" && provider != "vagrantkite" {
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

	return out, nil
}

func MachinesFromPlan(plan *terraform.Plan) (*Machines, error) {
	if plan.Diff == nil {
		return nil, errors.New("plan diff is empty")
	}

	if plan.Diff.Modules == nil {
		return nil, errors.New("plan diff module is empty")
	}

	out := &Machines{
		Machines: make([]Machine, 0),
	}

	for _, d := range plan.Diff.Modules {
		if d.Resources == nil {
			continue
		}

		for providerResource, r := range d.Resources {
			if r.Attributes == nil {
				continue
			}

			attrs := make(map[string]string, len(r.Attributes))
			for name, a := range r.Attributes {
				attrs[name] = a.New
			}

			provider, resourceType, label, err := parseResource(providerResource)
			if err != nil {
				return nil, err
			}

			if resourceType != "instance" {
				continue
			}

			out.Machines = append(out.Machines, Machine{
				Provider:   provider,
				Label:      label,
				Attributes: attrs,
			})
		}
	}

	return out, nil
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

// TODO(rjeczalik): move to provider/vagrant package
func InjectVagrantData(ctx context.Context, template *Template, username string) (KiteMap, error) {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	var resource struct {
		VagrantBuild map[string]map[string]interface{} `hcl:"vagrantkite_build"`
	}

	if err := template.DecodeResource(&resource); err != nil {
		return nil, err
	}

	if len(resource.VagrantBuild) == 0 {
		sess.Log.Debug("No Vagrant build available")
		return nil, nil
	}

	kiteIDs := make(KiteMap)

	for resourceName, box := range resource.VagrantBuild {
		kiteID := uuid.NewV4().String()

		kiteKey, err := sess.Userdata.Keycreator.Create(username, kiteID)
		if err != nil {
			return nil, err
		}

		klientURL, err := sess.Userdata.Bucket.LatestDeb()
		if err != nil {
			return nil, err
		}
		klientURL = sess.Userdata.Bucket.URL(klientURL)

		// get the registerURL if passed via template
		var registerURL string
		if r, ok := box["registerURL"]; ok {
			if ru, ok := r.(string); ok {
				registerURL = ru
			}
		}

		// get the kontrolURL if passed via template
		var kontrolURL string
		if k, ok := box["kontrolURL"]; ok {
			if ku, ok := k.(string); ok {
				kontrolURL = ku
			}
		}

		data := pUser.Value{
			Username:        username,
			Groups:          []string{"sudo"},
			Hostname:        username, // no typo here. hostname = username
			KiteKey:         kiteKey,
			LatestKlientURL: klientURL,
			RegisterURL:     registerURL,
			KontrolURL:      kontrolURL,
		}

		// pass the values as a JSON encoded as bae64. Our script will decode
		// and unmarshall and use it inside the Vagrant box
		val, err := json.Marshal(&data)
		if err != nil {
			return nil, err
		}

		kiteIDs[resourceName] = kiteID
		encoded := base64.StdEncoding.EncodeToString(val)
		box["provisionData"] = encoded
		resource.VagrantBuild[resourceName] = box
	}

	template.Resource["vagrantkite_build"] = resource.VagrantBuild

	if err := template.hclUpdate(); err != nil {
		return nil, err
	}

	return kiteIDs, nil
}

func CheckKlients(ctx context.Context, kiteIDs KiteMap) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	var wg sync.WaitGroup
	var mu sync.Mutex // protects multierror and outputs
	var multiErrors error

	check := func(label, kiteId string) error {
		queryString := protocol.Kite{ID: kiteId}.String()
		klientRef, err := klient.NewWithTimeout(sess.Kite, queryString, time.Minute*5)
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

// isVariable checkes whether the given string is a template variable, such as:
// "${var.region}"
func IsVariable(v string) bool {
	return v[0] == '$'
}

// ParseAccountID parses an AWS arn string to get the Account ID
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
