package api

import (
	"koding/db/mongodb/modelhelper"
	"koding/tools/utils"
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/response"
	"socialapi/workers/countly/client"

	"github.com/koding/logging"
	"github.com/koding/runner"

	"gopkg.in/mgo.v2/bson"
)

const (
	// EndpointInit defines app creation endpoint
	EndpointInit = "/countly/init"
)

// AddHandlers injects handlers for countly system
func AddHandlers(m *mux.Mux, cfg *config.Config) {
	logger := runner.MustGetLogger().New("countly-api")

	capi := &CountlyAPI{
		client: client.New(
			cfg.Countly.APIKey,
			client.SetBaseURL(cfg.Countly.Host),
			client.SetLogger(logger),
		),
		log:         logger,
		globalOwner: cfg.Countly.AppOwner,
	}

	m.AddHandler(
		handler.Request{
			Handler:  capi.Init,
			Name:     "countly-init",
			Type:     handler.GetRequest,
			Endpoint: EndpointInit,
		},
	)
}

// CountlyAPI is a wrapper struct for api handlers.
type CountlyAPI struct {
	client      *client.Client
	log         logging.Logger
	globalOwner string
}

// Init handles account and user creation
func (c *CountlyAPI) Init(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// make this call idempotent
	if group.Countly.APIKey != "" {
		return response.NewOK(group.Countly)
	}

	appKey, apiKey, err := c.createCountlyApp(group.Slug)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := setAPIKey(group.Id, appKey, apiKey); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(map[string]string{"appKey": appKey, "apiKey": apiKey})
}

func (c *CountlyAPI) createCountlyApp(slug string) (appKey string, apiKey string, err error) {
	c.log.Info("creating app for %q group", slug)
	app, err := c.client.CreateApp(&client.App{
		Name:  slug,
		Owner: c.globalOwner,
	})
	if err != nil {
		return "", "", err
	}
	c.log.Debug("created app for %q group: %+v", slug, app)

	c.log.Info("creating user for %q group", slug)
	info := &client.User{
		FullName: "Team " + slug,
		Username: slug,
		Password: utils.Pwgen(16),
		Email:    slug + "@koding.com",
		UserOf:   []string{app.ID},
	}

	user, err := c.client.CreateUser(info)
	if err != nil {
		return "", "", err
	}
	c.log.Debug("created user for %q group: %+v", slug, user)

	return app.Key, user.APIKey, nil
}

func setAPIKey(id bson.ObjectId, appKey, apiKey string) error {
	return modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": id},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"countly.apiKey": apiKey,
				"countly.appKey": appKey,
			},
		},
	)
}
