package services

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/koding/integration/helpers"
	"github.com/koding/logging"
)

const (
	PAGERDUTY = "pagerduty"
)

var (
	ErrNotSupportConfigure = errors.New("not support configure")
	ErrMessageEmpty        = errors.New("Message is empty")
	ErrDataIsEmpty         = errors.New("Data is empty")
	ErrCouldNotValidate    = errors.New("Validation has error")
	ErrMessageLengthIsZero = errors.New("Length of message less than zero")
	ErrCouldNotGetSettings = errors.New("error while getting settings")
	ErrCouldNotGetEvents   = errors.New("error while getting events")
)

type Pagerduty struct {
	publicURL      string
	integrationURL string
	log            logging.Logger
}

type PagerdutyConfig struct {
	PublicURL      string
	IntegrationURL string
}

func NewPagerduty(pc *PagerdutyConfig, log logging.Logger) (*Pagerduty, error) {

	return &Pagerduty{
		publicURL:      pc.PublicURL,
		integrationURL: pc.IntegrationURL,
		log:            log.New(PAGERDUTY),
	}, nil
}

func (p *Pagerduty) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	token := req.URL.Query().Get("token")
	if token == "" {
		w.WriteHeader(http.StatusBadRequest)
		p.log.Error("Token is not found %v", ErrUserTokenIsNotValid)
		return
	}

	pm := &PagerdutyActivity{}
	err := ReadAndParse(req.Body, pm)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
	}

	if err := pm.validate(); err != nil {
		p.log.Error("Types are not valid %v", ErrCouldNotValidate)
		return
	}

	// fetch events from integration's db, if incoming event is not allowed by user, then stop process
	setting, err := helpers.GetSettings(token, p.integrationURL)
	if err != nil {
		p.log.Error("Could not get settings %v", ErrCouldNotGetSettings)
		return
	}

	events, err := helpers.UnmarshalEvents(setting)
	if err != nil {
		p.log.Error("Could not get events %v", ErrCouldNotGetEvents)
		return
	}

	// if incoming event is not allowed by user, we dont send the message to the integration worker
	// don't need to return any error , just stop process
	if !isAllowedEvent(events, pm.getType()) {
		return
	}

	// message will be created according to incoming data with its incident type
	// there are different incident types; trigger,acknowledge,resolve...
	// createMessage creates different meaningful message for each incident types
	message := pm.createMessage()

	pr := helpers.NewPushRequest(message)

	if err := helpers.Push(token, pr, p.integrationURL); err != nil {
		p.log.Error("Could not push message: %s", err)
		return
	}
}

//  isAllowedEvent checks if incoming event is in event list or not
func isAllowedEvent(events []string, incomingEvent string) bool {
	for _, ev := range events {
		if ev == incomingEvent {
			return true
		}
	}
	return false
}

func (p *Pagerduty) Configure(req *http.Request) (helpers.ConfigureResponse, error) {
	p.log.Error("Pagerduty doesn't support Configure", ErrNotSupportConfigure)
	return nil, nil
}

// ReadAndParse is written for incoming json data from outside integration server
// mainly, gets the parameter as body and model struct & parse the body into struct
// after parsing, closes the body..
func ReadAndParse(body io.ReadCloser, model interface{}) error {
	defer func() {
		if body != nil {
			body.Close()
		}
	}()

	if err := json.NewDecoder(body).Decode(model); err != nil {
		return err
	}

	return nil
}

// getType gets the type of the incoming data from pagerduty webhook
func (p *PagerdutyActivity) getType() string {

	return p.Messages[0].Type
}

// createMessage creates message that we use in mentioning
// according to message type
func (p *PagerdutyActivity) createMessage() string {
	switch p.getType() {
	case "incident.trigger":
		return p.trigger()
	case "incident.acknowledge":
		return p.acknowledge()
	case "incident.resolve":
		return p.resolve()
	case "incident.unacknowledge":
		return p.unacknowledge()
	case "incident.escalate":
		return p.escalate()
	case "incident.assign":
		return p.assign()
	default:
		return ""
	}
}

// NOTE:
// PD -> Pagerduty
// trigger -> Sent by PD when an incident is newly created/triggered
func (p *PagerdutyActivity) trigger() string {
	event := fmt.Sprintf("**Event**\nIncident Triggered ([%s](%s))", p.getServiceName(), p.getServiceURL())
	subject := fmt.Sprintf("**Subject**\n%s", p.getSubject())
	assigned := fmt.Sprintf("**Assigned To**\n%s", p.getAssignedTo())
	incidentDetails := fmt.Sprintf("[View Incident Details](%s)", p.getIncidentURL())

	return fmt.Sprintf(">%s\n%s\n%s\n%s",
		event,
		subject,
		assigned,
		incidentDetails,
	)
}

//acknowledge -> Sent by PD when an incident has had its status changed from triggered to acknowledged.
func (p *PagerdutyActivity) acknowledge() string {
	event := fmt.Sprintf("**Event**\nIncident Acknowledged ([%s](%s))", p.getServiceName(), p.getServiceURL())
	subject := fmt.Sprintf("**Subject**\n%s", p.getSubject())
	assigned := fmt.Sprintf("**Assigned To**\n%s", p.getAssignedTo())
	incidentDetails := fmt.Sprintf("[View Incident Details](%s)", p.getIncidentURL())

	return fmt.Sprintf(">%s\n%s\n%s\n%s",
		event,
		subject,
		assigned,
		incidentDetails,
	)
}

// resolve -> Sent by PD when an incident has been resolved.
func (p *PagerdutyActivity) resolve() string {
	event := fmt.Sprintf("**Event**\nIncident Resolved ([%s](%s))", p.getServiceName(), p.getServiceURL())
	subject := fmt.Sprintf("**Subject**\n%s", p.getSubject())
	resolved := fmt.Sprintf("**Assigned To**\n%s", p.getResolvedBy())
	incidentDetails := fmt.Sprintf("[View Incident Details](%s)", p.getIncidentURL())

	return fmt.Sprintf(">%s\n%s\n%s\n%s",
		event,
		subject,
		resolved,
		incidentDetails,
	)
}

// unacknowledge -> Sent by PD when an incident is unacknowledged due to timeout.
func (p *PagerdutyActivity) unacknowledge() string {
	event := fmt.Sprintf("**Event**\nIncident Unacknowledged ([%s](%s))", p.getServiceName(), p.getServiceURL())
	subject := fmt.Sprintf("**Subject**\n%s", p.getSubject())
	assigned := fmt.Sprintf("**Assigned To**\n%s", p.getAssignedTo())
	incidentDetails := fmt.Sprintf("[View Incident Details](%s)", p.getIncidentURL())

	return fmt.Sprintf(">%s\n%s\n%s\n%s",
		event,
		subject,
		assigned,
		incidentDetails,
	)
}

// escalate -> Sent by PD when an incident has been
// escalated to another user in the same escalation chain.
func (p *PagerdutyActivity) escalate() string {
	event := fmt.Sprintf("**Event**\nIncident Escalated ([%s](%s))", p.getServiceName(), p.getServiceURL())
	assigned := fmt.Sprintf("**Assigned To**\n%s", p.getAssignedTo())
	description := fmt.Sprintf("**Description**\n%s", p.getDescription())

	return fmt.Sprintf(">%s\n%s\n%s",
		event,
		assigned,
		description,
	)
}

// assign -> Sent by PD when an incident has been manually
// reassigned to another user in a different escalation chain.
func (p *PagerdutyActivity) assign() string {
	event := fmt.Sprintf("**Event**\nIncident Assigned ([%s](%s))", p.getServiceName(), p.getServiceURL())
	subject := fmt.Sprintf("**Subject**\n%s", p.getSubject())
	assigned := fmt.Sprintf("**Assigned To**\n%s", p.getAssignedTo())
	description := fmt.Sprintf("**Description**\n%s", p.getDescription())

	return fmt.Sprintf(">%s\n%s\n%s\n%s",
		event,
		subject,
		assigned,
		description,
	)
}

//
// THESE ARE EVENT INFORMATIONS OF JSON DATA & USED TO GET INFORMATIONS OF DATA EASILY
//
// getServiceName extracts the service name from incoming pagerduty json data
func (p *PagerdutyActivity) getServiceName() string {

	return p.Messages[0].Data.Incident.Service.Name
}

// getServiceURL gives the url of the service that pagerduty sent.
// For example: service of incoming data is Datadog
// This function's output would be -> https://koding-test.pagerduty.com/services/P1QP2YT in example service
func (p *PagerdutyActivity) getServiceURL() string {

	return p.Messages[0].Data.Incident.Service.HTMLURL
}

func (p *PagerdutyActivity) getSubject() string {

	return p.Messages[0].Data.Incident.TriggerSummaryData.Subject
}

// getAssignedTo return the names that task is assigned to:
// its output might be as an example: Mehmet & Ali
// Also these name 'Mehmet & Ali' are clickable items via markdown
func (p *PagerdutyActivity) getAssignedTo() string {
	for _, service := range p.Messages {

		assignedArray := make([]string, 0)
		user := ""
		for _, assigned := range service.Data.Incident.AssignedTo {
			user = fmt.Sprintf("[%s](%s)", assigned.Object.Name, assigned.Object.HTMLURL)
			assignedArray = append(assignedArray, user)
		}

		return strings.Join(assignedArray, " & ")
	}
	return ""
}

func (p *PagerdutyActivity) getResolvedBy() string {
	for _, service := range p.Messages {
		return fmt.Sprintf("[%s](%s)", service.Data.Incident.ResolvedByUser.Name, service.Data.Incident.ResolvedByUser.HTMLURL)
	}

	return ""
}

func (p *PagerdutyActivity) getDescription() string {

	return p.Messages[0].Data.Incident.Service.Description
}

// getIncidentURL gives the incident url of the service
// you can think that its just a url
// in example : https://koding-test.pagerduty.com/incidents/PD0MLVP
func (p *PagerdutyActivity) getIncidentURL() string {

	return p.Messages[0].Data.Incident.HTMLURL
}

func (p *PagerdutyActivity) validate() error {
	if p.Messages == nil {
		return ErrMessageEmpty
	}

	if len(p.Messages) < 1 {
		return ErrMessageLengthIsZero
	}

	if p.Messages[0].Type == "" {
		return ErrDataIsEmpty
	}

	return nil
}
