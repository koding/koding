package webhook

import (
	"encoding/json"
	"errors"
	"socialapi/models"
	"socialapi/request"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

var (
	ErrTitleNotSet         = errors.New("title is not set")
	ErrNameNotUnique       = errors.New("title is not unique")
	ErrNameNotSet          = errors.New("name is not set")
	ErrIntegrationNotFound = errors.New("integration is not found")
	ErrSettingNotFound     = errors.New("setting is not found")
)

type Integration struct {
	// unique identifier of the integration
	Id int64 `json:"id,string"`

	// Unique name of the integration
	Name string `json:"name" sql:"NOT NULL;TYPE:VARCHAR(25)"`

	// Title of the integration
	Title string `json:"title" sql:"NOT NULL;TYPE:VARCHAR(200)"`

	// Summary of the integration
	Summary string `json:"summary" sql:"TYPE:TEXT"`

	// File path of the integration icon
	IconPath string `json:"iconPath" sql:"TYPE:VARCHAR(200)"`

	// Description of the integration
	Description string `json:"description" sql:"TYPE:TEXT"`

	// Instructions markdown of the integration
	Instructions string `json:"instructions" sql:"TYPE:TEXT"`

	// Type of the integration (incoming, outgoing)
	TypeConstant string `json:"typeConstant" sql:"TYPE:VARCHAR(100)"`

	// Settings used for storing events and other optional data
	Settings gorm.Hstore `json:"settings"`

	// IsPublished used for wip integrations
	IsPublished bool `json:"-"`

	// Creation date of the integration
	CreatedAt time.Time `json:"createdAt" sql:"NOT NULL"`

	// Modification date of the integration
	UpdatedAt time.Time `json:"updatedAt" sql:"NOT NULL"`

	// Deletion date of the integration
	DeletedAt time.Time `json:"-" sql:"NOT NULL"`
}

const (
	Integration_TYPE_INCOMING = "incoming"
	Integration_TYPE_OUTGOING = "outgoing"
)

func NewIntegration() *Integration {
	return &Integration{
		IsPublished: true,
	}
}

func (i *Integration) Create() error {

	if i.Name == "" {
		return ErrNameNotSet
	}

	if i.Title == "" {
		return ErrTitleNotSet
	}

	if i.TypeConstant == "" {
		i.TypeConstant = Integration_TYPE_INCOMING
	}

	selector := map[string]interface{}{
		"name": i.Name,
	}

	// no need to make it idempotent
	err := i.One(bongo.NewQS(selector))
	if err == nil {
		return ErrNameNotUnique
	}

	if err != bongo.RecordNotFound {
		return err
	}

	return bongo.B.Create(i)
}

func (i *Integration) ByName(name string) error {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"name": name,
		},
	}

	err := i.One(query)
	if err == bongo.RecordNotFound {
		return ErrIntegrationNotFound
	}

	if err != nil {
		return err
	}

	return nil
}

func (i *Integration) List(q *request.Query) ([]Integration, error) {
	query := &bongo.Query{
		Sort: map[string]string{
			"name": "ASC",
		},
	}
	query.AddScope(models.ExcludeFields(q.Exclude))

	var ints []Integration
	err := i.Some(&ints, query)
	if err != nil {
		return nil, err
	}

	return ints, nil
}

func (i *Integration) FetchByIds(ids []int64) ([]Integration, error) {
	var integrations []Integration

	if len(ids) == 0 {
		return integrations, nil
	}

	if err := bongo.B.FetchByIds(i, &integrations, ids); err != nil {
		return nil, err
	}

	return integrations, nil
}

///////////////   Section   //////////////////

func (i *Integration) AddSettings(name string, value interface{}) error {
	if i.Settings == nil {
		i.Settings = gorm.Hstore{}
	}

	settings, err := json.Marshal(value)
	if err != nil {
		return err
	}

	settingsStr := string(settings)

	i.Settings[name] = &settingsStr

	return nil
}

func (i *Integration) GetSettings(name string, value interface{}) error {
	if i.Settings == nil {
		return ErrSettingNotFound
	}

	v, ok := i.Settings[name]
	if !ok {
		return ErrSettingNotFound
	}

	return json.Unmarshal([]byte(*v), &value)
}

////////////////   Event   /////////////////

type Event struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}

func NewEvent(name, description string) Event {
	return Event{
		Name:        name,
		Description: description,
	}
}

type Events []Event

func NewEvents(e ...Event) Events {
	events := Events{}
	events = append(events, e...)

	return events
}

func (i *Integration) AddEvents(e Events) error {
	return i.AddSettings("events", e)
}

func (i *Integration) GetEvents() (Events, error) {
	events := Events{}
	err := i.GetSettings("events", &events)

	return events, err
}
