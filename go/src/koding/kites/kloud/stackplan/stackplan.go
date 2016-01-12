package stackplan

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/klient"
	pUser "koding/kites/kloud/scripts/provisionklient/userdata"
	"koding/kites/kloud/userdata"
	"strconv"
	"strings"
	"sync"
	"time"

	"gopkg.in/mgo.v2/bson"

	"golang.org/x/net/context"

	"github.com/fatih/structs"
	multierror "github.com/hashicorp/go-multierror"
	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite/protocol"
	"github.com/mitchellh/mapstructure"
	uuid "github.com/satori/go.uuid"
)

type AwsBootstrapOutput struct {
	ACL       string `json:"acl" mapstructure:"acl"`
	CidrBlock string `json:"cidr_block" mapstructure:"cidr_block"`
	IGW       string `json:"igw" mapstructure:"igw"`
	KeyPair   string `json:"key_pair" mapstructure:"key_pair"`
	RTB       string `json:"rtb" mapstructure:"rtb"`
	SG        string `json:"sg" mapstructure:"sg"`
	Subnet    string `json:"subnet" mapstructure:"subnet"`
	VPC       string `json:"vpc" mapstructure:"vpc"`
	AMI       string `json:"ami" mapstructure:"ami"`
}

// credPermissions defines the permission grid for the given method
var (
	credPermissionsMu sync.Mutex // protects credPermissions
	credPermissions   = map[string][]string{
		"bootstrap":    []string{"owner"},
		"plan":         []string{"user", "owner"},
		"apply":        []string{"user", "owner"},
		"authenticate": []string{"user", "owner"},
	}
)

type Machine struct {
	Provider    string            `json:"provider"`
	Label       string            `json:"label"`
	Region      string            `json:"region"`
	QueryString string            `json:"queryString,omitempty"`
	Attributes  map[string]string `json:"attributes"`
}

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

type Machines struct {
	Machines []Machine `json:"machines"`
}

type BuildData struct {
	Template string
	KiteIds  map[string]string
}

type KodingData struct {
	Account *models.Account `structs:"account"`
	Group   *models.Group   `structs:"group"`
	User    *models.User    `structs:"user"`
}

type Data struct {
	Creds      []*Credential
	KodingData *KodingData
}

type Credential struct {
	Provider   string
	Identifier string
	Data       map[string]string `mapstructure:"data"`
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

func InjectVagrantData(ctx context.Context, template *Template, username string) (*BuildData, error) {
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

	kiteIds := make(map[string]string)

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

		kiteIds[resourceName] = kiteID
		encoded := base64.StdEncoding.EncodeToString(val)
		box["provisionData"] = encoded
		resource.VagrantBuild[resourceName] = box
	}

	template.Resource["vagrantkite_build"] = resource.VagrantBuild

	if err := template.hclUpdate(); err != nil {
		return nil, err
	}

	b := &BuildData{
		KiteIds: kiteIds,
	}

	return b, nil
}

func InjectAWSData(ctx context.Context, template *Template, username string, data *Data) (*BuildData, error) {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	awsFound := false
	awsOutput := &AwsBootstrapOutput{}
	for _, cred := range data.Creds {
		if cred.Provider != "aws" {
			continue
		}

		awsFound = true

		if err := mapstructure.Decode(cred.Data, &awsOutput); err != nil {
			return nil, err
		}

		if structs.HasZero(awsOutput) {
			return nil, fmt.Errorf("Bootstrap data is incomplete: %v", awsOutput)
		}
	}

	if !awsFound {
		sess.Log.Debug("No AWS data found to be injected")
		return nil, nil
	}

	var resource struct {
		AwsInstance map[string]map[string]interface{} `hcl:"aws_instance"`
	}

	if err := template.DecodeResource(&resource); err != nil {
		return nil, err
	}

	if len(resource.AwsInstance) == 0 {
		return nil, fmt.Errorf("instance is empty: %v", resource.AwsInstance)
	}

	kiteIds := make(map[string]string)

	for resourceName, instance := range resource.AwsInstance {
		instance["key_name"] = awsOutput.KeyPair

		// if nothing is provided or the ami is empty use default Ubuntu AMI's
		if a, ok := instance["ami"]; !ok {
			instance["ami"] = awsOutput.AMI
		} else {
			if ami, ok := a.(string); ok && ami == "" {
				instance["ami"] = awsOutput.AMI
			}
		}

		// only ovveride if the user doesn't provider it's own subnet_id
		if instance["subnet_id"] == nil {
			instance["subnet_id"] = awsOutput.Subnet
			instance["security_groups"] = []string{awsOutput.SG}
		}

		// means there will be several instances, we need to create a userdata
		// with count interpolation, because each machine must have an unique
		// kite id.
		var count int = 1
		if c, ok := instance["count"]; ok {
			// we receive it as int
			cn, ok := c.(int)
			if !ok {
				return nil, fmt.Errorf("count statement should be an integer, got: %+v, %T", c, c)
			} else {
				count = cn
			}
		}

		// this part will be the same for all machines
		userCfg := &userdata.CloudInitConfig{
			Username: username,
			Groups:   []string{"sudo"},
			Hostname: username, // no typo here. hostname = username
		}

		// prepend custom script if available
		if c, ok := instance["user_data"]; ok {
			if customCMD, ok := c.(string); ok {
				userCfg.CustomCMD = customCMD
			}
		}

		kiteKeyName := fmt.Sprintf("kitekeys_%s", resourceName)

		// will be replaced with the kitekeys we create below
		userCfg.KiteKey = fmt.Sprintf("${lookup(var.%s, count.index)}", kiteKeyName)

		userdata, err := sess.Userdata.Create(userCfg)
		if err != nil {
			return nil, err
		}

		instance["user_data"] = string(userdata)

		// create independent kiteKey for each machine and create a Terraform
		// lookup map, which is used in conjuctuon with the `count.index`
		countKeys := map[string]string{}
		for i := 0; i < count; i++ {
			// create a new kite id for every new aws resource
			kiteUUID := uuid.NewV4()

			kiteId := kiteUUID.String()

			kiteKey, err := sess.Userdata.Keycreator.Create(username, kiteId)
			if err != nil {
				return nil, err
			}

			// if the count is greater than 1, terraform will change the labels
			// and append a number(starting with index 0) to each label
			if count != 1 {
				kiteIds[resourceName+"."+strconv.Itoa(i)] = kiteId
			} else {
				kiteIds[resourceName] = kiteId
			}

			countKeys[strconv.Itoa(i)] = kiteKey
		}

		template.Variable[kiteKeyName] = map[string]interface{}{
			"default": countKeys,
		}

		resource.AwsInstance[resourceName] = instance
	}

	template.Resource["aws_instance"] = resource.AwsInstance

	if err := template.hclUpdate(); err != nil {
		return nil, err
	}

	if err := template.shadowVariables("FORBIDDEN", "aws_access_key", "aws_secret_key"); err != nil {
		return nil, err
	}

	b := &BuildData{
		KiteIds: kiteIds,
	}

	return b, nil
}

func varsFromCredentials(creds *Data) map[string]string {
	vars := make(map[string]string, 0)
	for _, cred := range creds.Creds {
		for k, v := range cred.Data {
			vars[k] = v
		}
	}
	return vars
}

func CheckKlients(ctx context.Context, kiteIds map[string]string) error {
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

	for l, k := range kiteIds {
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

func FetchTerraformData(method, username, groupname string, identifiers []string) (*Data, error) {
	// fetch jaccount from username
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, err
	}

	// fetch jGroup from group slug name
	group, err := modelhelper.GetGroup(groupname)
	if err != nil {
		return nil, err
	}

	// fetch jUser from username
	user, err := modelhelper.GetUser(username)
	if err != nil {
		return nil, err
	}

	// validate if username belongs to groupnam
	selector := modelhelper.Selector{
		"targetId": account.Id,
		"sourceId": group.Id,
		"as": bson.M{
			"$in": []string{"member"},
		},
	}

	count, err := modelhelper.RelationshipCount(selector)
	if err != nil || count == 0 {
		return nil, fmt.Errorf("username '%s' does not belong to group '%s'", username, groupname)
	}

	// 2- fetch credential from identifiers via args
	credentials, err := modelhelper.GetCredentialsFromIdentifiers(identifiers...)
	if err != nil {
		return nil, err
	}

	// 3- count relationship with credential id and jaccount id as user or
	// owner. Any non valid credentials will be discarded
	validKeys := make(map[string]string, 0)

	credPermissionsMu.Lock()
	permittedTargets, ok := credPermissions[method]
	credPermissionsMu.Unlock()

	if !ok {
		return nil, fmt.Errorf("no permission data available for method '%s'", method)
	}

	for _, cred := range credentials {
		selector := modelhelper.Selector{
			"targetId": cred.Id,
			"sourceId": bson.M{
				"$in": []bson.ObjectId{account.Id, group.Id},
			},
			"as": bson.M{"$in": permittedTargets},
		}

		count, err := modelhelper.RelationshipCount(selector)
		if err != nil || count == 0 {
			// we return for any not validated identifier key.
			return nil, fmt.Errorf("credential with identifier '%s' is not validated", cred.Identifier)
		}

		validKeys[cred.Identifier] = cred.Provider
	}

	// 4- fetch credentialdata with identifier
	validIdentifiers := make([]string, 0)
	for pKey := range validKeys {
		validIdentifiers = append(identifiers, pKey)
	}

	credentialData, err := modelhelper.GetCredentialDatasFromIdentifiers(validIdentifiers...)
	if err != nil {
		return nil, err
	}

	// 5- return list of keys. We only support aws for now
	data := &Data{
		KodingData: &KodingData{
			Account: account,
			Group:   group,
			User:    user,
		},
		Creds: make([]*Credential, 0),
	}

	for _, c := range credentialData {
		provider, ok := validKeys[c.Identifier]
		if !ok {
			return nil, fmt.Errorf("provider is not found for identifer: %s", c.Identifier)
		}

		cred := &Credential{
			Provider:   provider,
			Identifier: c.Identifier,
		}

		if err := mapstructure.Decode(c.Meta, &cred.Data); err != nil {
			return nil, fmt.Errorf("malformed credential data found: %+v. Please fix it\n\terr:%s",
				c.Meta, err)
		}

		data.Creds = append(data.Creds, cred)
	}

	return data, nil
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
