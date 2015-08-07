package services

import "github.com/koding/logging"

type PivotalActivity struct {
	Kind             string            `json:"kind"`
	GUID             string            `json:"guid"`
	ProjectVersion   int               `json:"project_version"`
	Message          string            `json:"message"`
	Highlight        string            `json:"highlight"`
	Changes          []Change          `json:"changes"`
	PrimaryResources []PrimaryResource `json:"primary_resources"`
	Project          Project           `json:"project"`
	PerformedBy      PerformedBy       `json:"performed_by"`
	OccurredAt       int64             `json:"occurred_at"`
}

type Change struct {
	Kind           string         `json:"kind"`
	ChangeType     string         `json:"change_type"`
	ID             int            `json:"id"`
	OriginalValues OriginalValues `json:"original_values"`
	NewValues      NewValues      `json:"new_values"`
	Name           string         `json:"name"`
	StoryType      string         `json:"story_type"`
}

type OriginalValues struct {
	Estimate  interface{} `json:"estimate"`
	UpdatedAt int64       `json:"updated_at"`
}

type NewValues struct {
	Estimate  int   `json:"estimate"`
	UpdatedAt int64 `json:"updated_at"`
}

type PrimaryResource struct {
	Kind      string `json:"kind"`
	ID        int    `json:"id"`
	Name      string `json:"name"`
	StoryType string `json:"story_type"`
	URL       string `json:"url"`
}

type Project struct {
	Kind string `json:"kind"`
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type PerformedBy struct {
	Kind     string `json:"kind"`
	ID       int    `json:"id"`
	Name     string `json:"name"`
	Initials string `json:"initials"`
}

type ConfigurePivotalRequest struct {
	AccessToken  string        `json:"token"`
	ProjectID    int           `json: projectId`
	Events       []interface{} `json:"events"`
	ServiceToken string        `json:"serviceToken"`
}

type ConfigurePivotal struct {
	// URL that pivotal sends all the notification information
	WebhookURL string `json:"webhook_url"`

	// Version of the pivotal API
	WebhookVersion string `json:"webhook_version"`

	// Configured Webhook Id that will be used in update and delete requests, can be empty
	WebhookID string `json:"webhook_id,omitempty"`
}

type Pivotal struct {
	serverURL      string
	publicURL      string
	integrationURL string
	log            logging.Logger
}
