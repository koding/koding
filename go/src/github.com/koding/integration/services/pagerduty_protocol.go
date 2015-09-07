package services

import "time"

type PagerdutyActivity struct {
	Messages []Message `json:"messages"`
}

type Message struct {
	Type      string    `json:"type"`
	Data      Data      `json:"data"`
	ID        string    `json:"id"`
	CreatedOn time.Time `json:"created_on"`
}

type Data struct {
	Incident Incident `json:"incident"`
}

type Incident struct {
	ID                    string             `json:"id"`
	IncidentNumber        int                `json:"incident_number"`
	CreatedOn             time.Time          `json:"created_on"`
	Status                string             `json:"status"`
	PendingActions        []PendingAction    `json:"pending_actions"`
	HTMLURL               string             `json:"html_url"`
	IncidentKey           string             `json:"incident_key"`
	Service               ServicePD          `json:"service"`
	EscalationPolicy      EscalationPolicy   `json:"escalation_policy"`
	AssignedToUser        AssignedToUser     `json:"assigned_to_user"`
	TriggerSummaryData    TriggerSummaryData `json:"trigger_summary_data"`
	TriggerDetailsHTMLURL string             `json:"trigger_details_html_url"`
	TriggerType           string             `json:"trigger_type"`
	LastStatusChangeOn    time.Time          `json:"last_status_change_on"`
	LastStatusChangeBy    LastStatusChangeBy `json:"last_status_change_by"`
	NumberOfEscalations   int                `json:"number_of_escalations"`
	ResolvedByUser        ResolvedByUser     `json:"resolved_by_user"`
	AssignedTo            []AssignedTo       `json:"assigned_to"`
}

type PendingAction struct {
	Type string    `json:"type"`
	At   time.Time `json:"at"`
}

type AssignedTo struct {
	At     time.Time `json:"at"`
	Object Object    `json:"object"`
}

type Object struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Email   string `json:"email"`
	HTMLURL string `json:"html_url"`
	Type    string `json:"type"`
}

type ServicePD struct {
	ID          string      `json:"id"`
	Name        string      `json:"name"`
	HTMLURL     string      `json:"html_url"`
	DeletedAt   interface{} `json:"deleted_at"`
	Description string      `json:"description"`
}

type EscalationPolicy struct {
	ID        string      `json:"id"`
	Name      string      `json:"name"`
	DeletedAt interface{} `json:"deleted_at"`
}

type TriggerSummaryData struct {
	Subject string `json:"subject"`
}

type ResolvedByUser struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Email   string `json:"email"`
	HTMLURL string `json:"html_url"`
}

type LastStatusChangeBy struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Email   string `json:"email"`
	HTMLURL string `json:"html_url"`
}

type AssignedToUser struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Email   string `json:"email"`
	HTMLURL string `json:"html_url"`
}
