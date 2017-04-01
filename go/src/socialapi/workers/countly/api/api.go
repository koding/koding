package api

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"koding/tools/utils"
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/countly/client"

	"github.com/koding/logging"
	"github.com/koding/runner"
	"gopkg.in/mgo.v2/bson"
)

// CountlyAPI is a wrapper struct for api handlers.
type CountlyAPI struct {
	client      *client.Client
	log         logging.Logger
	globalOwner string
}

// CreateAppResponse holds the response for create app request return params.
type CreateAppResponse struct {
	AppID  string `json:"appId"`
	AppKey string `json:"appKey"`
	APIKey string `json:"apiKey"`
	UserID string `json:"-"`
}

// NewCountlyAPI creates api handler functions for countly
func NewCountlyAPI(cfg *config.Config) *CountlyAPI {
	logger := runner.MustGetLogger().New("countly-api")

	return &CountlyAPI{
		client: client.New(
			cfg.Countly.APIKey,
			client.SetBaseURL(cfg.Countly.Host),
			client.SetLogger(logger),
		),
		log:         logger,
		globalOwner: cfg.Countly.AppOwner,
	}
}

// Init handles account and user creation
func (c *CountlyAPI) Init(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	res, err := c.CreateApp(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(res)
}

// CreateApp creates an app for given group.
func (c *CountlyAPI) CreateApp(slug string) (*CreateAppResponse, error) {
	group, err := modelhelper.GetGroup(slug)
	if err != nil {
		return nil, err
	}

	// make this call idempotent
	if group.HasCountly() {
		return &CreateAppResponse{
			AppID:  group.Countly.AppID,
			AppKey: group.Countly.AppKey,
			APIKey: group.Countly.APIKey,
			UserID: group.Countly.UserID,
		}, nil
	}

	app, err := c.client.CreateApp(&client.App{
		Name:  slug,
		Owner: c.globalOwner,
	})
	if err != nil {
		return nil, err
	}
	c.log.Debug("created app for %q group: %+v", slug, app)

	user, err := c.EnsureUser(slug, app.ID)
	if err != nil {
		return nil, err
	}
	c.log.Debug("created user for %q group: %+v", slug, user)

	res := &CreateAppResponse{
		AppID:  app.ID,
		AppKey: app.Key,
		APIKey: user.APIKey,
		UserID: user.ID,
	}
	if err := persist(group.Id, res); err != nil {
		return nil, err
	}

	return res, nil
}

// EnsureUser creates user on Countly if it does not exist.
func (c *CountlyAPI) EnsureUser(slug, appID string) (*client.User, error) {
	email := slug + "@koding.com"
	info := &client.User{
		FullName: "Team " + slug,
		Username: slug,
		Password: utils.Pwgen(16),
		Email:    email,
		UserOf:   []string{appID},
	}

	user, err := c.client.CreateUser(info)
	if err != nil {
		return nil, err
	}

	if user.APIKey != "" {
		c.log.Debug("created user for %q group: %+v", slug, user)
		return user, nil
	}
	c.log.Info("couldnt create user for %q app: %+v trying to get previous one", slug, appID)

	users, err := c.client.GetAllUsers()
	if err != nil {
		return nil, err
	}

	for _, user := range users {
		if user.Email == email {
			return &user, nil
		}
	}

	return nil, errors.New("user not found")
}

func persist(id bson.ObjectId, res *CreateAppResponse) error {
	return modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": id},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"countly.apiKey": res.APIKey,
				"countly.appKey": res.AppKey,
				"countly.appId":  res.AppID,
				"countly.userId": res.UserID,
			},
		},
	)
}
