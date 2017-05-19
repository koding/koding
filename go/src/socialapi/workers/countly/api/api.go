package api

import (
	"errors"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/metrics"
	"koding/tools/utils"
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/countly/client"

	"github.com/koding/logging"
	"github.com/koding/runner"
	dogstatsd "github.com/narqo/go-dogstatsd-parser"
)

// CountlyAPI is a wrapper struct for api handlers.
type CountlyAPI struct {
	client         *client.Client
	log            logging.Logger
	cfg            *config.Config
	groupDataCache *groupDataCache
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
		log:            logger,
		cfg:            cfg,
		groupDataCache: newGroupCache(),
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

// PublishKiteMetrics publishes the kd and klient metrics to countly.
func (c *CountlyAPI) PublishKiteMetrics(u *url.URL, h http.Header, pr *metrics.PublishRequest) (int, http.Header, interface{}, error) {
	metrics := make(map[string][]client.Event, 0)

	for _, p := range pr.Data {
		m, err := dogstatsd.Parse(string(p))
		if err != nil {
			c.log.Info("Error while parsing metric %q, err: %s", string(p), err)
			continue
		}

		var count, duration int
		switch m.Type {
		case dogstatsd.Counter:
			val, _ := m.Value.(int64)
			count = int(val)
		case dogstatsd.Gauge, dogstatsd.Histogram:
			val, _ := m.Value.(float64)
			count = int(val)
		case dogstatsd.Meter, dogstatsd.Timer:
			val, _ := m.Value.(float64)
			duration = int(val)
		default:
			count = 1
		}

		// TODO: add validation for teams

		slug := getFromMap(m.Tags, "teamName", "group", "groupName")
		if slug == "" {
			continue
		}

		metrics[slug] = append(metrics[slug], client.Event{
			Key:          m.Name + "_" + string(m.Type),
			Count:        count,
			Dur:          duration,
			Segmentation: m.Tags,
		})
	}

	for slug, events := range metrics {
		if err := c.Publish(slug, events...); err != nil {
			response.NewBadRequest(err)
		}
	}

	return response.NewOK(nil)
}

// getFromMap returns the first value of the given vals.
func getFromMap(m map[string]string, vals ...string) string {
	for _, val := range vals {
		v, ok := m[val]
		if ok {
			return v
		}
	}

	return ""
}

// Publish is the glue function for ensuring a metric is pushlished with its
// supportive data.
func (c *CountlyAPI) Publish(slug string, events ...client.Event) error {
	if c.cfg.Countly.Disabled {
		return nil
	}

	groupData, _ := c.groupDataCache.BySlug(slug)
	appKey := ""
	if groupData != nil {
		appKey, _ = groupData.Payload.GetString("countly.appKey")
	}

	if appKey == "" {
		// if we should create non existing apps.
		if !c.cfg.Countly.FixApps {
			return nil
		}

		cres, err := c.CreateApp(slug)
		if err != nil {
			return err
		}

		appKey = cres.AppID
		groupData, err = c.groupDataCache.Refresh(slug)
		if err != nil {
			return err
		}
	}

	return c.client.WriteEvent(appKey, slug, events)
}

// CreateApp creates an app for given group.
func (c *CountlyAPI) CreateApp(slug string) (*mongomodels.Countly, error) {
	// make this call idempotent
	countlyInfo, err := modelhelper.FetchCountlyInfo(slug)
	if err == nil {
		return countlyInfo, nil
	}

	app, err := c.client.CreateApp(&client.App{
		Name:  slug,
		Owner: c.cfg.Countly.AppOwner,
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

	res := &mongomodels.Countly{
		AppID:  app.ID,
		AppKey: app.Key,
		APIKey: user.APIKey,
		UserID: user.ID,
	}

	if err := modelhelper.UpsertGroupData(slug, "countly", res); err != nil {
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
