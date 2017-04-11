package stack

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"koding/api"
	"koding/remoteapi"
	"koding/remoteapi/client"
	stacktemplate "koding/remoteapi/client/j_stack_template"

	"github.com/koding/kite"
	"github.com/koding/logging"
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

var requiredData = map[string]interface{}{
	"group": []interface{}{"slug"},
	"user":  []interface{}{"username"},
}

// Import creates a stack from the received stack template. Upon request it:
//
//  - creates a JStackTemplate
//  - updates JStackTemplate with machines obtained via terraformer plan command
//  - generates a JComputeStack
//  - builds a JComputeStack
//
// The method expects the received credentials to be already verified
// and bootstrapped.
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

	teamReq := &TeamRequest{
		Provider:   req.Provider,
		GroupName:  req.Team,
		Identifier: req.Credentials[req.Provider][0],
	}

	sb := &stackBuilder{
		req: &req,
		resp: &ImportResponse{
			Title: req.Title,
		},
		api: k.RemoteClient.New(&api.User{
			Username: r.Username,
			Team:     req.Team,
		}),
		timeout: k.RemoteClient.Timeout(),
		log:     k.Log.New("stackBuilder"),
	}

	if err := sb.buildTemplate(); err != nil {
		return nil, errors.New("failure creating template: " + err.Error())
	}

	planReq := &PlanRequest{
		Provider:        req.Provider,
		StackTemplateID: sb.resp.TemplateID,
		GroupName:       req.Team,
	}

	machines, err := k.doPlan(r, p, teamReq, planReq)
	if err != nil {
		return nil, errors.New("failure creating plan: " + err.Error())
	}

	if err := sb.setVerified(machines); err != nil {
		return nil, errors.New("failure updating template: " + err.Error())
	}

	if err := sb.buildStack(); err != nil {
		return nil, errors.New("failure creating stack: " + err.Error())
	}

	applyReq := &ApplyRequest{
		Provider:  req.Provider,
		StackID:   sb.resp.StackID,
		GroupName: req.Team,
	}

	eventID, err := k.doApply(r, p, teamReq, applyReq)
	if err != nil {
		return nil, errors.New("failure building stack: " + err.Error())
	}

	sb.resp.EventID = eventID

	return sb.resp, nil
}

func (k *Kloud) doPlan(r *kite.Request, p Provider, teamReq *TeamRequest, req *PlanRequest) ([]*Machine, error) {
	kiteReq := &kite.Request{
		Method:   "plan",
		Username: r.Username,
	}

	stack, ctx, err := k.newStack(kiteReq, teamReq)
	if err != nil {
		return nil, err
	}

	ctx = context.WithValue(ctx, PlanRequestKey, req)

	v, err := stack.HandlePlan(ctx)
	if err != nil {
		return nil, err
	}

	k.Log.Debug("plan received: %# v", v)

	var machines []*Machine

	if v, ok := v.(*PlanResponse); ok {
		if m, ok := v.Machines.([]*Machine); ok {
			machines = m
		}
	}

	return machines, nil
}

func (k *Kloud) doApply(r *kite.Request, p Provider, teamReq *TeamRequest, req *ApplyRequest) (eventID string, err error) {
	kiteReq := &kite.Request{
		Method:   "apply",
		Username: r.Username,
	}

	stack, ctx, err := k.newStack(kiteReq, teamReq)
	if err != nil {
		return "", err
	}

	ctx = context.WithValue(ctx, ApplyRequestKey, req)

	v, err := stack.HandleApply(ctx)
	if err != nil {
		return "", err
	}

	return v.(*ControlResult).EventId, nil
}

type stackBuilder struct {
	req     *ImportRequest
	resp    *ImportResponse
	log     logging.Logger
	api     *client.Koding
	timeout time.Duration
	once    sync.Once
}

func (sb *stackBuilder) buildTemplate() error {
	params := &stacktemplate.JStackTemplateCreateParams{
		Body: stacktemplate.JStackTemplateCreateBody{
			Template:    sb.reqTemplate(),
			Title:       &sb.req.Title,
			Credentials: sb.req.Credentials,
			Config: map[string]interface{}{
				"groupStack":        false,
				"requiredProviders": []interface{}{sb.req.Provider},
				"requiredData":      requiredData,
			},
		},
	}

	params.SetTimeout(sb.timeout)

	resp, err := sb.api.JStackTemplate.JStackTemplateCreate(params, nil)
	if err != nil {
		return err
	}

	sb.log.Debug("JStackTemplate.create response: %#v", resp)

	// TODO(rjeczalik): generated model does not have an ID field.
	// var tmpl models.JStackTemplate
	var tmpl struct {
		ID string `json:"_id"`
	}

	if err := remoteapi.Unmarshal(resp.Payload, &tmpl); err != nil {
		return err
	}

	sb.resp.TemplateID = tmpl.ID

	return nil
}

func (sb *stackBuilder) setVerified(machines []*Machine) error {
	body := map[string]interface{}{
		"config.verified": true,
	}

	if len(machines) != 0 {
		body["machines"] = machines
	}

	params := &stacktemplate.JStackTemplateUpdateParams{
		ID:   sb.resp.TemplateID,
		Body: body,
	}

	params.SetTimeout(sb.timeout)

	resp, err := sb.api.JStackTemplate.JStackTemplateUpdate(params, nil)
	if err != nil {
		return err
	}

	sb.log.Debug("JStackTemplate.update response: %#v", resp)

	return remoteapi.Unmarshal(&resp.Payload.DefaultResponse, nil)
}

func (sb *stackBuilder) buildStack() error {
	params := &stacktemplate.JStackTemplateGenerateStackParams{
		ID: sb.resp.TemplateID,
		Body: map[string]interface{}{
			"_id": sb.resp.TemplateID,
		},
	}

	params.SetTimeout(sb.timeout)

	resp, err := sb.api.JStackTemplate.JStackTemplateGenerateStack(params, nil)
	if err != nil {
		return err
	}

	var payload struct {
		Stack struct {
			ID string `json:"_id"`
		} `json:"stack"`
	}

	if err := remoteapi.Unmarshal(&resp.Payload.DefaultResponse, &payload); err != nil {
		return err
	}

	sb.log.Debug("JStackTemplate.generateStack response: %#v", resp)

	sb.resp.StackID = payload.Stack.ID

	return nil
}

func (sb *stackBuilder) reqTemplate() *string {
	s := string(sb.req.Template)
	return &s
}
