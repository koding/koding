// Package team provides api functions for team worker
package team

import (
	"errors"
	mongomodels "koding/db/models"
	"socialapi/config"
	"socialapi/models"
	"strings"

	"koding/db/mongodb/modelhelper"
	"strconv"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	"github.com/f2prateek/clearbit-go"
	"github.com/hashicorp/go-multierror"
	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

var (
	ErrCompanyNameNotFound     = errors.New("company name not found")
	ErrCompanyMetricsNotFound  = errors.New("company metrics not found")
	ErrCompanyEmployeeNotFound = errors.New("company employee not found")
	ErrCompanyDomainNotFound   = errors.New("company domain not found")
)

// Controller holds the required parameters for team async operations
type Controller struct {
	log      logging.Logger
	config   *config.Config
	clearbit clearbit.Clearbit
}

// NewController creates a handler for consuming async operations of team
func NewController(log logging.Logger, config *config.Config) *Controller {
	return &Controller{
		log:      log,
		config:   config,
		clearbit: clearbit.New(config.Clearbit),
	}
}

// DefaultErrHandler handles the errors, we dont need to ack a message,
// continue to the success
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

// HandleChannel handles channel operations
func (c *Controller) HandleChannel(channel *models.Channel) error {
	if channel.TypeConstant != models.Channel_TYPE_GROUP {
		return nil
	}

	chans, err := channel.FetchAllChannelsOfGroup()
	if err != nil {
		return err
	}

	var errs *multierror.Error

	for _, ch := range chans {
		// we'r gonna innore all `not found` errors while deleting datas
		if err := ch.Delete(); err != nil && err != bongo.RecordNotFound {
			errs = multierror.Append(errs, err)
		}

		if err := ch.DeleteChannelParticipants(); err != nil {
			return err
		}

	}

	if errs.ErrorOrNil() != nil {
		return errs
	}

	return nil
}

// HandleCreator finds the creator of the channel, and tries to find its
// company name according to its email address
func (c *Controller) HandleCreator(channel *models.Channel) error {
	// we need to check environment, because we dont want to request to clearbit for our dev
	if channel.TypeConstant != models.Channel_TYPE_GROUP || c.config.Environment != "production" {
		return nil
	}

	creator, err := models.Cache.Account.ById(channel.CreatorId)
	if err != nil {
		return nil
	}
	user, err := modelhelper.GetUser(creator.Nick)
	if err != nil {
		return nil
	}
	// if user already has company, no need to fetch user's company info again.
	if user.CompanyId.Hex() != "" {
		return nil
	}
	// if user has no company data, then try to fetch info about company of user.
	userData, err := c.clearbit.Enrichment().Combined(user.Email)
	if err != nil {
		return err
	}

	if userData.Company == nil {
		return nil
	}

	if userData.Company.Name == nil {
		return nil
	}

	// if code line reach to here, it means that we got user's company data,
	// after that we are going to update user's data.
	var company *mongomodels.Company

	company, err = modelhelper.GetCompanyByNameOrSlug(*userData.Company.Name)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}
	// if company is not found in db, then create new one
	// after creation, update user's company with company id
	if err == mgo.ErrNotFound {
		err := checkValuesForCompany(userData.Company)
		if err != nil {
			return nil
		}

		// parse company data of clearbit package into our company model struct
		companyData := parseClearbitCompany(userData.Company)

		// create company in db if it doesn't exist
		company, err = modelhelper.CreateCompany(companyData)
		if err != nil {
			return err
		}
	}

	// update the company info of user if company exist in mongo
	selector := bson.M{"username": user.Name}
	update := bson.M{"companyId": company.Id}
	if err := modelhelper.UpdateUser(selector, update); err != nil {
		return err
	}
	return nil
}

func checkValuesForCompany(company *clearbit.Company) error {
	if company.Name == nil {
		return ErrCompanyNameNotFound
	}
	if company.Metrics == nil {
		return ErrCompanyMetricsNotFound
	}
	if company.Metrics.Employees == nil {
		return ErrCompanyEmployeeNotFound
	}
	if company.Domain == nil {
		return ErrCompanyDomainNotFound
	}

	return nil
}

// parseClearbitCompany parses company data of clearbit package into our company model struct
func parseClearbitCompany(company *clearbit.Company) *mongomodels.Company {
	return &mongomodels.Company{
		Name:      *company.Name,
		Slug:      strings.ToLower(*company.Name),
		Employees: *company.Metrics.Employees,
		Domain:    *company.Domain,
	}
}

// HandleParticipant handles participant operations
func (c *Controller) HandleParticipant(cp *models.ChannelParticipant) error {
	channel, err := models.Cache.Channel.ById(cp.ChannelId)
	if err != nil {
		c.log.Error("Channel: %d is not found", cp.ChannelId)
		return nil
	}

	if channel.TypeConstant != models.Channel_TYPE_GROUP {
		return nil // following logic ensures that channel is a group channel
	}

	group, err := modelhelper.GetGroup(channel.GroupName)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	if err == mgo.ErrNotFound {
		c.log.Error("Group: %s is not found in mongo", channel.GroupName)
		return nil
	}

	if err := c.handleDefaultChannels(group.DefaultChannels, cp); err != nil {
		return err
	}

	if err := c.handleParticipantRemove(cp); err != nil {
		return err
	}

	return nil
}

func (c *Controller) handleDefaultChannels(defaultChannels []string, cp *models.ChannelParticipant) error {
	for _, channelId := range defaultChannels {
		ci, err := strconv.ParseInt(channelId, 10, 64)
		if err != nil {
			c.log.Error("Couldnt parse channelId: %s, err: %s", channelId, err.Error())
			continue
		}

		if err := c.handleDefaultChannel(ci, cp); err != nil {
			return err
		}
	}

	return nil
}

func (c *Controller) handleDefaultChannel(channelId int64, cp *models.ChannelParticipant) error {
	defChan, err := models.Cache.Channel.ById(channelId)
	if err != nil && err != bongo.RecordNotFound {
		return err
	}

	if err == bongo.RecordNotFound {
		c.log.Error("Channel: %d is not found", channelId)
		return nil
	}

	// i wrote all of them to have a referance for future, because we
	// are gonna need this logic while implementing invitations ~ CS
	switch cp.StatusConstant {
	case models.ChannelParticipant_STATUS_ACTIVE:
		_, err = defChan.AddParticipant(cp.AccountId)
	case models.ChannelParticipant_STATUS_BLOCKED:
		err = defChan.RemoveParticipant(cp.AccountId)
	case models.ChannelParticipant_STATUS_LEFT:
		err = defChan.RemoveParticipant(cp.AccountId)
	}

	switch err {
	case models.ErrParticipantBlocked:
		// nothing to do here, user should be unblocked first
		return nil

	default:
		return nil
	}
}

// handleParticipantRemove removes a user from all channel participated channels
// in given group
func (c *Controller) handleParticipantRemove(cp *models.ChannelParticipant) error {
	channel, err := models.Cache.Channel.ById(cp.ChannelId)
	if err != nil {
		c.log.Error("Channel: %d is not found", cp.ChannelId)
		return nil
	}

	if channel.TypeConstant != models.Channel_TYPE_GROUP {
		return nil
	}

	if !models.IsIn(cp.StatusConstant,
		models.ChannelParticipant_STATUS_BLOCKED,
		models.ChannelParticipant_STATUS_LEFT,
	) {
		return nil
	}

	cpp := models.NewChannelParticipant()
	ids, err := cpp.FetchAllParticipatedChannelIdsInGroup(cp.AccountId, channel.GroupName)
	if err != nil && err != bongo.RecordNotFound {
		return err
	}

	if err == bongo.RecordNotFound {
		return nil
	}

	for _, id := range ids {
		ch := models.NewChannel()
		ch.Id = id
		if err := ch.RemoveParticipant(cp.AccountId); err != nil {
			return err
		}
	}
	return nil
}
