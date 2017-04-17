package marathon

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"path"

	"koding/kites/config"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/metadata"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/utils"

	marathon "github.com/gambol99/go-marathon"
	"github.com/hashicorp/terraform/terraform"
)

var klientPort = map[string]interface{}{
	"container_port": 56789,
	"host_port":      0,
	"protocol":       "tcp",
}

// Label represents a single app's label.
type Label struct {
	Label string
	AppID string
}

// Stack represents a Marathon application.
type Stack struct {
	*provider.BaseStack

	EntrypointBaseURL string
	ScreenURL         string
	CertURL           string
	KlientURL         string

	Labels []Label
	Count  int
}

var (
	_ provider.Stack = (*Stack)(nil) // public API
	_ stack.Stacker  = (*Stack)(nil) // internal API
)

func newStack(bs *provider.BaseStack) (provider.Stack, error) {
	s := &Stack{
		BaseStack:         bs,
		EntrypointBaseURL: metadata.DefaultEntrypointBaseURL,
		ScreenURL:         metadata.DefaultScreenURL,
		CertURL:           metadata.DefaultCertURL,
		KlientURL:         stack.Konfig.KlientGzURL(),
	}

	bs.PlanFunc = s.plan
	bs.StateFunc = s.state

	return s, nil
}

// VerifyCredential checks whether the given credentials
// can be used for deploying an app into Marathon.
func (s *Stack) VerifyCredential(c *stack.Credential) error {
	client, err := marathon.NewClient(*c.Credential.(*Credential).Config())
	if err != nil {
		return err
	}

	_, err = client.Ping()
	return err
}

// BootstrapTemplate implements the provider.Stack interface.
//
// It is a nop for Marathon.
func (s *Stack) BootstrapTemplates(*stack.Credential) (_ []*stack.Template, _ error) {
	return
}

// StacklyTemplate applies the given credentials to user's stack template.
func (s *Stack) ApplyTemplate(c *stack.Credential) (*stack.Template, error) {
	t := s.Builder.Template

	var resource struct {
		MarathonApp map[string]map[string]interface{} `hcl:"marathon_app"`
	}

	if err := t.DecodeResource(&resource); err != nil {
		return nil, err
	}

	if len(resource.MarathonApp) == 0 {
		return nil, errors.New("applications are empty")
	}

	for name, app := range resource.MarathonApp {
		if debug, ok := app["debug"].(bool); ok {
			s.Debug = debug
			delete(app, "debug")
		}

		s.convertInstancesToGroup(name, s.unique(c), app)

		if err := s.injectEntrypoint(app); err != nil {
			return nil, err
		}

		s.injectFetchEntrypoints(app)
		s.injectHealthChecks(app)

		if err := s.injectMetadata(app, name); err != nil {
			return nil, err
		}
	}

	t.Resource["marathon_app"] = resource.MarathonApp

	err := t.ShadowVariables("FORBIDDEN", "marathon_basic_auth_user", "marathon_basic_auth_password")
	if err != nil {
		return nil, errors.New("marathon: error shadowing: " + err.Error())
	}

	if err := t.Flush(); err != nil {
		return nil, errors.New("marathon: error flushing template: " + err.Error())
	}

	content, err := t.JsonOutput()
	if err != nil {
		return nil, err
	}

	return &stack.Template{
		Content: content,
	}, nil
}

// convertInstancesToGroup converts instances property to a count one.
//
// Since Marathon does not support instance indexing it's not possible
// to assign unique metadata for each of the instace, thus making such
// stack unusable for Koding. Relevant issue:
//
//   https://github.com/mesosphere/marathon/issues/1242
//
// What we do instead is we convert multiple instances of an application to
// an application group as a workaround.
func (s *Stack) convertInstancesToGroup(name, unique string, app map[string]interface{}) {
	instances, ok := app["instances"].(int)
	if ok {
		delete(app, "instances")
	} else {
		instances = 1
	}

	count, ok := app["count"].(int)
	if !ok {
		count = 1
	}

	count *= instances

	app["count"] = count

	// Each app within group must have unique name.
	var label string
	appID, ok := app["app_id"].(string)
	if !ok || appID == "" {
		label = path.Join("/", name)

		if count > 1 {
			appID = path.Join("/", name, path.Base(name)+"-"+unique+"-%v")
		} else {
			appID = path.Join("/", name+"-"+unique)
		}
	} else {
		label = path.Join("/", path.Base(appID))

		if count > 1 {
			appID = path.Join("/", appID, path.Base(appID)+"-%v")
		} else {
			appID = path.Join("/", appID)
		}
	}

	forEachContainer(app, func(map[string]interface{}) error {
		s.Count++
		return nil
	})

	if count > 1 {
		app["app_id"] = fmt.Sprintf(appID, "${count.index + 1}")

		for i := 1; i <= count; i++ {
			id := fmt.Sprintf(appID, i)

			if s.Count > 1 {
				for j := 1; j <= s.Count; j++ {
					s.Labels = append(s.Labels, Label{
						Label: fmt.Sprintf("%s-%d-%d", label, i, j),
						AppID: id,
					})
				}
			} else {
				s.Labels = append(s.Labels, Label{
					Label: fmt.Sprintf("%s-%d", label, i),
					AppID: id,
				})
			}
		}
	} else {
		app["app_id"] = appID

		if s.Count > 1 {
			for i := 1; i <= s.Count; i++ {
				s.Labels = append(s.Labels, Label{
					Label: fmt.Sprintf("%s-%d", label, i),
					AppID: appID,
				})
			}
		} else {
			s.Labels = append(s.Labels, Label{
				Label: label,
				AppID: appID,
			})
		}
	}
}

var ErrIncompatibleEntrypoint = errors.New(`marathon: setting "args" argument conflicts with Koding entrypoint injected into each container. Please use "cmd" argument instead.`)

// injectEntrypoint injects an entrypoint, which is responsible for installing
// klient before running container's command.
//
// The entrypoint is injected in a twofold manner:
//
//   - if "cmd" argument is used, it's prefixed with an entrypoint.N.sh script
//   - if container's default command (the one from Dockerfile) is used,
//     the container's entrypoint (by default /bin/sh) is replaced
//     with the Koding one
//
func (s *Stack) injectEntrypoint(app map[string]interface{}) error {
	if _, ok := app["args"]; ok {
		return ErrIncompatibleEntrypoint
	}

	i := 0

	injectEntrypoint := func(c map[string]interface{}) error {
		i++

		entrypoint := map[string]interface{}{
			"key":   "entrypoint",
			"value": fmt.Sprintf("/mnt/mesos/sandbox/entrypoint.${count.index * %d + %d}.sh", s.Count, i),
		}

		parametersGroup, ok := c["parameters"].(map[string]interface{})
		if !ok {
			parametersGroup = make(map[string]interface{})
			c["parameters"] = parametersGroup
		}

		parametersGroup["parameter"] = appendSlice(parametersGroup["parameter"], entrypoint)

		return nil
	}

	forEachContainer(app, injectEntrypoint)

	return nil
}

func (s *Stack) injectFetchEntrypoints(app map[string]interface{}) {
	fetch := getSlice(app["fetch"])

	fetch = append(fetch, map[string]interface{}{
		"uri":        s.ScreenURL,
		"executable": false,
		"cache":      true,
	}, map[string]interface{}{
		"uri":        s.CertURL,
		"executable": false,
		"cache":      true,
	}, map[string]interface{}{
		"uri":        s.KlientURL,
		"executable": false,
		"cache":      false,
	})

	for i := range s.Labels {
		fetch = append(fetch, map[string]interface{}{
			"uri":        fmt.Sprintf("%s/entrypoint.%d.sh", s.EntrypointBaseURL, i+1),
			"executable": true,
			"cache":      false,
		})
	}

	app["fetch"] = fetch
}

func (s *Stack) injectHealthChecks(app map[string]interface{}) {
	// TODO(rjeczalik): use http healthcheck - implement mapping port indexes,
	// the following fails with:
	//
	//   curl(52): Empty response from server
	//
	// Which makes Marathon redeploy healthy container.
	//
	// healthCheckGroup, ok := app["health_checks"].(map[string]interface{})
	// if !ok {
	//    healthCheckGroup = make(map[string]interface{})
	//    app["health_checks"] = healthCheckGroup
	// }
	// healthCheckGroup["health_check"] = appendSlice(healthCheckGroup["health_check"], healthCheck)

	containerCount := 0

	injectPortMapping := func(c map[string]interface{}) error {
		containerCount++

		portMappingGroup, ok := c["port_mappings"].(map[string]interface{})
		if !ok {
			portMappingGroup = make(map[string]interface{})
			c["port_mappings"] = portMappingGroup
		}

		portMappingGroup["port_mapping"] = appendSlice(portMappingGroup["port_mapping"], klientPort)

		return nil
	}

	forEachContainer(app, injectPortMapping)

	count, ok := app["count"].(int)
	if !ok {
		count = 1
	}

	count = count * containerCount

	ports := getSlice(app["ports"])

	for ; count > 0; count-- {
		ports = append(ports, 0)
	}

	app["ports"] = ports
}

func (s *Stack) injectMetadata(app map[string]interface{}, name string) error {
	envs := getObject(app["env"])

	cmd, ok := app["cmd"]
	if ok {
		delete(app, "cmd")
		envs["KODING_CMD"] = cmd
	}

	if val, ok := envs["KODING_KLIENT_URL"].(string); !ok || val == "" {
		envs["KODING_KLIENT_URL"] = s.KlientURL
	}

	for i, label := range s.Labels {
		kiteKey, err := s.BuildKiteKey(label.Label, s.Req.Username)
		if err != nil {
			return err
		}

		tunnelID := utils.RandString(8)

		if m, ok := s.Builder.Machines[label.Label]; ok && m.Uid != "" {
			tunnelID = m.Uid
		}

		konfig := &config.Konfig{
			Endpoints: stack.Konfig.Endpoints,
			TunnelID:  tunnelID,
			KiteKey:   kiteKey,
			Debug:     s.Debug,
		}

		metadata := map[string]interface{}{
			"konfig.konfig.konfigs": map[string]interface{}{
				konfig.ID(): konfig,
			},
			"konfig.konfig.konfigs.used": map[string]interface{}{
				"id": konfig.ID(),
			},
		}

		p, err := json.Marshal(metadata)
		if err != nil {
			return err
		}

		envs[fmt.Sprintf("KODING_METADATA_%d", i+1)] = base64.StdEncoding.EncodeToString(p)
	}

	app["env"] = envs

	return nil
}

func (s *Stack) plan() (stack.Machines, error) {
	machines := make(stack.Machines, len(s.Labels))

	for _, label := range s.Labels {
		m := &stack.Machine{
			Provider: "marathon",
			Label:    label.Label,
			Attributes: map[string]string{
				"app_id": label.AppID,
			},
		}

		machines[label.Label] = m
	}

	return machines, nil
}

func (s *Stack) unique(c *stack.Credential) string {
	if s.Builder.Stack != nil {
		return s.Req.Username + "-" + s.Builder.Stack.ID.Hex()
	}

	return s.Req.Username + "-" + c.Identifier
}

func (s *Stack) state(state *terraform.State, klients map[string]*provider.DialState) (map[string]*stack.Machine, error) {
	machines := make(map[string]*stack.Machine, len(s.Labels))

	for _, label := range s.Labels {

		state, ok := klients[label.Label]
		if !ok {
			return nil, fmt.Errorf("no klient state found for %q app", label)
		}

		m := &stack.Machine{
			Provider: "marathon",
			Label:    label.Label,
			Attributes: map[string]string{
				"app_id": label.AppID,
			},
			QueryString: state.KiteID,
			RegisterURL: state.KiteURL,
			State:       machinestate.Running,
			StateReason: "Created with kloud.apply",
		}

		if state.Err != nil {
			m.State = machinestate.Stopped
			m.StateReason = fmt.Sprintf("Stopped due to dial failure: %s", state.Err)
		}

		machines[m.Label] = m

	}

	return machines, nil
}

// Credential gives Marathon credentials that are attached
// to a current stack.
func (s *Stack) Credential() *Credential {
	return s.BaseStack.Credential.(*Credential)
}

func getObject(v interface{}) map[string]interface{} {
	object := make(map[string]interface{})

	switch v := v.(type) {
	case map[string]interface{}:
		object = v
	case map[string]string:
		for k, v := range v {
			object[k] = v
		}
	}

	return object
}

func getSlice(v interface{}) []interface{} {
	var slice []interface{}

	switch v := v.(type) {
	case nil:
	case []map[string]interface{}:
		slice = make([]interface{}, 0, len(v))

		for _, elem := range v {
			slice = append(slice, elem)
		}
	case []map[string]string:
		slice = make([]interface{}, 0, len(v))

		for _, elem := range v {
			slice = append(slice, elem)
		}
	case []interface{}:
		slice = v
	default:
		slice = []interface{}{v}
	}

	return slice
}

func forEachContainer(app map[string]interface{}, fn func(map[string]interface{}) error) error {
	for _, v := range getSlice(app["container"]) {
		containerGroup, ok := v.(map[string]interface{})
		if !ok {
			continue
		}

		for _, container := range getSlice(containerGroup["docker"]) {
			c, ok := container.(map[string]interface{})
			if !ok {
				continue
			}

			if err := fn(c); err != nil {
				return err
			}
		}
	}

	return nil
}

func appendSlice(slice interface{}, elems ...interface{}) []interface{} {
	return append(getSlice(slice), elems...)
}
