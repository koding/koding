package google

import (
	"bytes"
	"fmt"
	"strconv"
	"text/template"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/userdata"

	compute "google.golang.org/api/compute/v1"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1475345133 -pkg google -o bootstrap.json.tmpl.go bootstrap.json.tmpl
//go:generate go fmt bootstrap.json.tmpl.go

const (
	defaultMachineType  = "n1-standard-1"   // 1vCPU, 3.75GB memory.
	defaultMachineImage = "ubuntu-1404-lts" // From image family, size: 10GB.
)

var bootstrap = template.Must(template.New("").Parse(mustAsset("bootstrap.json.tmpl")))

type bootstrapConfig struct {
	NetworkName          string
	FirewallNameHTTP     string
	FirewallNameICMP     string
	FirewallNameInternal string
	FirewallNameRDP      string
	FirewallNameSSH      string
	FirewallNameKlient   string
}

// Stack implements the stack.Stack interface.
type Stack struct {
	*provider.BaseStack
}

var (
	_ provider.Stack = (*Stack)(nil) // public API
	_ stack.Stacker  = (*Stack)(nil) // internal API
)

func newStack(bs *provider.BaseStack) (provider.Stack, error) {
	return &Stack{BaseStack: bs}, nil
}

func (s *Stack) VerifyCredential(c *stack.Credential) error {
	cred := c.Credential.(*Cred)

	if err := cred.Valid(); err != nil {
		return err
	}

	computeService, err := cred.ComputeService()
	if err != nil {
		return &stack.Error{
			Err: err,
		}
	}

	// Try to get project info. If there is no error, project name and JSON key
	// are valid.
	_, err = compute.NewProjectsService(computeService).Get(cred.Project).Do()
	if err != nil {
		return &stack.Error{
			Err: err,
		}
	}

	return nil
}

func (s *Stack) BootstrapTemplates(c *stack.Credential) ([]*stack.Template, error) {
	cfg := &bootstrapConfig{
		NetworkName:          "koding-vn-" + c.Identifier,
		FirewallNameHTTP:     "koding-allow-http-" + c.Identifier,
		FirewallNameICMP:     "koding-allow-icmp-" + c.Identifier,
		FirewallNameInternal: "koding-allow-internal-" + c.Identifier,
		FirewallNameRDP:      "koding-allow-rdp-" + c.Identifier,
		FirewallNameSSH:      "koding-allow-ssh-" + c.Identifier,
		FirewallNameKlient:   "koding-allow-klient-" + c.Identifier,
	}

	t, err := newBootstrapTemplate(cfg)
	if err != nil {
		return nil, err
	}

	cred := c.Credential.(*Cred)
	t.Key = cred.Project + "-" + s.BootstrapArg().GroupName + "-" + c.Identifier
	return []*stack.Template{t}, nil
}

func (s *Stack) ApplyTemplate(c *stack.Credential) (*stack.Template, error) {
	t := s.Builder.Template

	cred := c.Credential.(*Cred)
	boot := c.Bootstrap.(*Bootstrap)

	var resource struct {
		GCInstance map[string]map[string]interface{} `hcl:"google_compute_instance"`
	}

	if err := t.DecodeResource(&resource); err != nil {
		return nil, err
	}

	if len(resource.GCInstance) == 0 {
		return nil, fmt.Errorf("there are no Google compute instances defined")
	}

	computeService, err := cred.ComputeService()
	if err != nil {
		s.Log.Warning("cannot create compute service: %s", err)
	}

	// Family2Image is used as a workaround for old terraform we use. It
	// translates image family name into the latest image name.
	//
	// TODO(ppknap): remove when we terraform is upgraded.
	f2i := Family2Image{
		GetFromFamily: s.getFromFamily(computeService),
	}

	// Image2Size is used to obtain image size from GCP API. This allows to set
	// up disk size when it's not provided. We need this in order to have proper
	// metadata in our database.
	i2s := Image2Size{
		GetDiskSize: s.getDiskSize(cred.Project, computeService),
	}

	for resourceName, instance := range resource.GCInstance {
		// Set default machine type if user didn't define it herself.
		if mt, ok := instance["machine_type"]; !ok {
			instance["machine_type"] = defaultMachineType
		} else {
			if mtstr, ok := mt.(string); ok && mtstr == "" {
				instance["machine_type"] = defaultMachineType
			}
		}

		// Set default zone if user didn't define it herself.
		const lookupZone = "${lookup(var.zones, var.google_region)}"
		if z, ok := instance["zone"]; !ok {
			instance["zone"] = lookupZone
		} else {
			if zstr, ok := z.(string); ok && zstr == "" {
				instance["zone"] = lookupZone
			}
		}

		// Set default image for disk if user didn't define it herself.
		if _, ok := instance["disk"]; !ok {
			instance["disk"] = []map[string]interface{}{
				{
					"image": defaultMachineImage,
				},
			}
		}
		instance["disk"] = i2s.Replace(f2i.Replace(instance["disk"]))

		// Set default network interface if user didn't define it herself.
		if _, ok := instance["network_interface"]; !ok {
			instance["network_interface"] = map[string]interface{}{
				"network":       boot.KodingNetworkID,
				"access_config": map[string]interface{}{},
			}
		}

		// Instance name is always required.
		instanceName, ok := instance["name"]
		if !ok {
			return nil, fmt.Errorf("%q instance name is required", resourceName)
		}
		if instr, ok := instanceName.(string); !ok || instr == "" {
			return nil, fmt.Errorf("%q instance name is invalid: %v", resourceName, instanceName)
		}

		// means there will be several instances, we need to create a userdata
		// with count interpolation, because each machine must have an unique
		// kite id.
		count := 1
		if n, ok := instance["count"].(int); ok && n > 1 {
			count = n
		}

		var labels []string
		if count > 1 {
			for i := 0; i < count; i++ {
				labels = append(labels, fmt.Sprintf("%s.%d", resourceName, i))
			}
		} else {
			labels = append(labels, resourceName)
		}

		kiteKeyName := fmt.Sprintf("kitekeys_%s", resourceName)

		// Cloud-Init can be injected only via "user-data" field defined in
		// root "metadata" object.
		var metadata = make(map[string]interface{})
		if meta, ok := instance["metadata"].([]map[string]interface{}); ok {
			metadata = flatten(meta)
		}
		s.Builder.InterpolateField(metadata, resourceName, "user-data")

		// this part will be the same for all machines
		userCfg := &userdata.CloudInitConfig{
			Username: s.Req.Username,
			Groups:   []string{"sudo"},
			Hostname: s.Req.Username, // no typo here. hostname = username
			KiteKey:  fmt.Sprintf("${lookup(var.%s, count.index)}", kiteKeyName),
		}

		if s, ok := metadata["user-data"].(string); ok {
			userCfg.UserData = s
		}

		userdata, err := s.Session.Userdata.Create(userCfg)
		if err != nil {
			return nil, err
		}

		metadata["user-data"] = string(userdata)
		instance["metadata"] = addPublicKey(metadata, s.Req.Username, s.Keys.PublicKey)

		// create independent kiteKey for each machine and create a Terraform
		// lookup map, which is used in conjuctuon with the `count.index`
		countKeys := make(map[string]string, count)
		for i, label := range labels {
			kiteKey, err := s.BuildKiteKey(label, s.Req.Username)
			if err != nil {
				return nil, err
			}

			countKeys[strconv.Itoa(i)] = kiteKey
		}

		t.Variable[kiteKeyName] = map[string]interface{}{
			"default": countKeys,
		}

		resource.GCInstance[resourceName] = instance
	}

	t.Resource["google_compute_instance"] = resource.GCInstance

	err = t.ShadowVariables("FORBIDDEN", "google_credentials")
	if err != nil {
		return nil, err
	}

	if err := t.Flush(); err != nil {
		return nil, err
	}

	content, err := t.JsonOutput()
	if err != nil {
		return nil, err
	}

	return &stack.Template{
		Content: content,
	}, nil
}

func (s *Stack) BootstrapArg() *stack.BootstrapRequest {
	return s.BaseStack.Arg.(*stack.BootstrapRequest)
}

// addPublicKey injects to user-publicKey ssh pair into instance metadata.
func addPublicKey(metadata map[string]interface{}, user, publicKey string) map[string]interface{} {
	key := "ssh-keys"
	// Fall back to depricated sshKeys instance level value. It may be used by
	// the user who creates instances that don't support newer ssh-keys format.
	if _, ok := metadata["sshKeys"]; ok {
		// User specified both fields. In that case we will use newer format.
		if _, ok := metadata[key]; !ok {
			key = "sshKeys"
		}
	}

	sshKeyNew := user + ":" + publicKey
	if sshKeyCpy, ok := metadata[key].(string); ok && sshKeyCpy != "" {
		sshKeyNew = sshKeyNew + `\n` + sshKeyCpy
	}

	metadata[key] = sshKeyNew
	return metadata
}

// getFromFamily calls GCE API and retrieves the latest image that is a part of
// provided family. If an error occurs, this function is no-op.
func (s *Stack) getFromFamily(computeService *compute.Service) func(string, string) string {
	if computeService == nil {
		return nil
	}

	imagesService := compute.NewImagesService(computeService)
	return func(project, family string) string {
		image, err := imagesService.GetFromFamily(project, family).Do()
		if err != nil {
			s.Log.Warning("cannot create image service: %s", err)
			return ""
		}

		if image == nil || image.Name == "" {
			s.Log.Warning("no image for family: %s (project: %s)", family, project)
			return ""
		}

		return image.Name
	}
}

// getFromFamily calls GCE API and retrieves the size of provided image.
func (s *Stack) getDiskSize(currentProject string, computeService *compute.Service) func(string, string) int {
	if computeService == nil {
		return nil
	}

	imagesService := compute.NewImagesService(computeService)
	return func(project, image string) int {
		if project == "" {
			project = currentProject
		}

		computeImg, err := imagesService.Get(project, image).Do()
		if err != nil {
			s.Log.Warning("cannot find image %q: %v (project: %q)", image, err, project)
			if project == currentProject {
				return 0
			}

			project = currentProject

			// Fall-back to current project.
			if computeImg, err = imagesService.Get(project, image).Do(); err != nil {
				s.Log.Warning("cannot find image %q in stack's project: %v", image, err)
				return 0
			}
		}

		if computeImg == nil || computeImg.DiskSizeGb == 0 {
			s.Log.Warning("no size metadata for image: %q (project: %q)", image, project)
			return 0
		}

		return int(computeImg.DiskSizeGb)
	}
}

func flatten(data []map[string]interface{}) map[string]interface{} {
	res := make(map[string]interface{})
	for _, ms := range data {
		for key, m := range ms {
			if val, ok := m.(string); ok {
				if res[key] == nil {
					res[key] = val
				} else {
					res[key] = res[key].(string) + "\n" + val
				}
			}
		}
	}

	return res
}

func mustAsset(s string) string {
	p, err := Asset(s)
	if err != nil {
		panic(err)
	}
	return string(p)
}

func newBootstrapTemplate(cfg *bootstrapConfig) (*stack.Template, error) {
	var buf bytes.Buffer

	if err := bootstrap.Execute(&buf, cfg); err != nil {
		return nil, err
	}

	return &stack.Template{
		Content: buf.String(),
	}, nil
}
