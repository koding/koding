package api

import (
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

	res, err := c.CreateCountlyApp(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(res)
}

// CreateCountlyApp creates an app for given group.
func (c *CountlyAPI) CreateCountlyApp(slug string) (*CreateAppResponse, error) {
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

	info := &client.User{
		FullName: "Team " + slug,
		Username: slug,
		Password: utils.Pwgen(16),
		Email:    slug + "@koding.com",
		UserOf:   []string{app.ID},
	}

	user, err := c.client.CreateUser(info)
	if err != nil {
		return nil, err
	}
	c.log.Debug("created user for %q group: %+v", slug, user)

	res := &CreateAppResponse{
		AppID:  app.ID,
		AppKey: app.Key,
		APIKey: user.APIKey,
	}
	if err := persist(group.Id, res); err != nil {
		return nil, err
	}

	return res, nil
}

func persist(id bson.ObjectId, res *CreateAppResponse) error {
	return modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": id},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"countly.apiKey": res.APIKey,
				"countly.appKey": res.AppKey,
				"countly.appId":  res.AppID,
			},
		},
	)
}
