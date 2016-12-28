package stack

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"koding/api"
	stacktemplate "koding/remoteapi/client/j_stack_template"
	"koding/remoteapi/models"

	"github.com/koding/kite"
	yaml "gopkg.in/yaml.v2"
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

func (k *Kloud) Import(r *kite.Request) (interface{}, error) {
	var req ImportRequest

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	if err := req.Valid(); err != nil {
		return nil, err
	}

	// TODO(rjeczalik): Refactor stack/provider/apply to make it possible to build
	// multiple stacks at once.
	if req.Provider == "" {
		providers, err := ReadProviders(req.Template)
		if err != nil {
			return nil, err
		}

		for _, provider := range providers {
			if _, ok := k.providers[provider]; ok {
				req.Provider = provider
				break
			}
		}
	}

	if req.Title == "" {
		req.Title = fmt.Sprintf("%s %s Stack", Pokemon(), strings.ToTitle(req.Provider))
	}

	p, ok := k.providers[req.Provider]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	c := k.RemoteClient.New(&api.User{
		Username: r.Username,
		Team:     req.Team,
	})

	tmplParams := &stacktemplate.PostRemoteAPIJStackTemplateCreateParams{
		Body: stacktemplate.PostRemoteAPIJStackTemplateCreateBody{
			Template:    pstring(req.Template),
			Title:       &req.Title,
			Credentials: req.Credentials,
		},
	}

	tmplParams.SetTimeout(k.RemoteClient.Timeout())

	tmplResp, err := c.JStackTemplate.PostRemoteAPIJStackTemplateCreate(tmplParams)
	if err != nil {
		return nil, errors.New("JStackTemplate.create failure: " + err.Error())
	}

	k.Log.Debug("JStackTemplate.create response: %#v", tmplResp)

	// TODO(rjeczalik): generated model does not have an ID field.
	// var tmpl models.JStackTemplate
	var tmpl struct {
		ID string `json:"_id"`
	}

	if err := response(tmplResp.Payload, &tmpl); err != nil {
		return nil, errors.New("JStackTemplate.create failure: " + err.Error())
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
		StackTemplateID: tmpl.ID,
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

	tmplUpdateParams := &stacktemplate.PostRemoteAPIJStackTemplateUpdateIDParams{
		ID: tmpl.ID,
		Body: map[string]interface{}{
			"config": map[string]interface{}{
				"verified": true,
			},
			"machines": machines,
		},
	}

	tmplUpdateParams.SetTimeout(k.RemoteClient.Timeout())

	tmplUpdateResp, err := c.JStackTemplate.PostRemoteAPIJStackTemplateUpdateID(tmplUpdateParams)
	if err != nil {
		return nil, fmt.Errorf("JStackTemplate.update failure: " + err.Error())
	}

	k.Log.Debug("JStackTemplate.update response: %#v", tmplUpdateResp)

	stackParams := &stacktemplate.PostRemoteAPIJStackTemplateGenerateStackIDParams{
		ID: tmpl.ID,
	}

	stackParams.SetTimeout(k.RemoteClient.Timeout())

	stackResp, err := c.JStackTemplate.PostRemoteAPIJStackTemplateGenerateStackID(stackParams)
	if err != nil {
		return nil, errors.New("JStackTemplate.generateStack failure: " + err.Error())
	}

	var resp struct {
		Stack struct {
			ID string `json:"_id"`
		} `json:"stack"`
	}

	if err := response(&stackResp.Payload.DefaultResponse, &resp); err != nil {
		return nil, errors.New("JStackTemplate.generateStack failure: " + err.Error())
	}

	k.Log.Debug("JStackTemplate.generateStack response: %#v", stackResp)

	kiteReq = &kite.Request{
		Method:   "apply",
		Username: r.Username,
	}

	applyReq := &ApplyRequest{
		Provider:  req.Provider,
		StackID:   resp.Stack.ID,
		GroupName: req.Team,
	}

	applyStack, ctx, err := k.NewStack(p, kiteReq, teamReq)
	if err != nil {
		return nil, err
	}

	ctx = context.WithValue(ctx, ApplyRequestKey, applyReq)

	v, err = applyStack.HandleApply(ctx)
	if err != nil {
		return nil, fmt.Errorf("error building stack: %s", err)
	}

	return &ImportResponse{
		TemplateID: tmpl.ID,
		StackID:    resp.Stack.ID,
		Title:      req.Title,
		EventID:    v.(*ControlResult).EventId,
	}, nil
}

func response(resp *models.DefaultResponse, v interface{}) error {
	if resp.Error != nil {
		if err, ok := resp.Error.(map[string]interface{}); ok {
			msg, _ := err["message"].(string)
			typ, _ := err["name"].(string)

			if msg != "" && typ != "" {
				return &kite.Error{
					Type:    typ,
					Message: msg,
				}
			}
		}

		return fmt.Errorf("%v", resp.Error)
	}

	if v == nil {
		return nil
	}

	p, err := jsonMarshal(resp.Data)
	if err != nil {
		return err
	}

	return json.Unmarshal(p, v)
}

func jsonMarshal(v interface{}) ([]byte, error) {
	var buf bytes.Buffer

	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)

	if err := enc.Encode(v); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
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

func pstring(p []byte) *string {
	if len(p) == 0 {
		return nil
	}

	s := string(p)
	return &s
}
