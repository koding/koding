package stack

import (
	"encoding/json"
	"errors"
	"fmt"

	"github.com/koding/kite"
)

// ImportRequest represents a request struct for "stack.import"
// kloud's kite method.
type ImportRequest struct {
	Credentials map[string][]string `json:"credentials"`
	Template    []byte              `json:"template"`
	Provider    string              `json:"provider"`
	Team        string              `json:"team"`
	Title       string              `json:"title,omitempty"`
}

// Valid implements the Validator interface.
func (r *ImportRequest) Valid() error {
	if len(r.Credentials) == 0 {
		return errors.New("empty credentials")
	}

	if len(r.Template) == 0 {
		return errors.New("empty template")
	}

	if r.Team == "" {
		return errors.New("empty team")
	}

	var raw json.RawMessage

	if err := json.Unmarshal(r.Template, &raw); err != nil {
		return fmt.Errorf("template is not a valid JSON: %s", err)
	}

	return nil
}

// ImportResponse represents a response struct for "stack.import"
// kloud's kite method.
type ImportResponse struct {
	TemplateID string `json:"templateId"`
	StackID    string `json:"stackId"`
	Title      string `json:"title"`
	EventID    string `json:"eventId"`
}

// Import
func (k *Kloud) Import(r *kite.Request) (interface{}, error) {
	var req ImportRequest

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	if err := req.Valid(); err != nil {
		return nil, err
	}

	if req.Title == "" {
		req.Title = fmt.Sprintf("%s's Stack", strings.ToTitle(r.Username))
	}

	p, ok := k.providers[req.Provider]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	account, err := modelhelper.GetAccount(r.Username)
	if err != nil {
		return nil, models.ResError(err, "jAccount")
	}

	user, err := modelhelper.GetUser(r.Username)
	if err != nil {
		return nil, models.ResError(err, "jUser")
	}

	team, err := modelhelper.GetGroup(req.Team)
	if err != nil {
		return nil, models.ResError(err, "jGroup")
	}

	sum := sha1.Sum(req.Template)
	raw, err := yamlReencode(req.Template)
	if err != nil {
		return nil, fmt.Errorf("failed to YAML-encode stack template: %s", err)
	}

	tmpl := models.NewStackTemplate(req.Provider, "")
	tmpl.Credentials = req.Credentials
	tmpl.OriginID = account.Id
	tmpl.Template.Details = bson.M{"lastUpdaterId": account.Id}
	tmpl.Group = req.Team
	tmpl.Template.Content = string(req.Template)
	tmpl.Template.RawContent = string(raw)
	tmpl.Template.Sum = hex.EncodeToString(sum[:])

	if err := modelhelper.CreateStackTemplate(tmpl); err != nil {
		return nil, fmt.Errorf("error creating jStackTemplate: %s", err)
	}

	teamReq := &TeamRequest{
		Provider:   req.Provider,
		GroupName:  req.Team,
		Identifier: req.Credentials[req.Provider][0],
	}

	kiteReq := &kite.Request{
		Method:   "plan",
		Username: r.Username,
	}

	planReq := &PlanRequest{
		Provider:        req.Provider,
		StackTemplateID: tmpl.Id.Hex(),
		GroupName:       req.Team,
	}

	planStack, ctx, err := k.NewStack(p, kiteReq, teamReq)
	if err != nil {
		return nil, err
	}

	ctx = context.WithValue(ctx, PlanRequestKey, planReq)

	v, err := planStack.HandlePlan(ctx)
	if err != nil {
		return nil, fmt.Errorf("error creating plan: %s", err)
	}

	k.Log.Debug("plan received %# v", v)

	var machines []*Machine

	if v, ok := v.(*PlanResponse); ok {
		if m, ok := v.Machines.([]*Machine); ok {
			machines = m
		}
	}

	if len(machines) == 0 {
		return nil, fmt.Errorf("stack contains no machines to build")
	}

	tmpl.Machines = make([]bson.M, len(machines))

	for i, machine := range machines {
		tmpl.Machines[i] = bson.M{
			"provider": req.Provider,
			"label":    machine.Label,
		}
	}

	now := time.Now().UTC()
	m := make([]*models.Machine, len(machines))

	for i, machine := range machines {
		uid := fmt.Sprintf("u%c%c%c%s", r.Username[0], req.Team[0],
			req.Provider[0], utils.StringN(8))

		m[i] = &models.Machine{
			ObjectId:   bson.NewObjectId(),
			Provider:   machine.Provider,
			Slug:       machine.Label,
			Label:      machine.Label,
			Credential: r.Username,
			Uid:        uid,
			Status: models.MachineStatus{
				State:      machinestate.Building.String(),
				Reason:     "Building by Kloud",
				ModifiedAt: now,
			},
			Users: []models.MachineUser{{
				Id:       user.ObjectId,
				Username: r.Username,
				Sudo:     true,
				Owner:    true,
			}},
			Groups: []models.MachineGroup{{
				Id: team.Id,
			}},
			Meta: bson.M{
				"alwaysOn":     false,
				"storage_size": 0,
				"type":         req.Provider,
			},
		}
	}

	if err := modelhelper.CreateMachines(m...); err != nil {
		return nil, models.ResError(err, "jMachine")
	}

	stack := &models.ComputeStack{
		Id:          bson.NewObjectId(),
		BaseStackId: tmpl.Id,
		OriginId:    account.Id,
		Credentials: tmpl.Credentials,
		Group:       req.Team,
		Revision:    tmpl.Template.Sum,
		Title:       req.Title,
		Machines:    make([]bson.ObjectId, 0, len(m)),
		Config: bson.M{
			"groupStack": false,
			"requiredData": bson.M{
				"group": []interface{}{"slug"},
				"user":  []interface{}{"username"},
			},
			"requiredProviders": []interface{}{req.Provider, "koding"},
			"verified":          true,
		},
		Meta: bson.M{
			"createdAt":  now,
			"modifiedAt": now,
			"tags":       nil,
			"views":      nil,
			"votes":      nil,
			"likes":      0,
		},
	}

	stack.Status.State = machinestate.NotInitialized.String()

	for i := range m {
		stack.Machines = append(stack.Machines, m[i].ObjectId)
	}

	if err := modelhelper.CreateComputeStack(stack); err != nil {
		return nil, models.ResError(err, "jComputeStack")
	}

	kiteReq = &kite.Request{
		Method:   "apply",
		Username: r.Username,
	}

	applyReq := &ApplyRequest{
		Provider:  req.Provider,
		StackID:   stack.Id.Hex(),
		GroupName: req.Team,
	}

	applyStack, ctx, err := k.NewStack(p, kiteReq, teamReq)
	if err != nil {
		return nil, err
	}

	ctx = context.WithValue(ctx, ApplyRequestKey, applyReq)

	v, err = applyStack.HandleApply(ctx)
	if err != nil {
		return nil, fmt.Errorf("error creating plan: %s", err)
	}

	return &ImportResponse{
		TemplateID: tmpl.Id.Hex(),
		StackID:    stack.Id.Hex(),
		Title:      req.Title,
		EventID:    v.(*ControlResult).EventId,
	}, nil
}

func yamlReencode(template []byte) ([]byte, error) {
	var m map[string]interface{}

	if err := json.Unmarshal(template, &m); err != nil {
		return nil, err
	}

	p, err := yaml.Marshal(m)
	if err != nil {
		return nil, err
	}

	return p, nil
}
