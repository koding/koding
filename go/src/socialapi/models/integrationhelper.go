// For the sake of resolving circular dependency, we have added
// read only integration helper here
package models

import (
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

const ChannelIntegrationBongoName = "integration.channel_integration"

const IntegrationBongoName = "integration.integration"

/////////////// ChannelIntegrationMeta ///////////////////

type ChannelIntegrationMeta struct {
	Id       int64  `json:"id,string"`
	IconPath string `json:"iconPath"`
	Title    string `json:"title"`
}

func NewChannelIntegrationMeta() *ChannelIntegrationMeta {
	return &ChannelIntegrationMeta{}
}

func (cim *ChannelIntegrationMeta) Populate(ci *ChannelIntegration, i *Integration) {
	// Later on, also image will be customizable
	cim.Id = ci.Id
	cim.IconPath = i.IconPath
	cim.Title = i.Title

	if ci.Settings == nil {
		return
	}

	val, ok := ci.Settings["customName"]
	if ok && val != nil && *val != "" {
		cim.Title = *val
	}
}

func (cim *ChannelIntegrationMeta) ByChannelIntegrationId(id int64) error {
	ci := new(ChannelIntegration)
	if err := ci.ById(id); err != nil {
		return err
	}

	i := new(Integration)
	if err := i.ById(ci.IntegrationId); err != nil {
		return err
	}

	cim.Populate(ci, i)

	return nil
}

/////////////// ChannelIntegration ///////////////////

type ChannelIntegration struct {
	// unique identifier of the channel integration
	Id int64

	// Settings field used for storing custom bot name, icon path and various
	// other data
	Settings gorm.Hstore

	// Id of the integration
	IntegrationId int64
}

func (i ChannelIntegration) GetId() int64 {
	return i.Id
}

func (i ChannelIntegration) BongoName() string {
	return ChannelIntegrationBongoName
}

func (i *ChannelIntegration) ById(id int64) error {
	return bongo.B.ById(i, id)
}

/////////////// Integration ///////////////////

type Integration struct {
	Id       int64
	IconPath string
	Title    string
}

func (i Integration) GetId() int64 {
	return i.Id
}

func (i Integration) BongoName() string {
	return IntegrationBongoName
}

func (i *Integration) ById(id int64) error {
	return bongo.B.ById(i, id)
}
