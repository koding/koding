package webhook

import (
	"errors"
	"time"

	"github.com/koding/bongo"
)

var (
	ErrInvalidIntegrationData = errors.New("invalid integration data")
	ErrTitleNotUnique         = errors.New("title is not unique")
)

type Integration struct {
	// unique identifier of the integration
	Id int64 `json:"id,string"`

	// Title of the integration
	Title string `json:"title" sql:"NOT NULL;TYPE:VARCHAR(200)"`

	// File path of the integration icon
	IconPath string `json:"iconPath" sql:"TYPE:VARCHAR(200)"`

	// Description of the integration
	Description string `json:"description" sql:"TYPE:TEXT"`

	// Instructions markdown of the integration
	Instructions string `json:"instructions" sql:"TYPE:TEXT"`

	// Type of the integration (incoming, outgoing)
	TypeConstant string `json:"typeConstant" sql:"TYPE:VARCHAR(100)"`

	// Current version of the integration
	Version string `json:"version" sql:"NOT NULL;TYPE:VARCHAR(6)"`

	// Creation date of the integration
	CreatedAt time.Time `json:"createdAt" sql:"NOT NULL"`

	// Modification date of the integration
	UpdatedAt time.Time `json:"updatedAt" sql:"NOT NULL"`

	// Deletion date of the integration
	DeletedAt time.Time `json:"deletedAt" sql:"NOT NULL"`
}

const (
	Integration_TYPE_INCOMING = "incoming"
	Integration_TYPE_OUTGOING = "outgoing"
)

func NewIntegration() *Integration {
	return &Integration{}
}

func (i *Integration) Create() error {

	if i.Title == "" || i.TypeConstant == "" {
		return ErrInvalidIntegrationData
	}

	selector := map[string]interface{}{
		"title": i.Title,
	}

	// no need to make it idempotent
	err := i.One(bongo.NewQS(selector))
	if err == nil {
		return ErrTitleNotUnique
	}

	if err != bongo.RecordNotFound {
		return err
	}

	return bongo.B.Create(i)
}
