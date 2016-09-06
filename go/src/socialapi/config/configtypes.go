package config

import "github.com/koding/runner"

type (
	// Config holds all the configuration variables of socialapi
	Config struct {
		// extend config with runner's
		runner.Config `structs:",flatten"`

		// Mongo holds full connection string
		Mongo string `env:"key=KONFIG_SOCIALAPI_MONGO                                 required"`

		// Protocol holds used protocol information
		Protocol string `env:"key=KONFIG_SOCIALAPI_PROTOCOL                           required"`

		Segment string `env:"key=KONFIG_SOCIALAPI_SEGMENT                             required"`

		// Email holds the required configuration data for email related workers
		Email Email

		// Sitemap holds configuration for Sitemap workers
		Sitemap Sitemap

		// Algolia holds configuration parameters for Aloglia search engine
		Algolia Algolia

		// Mixpanel holds configuration parameters for mixpanel
		Mixpanel Mixpanel

		// Limits holds limits for various cases
		Limits Limits

		Stripe Stripe

		// Holds access information for realtime message authenticator
		GateKeeper GateKeeper

		// Holds host and port information for integration worker
		Integration Integration

		// Holds host and port information for webhook middleware
		WebhookMiddleware WebhookMiddleware

		Kloud Kloud

		ProxyURL string

		CustomDomain CustomDomain

		GoogleapiServiceAccount GoogleapiServiceAccount

		Geoipdbpath string

		DisabledFeatures DisabledFeatures

		Janitor Janitor

		Github Github

		Slack Slack

		// SneakerS3 encrypts the credentials and stores these values in S3 storage system
		SneakerS3 SneakerS3

		Mailgun Mailgun

		DummyAdmins []string

		Druid Druid

		Clearbit string `env:"key=KONFIG_SOCIALAPI_CLEARBIT                             required"`
	}

	// Email holds Email Workers' config
	Email struct {
		Host                    string `env:"key=KONFIG_SOCIALAPI_EMAIL_HOST                     required"`
		Protocol                string `env:"key=KONFIG_SOCIALAPI_EMAIL_PROTOCOL                 required"`
		DefaultFromMail         string `env:"key=KONFIG_SOCIALAPI_EMAIL_DEFAULTFROMMAIL          required"`
		DefaultFromName         string `env:"key=KONFIG_SOCIALAPI_EMAIL_DEFAULTFROMNAME          required"`
		ForcedRecipientEmail    string `env:"key=KONFIG_SOCIALAPI_EMAIL_FORCEDRECIPIENTEMAIL"`
		ForcedRecipientUsername string `env:"key=KONFIG_SOCIALAPI_EMAIL_FORCEDRECIPIENTUSERNAME"`
		Username                string `env:"key=KONFIG_SOCIALAPI_EMAIL_USERNAME                 required"`
		Password                string `env:"key=KONFIG_SOCIALAPI_EMAIL_PASSWORD                 required"`
		TemplateRoot            string `env:"key=KONFIG_SOCIALAPI_EMAIL_TEMPLATEROOT 	        default=workers/sitemap/files/"`
	}

	// Sitemap holds Sitemap Workers' config
	Sitemap struct {
		RedisDB        int    `env:"key=KONFIG_SOCIALAPI_SITEMAP_REDISDB"`
		UpdateInterval string `env:"key=KONFIG_SOCIALAPI_SITEMAP_UPDATEINTERVAL"`
	}

	// Algolia holds Algolia service credentials
	Algolia struct {
		AppId            string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APPID                        required"`
		ApiKey           string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APIKEY                       required"`
		ApiSecretKey     string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APISECRETKEY                 required"`
		IndexSuffix      string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX                  required"`
		ApiSearchOnlyKey string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APISEARCHONLYKEY             required"`
	}

	// Mixpanel holds mixpanel credentials
	Mixpanel struct {
		Token   string `env:"key=KONFIG_SOCIALAPI_MIXPANEL_TOKEN                            required"`
		Enabled bool   `env:"key=KONFIG_SOCIALAPI_MIXPANEL_ENABLED"`
	}

	// Limits holds application's various limits
	Limits struct {
		MessageBodyMinLen    int    `env:"key=KONFIG_SOCIALAPI_LIMITS_MESSAGEBODYMINLEN     required default=1"`
		PostThrottleDuration string `env:"key=KONFIG_SOCIALAPI_LIMITS_POSTTHROTTLEDURATION  required default=5s"`
		PostThrottleCount    int    `env:"key=KONFIG_SOCIALAPI_LIMITS_POSTTHROTTLECOUNT     required default=20"`
	}

	Stripe struct {
		SecretToken string `env:"key=KONFIG_SOCIALAPI_STRIPE_SECRETTOKEN"`
	}

	GateKeeper struct {
		Host   string `env:"key=KONFIG_SOCIALAPI_GATEKEEPER_HOST"`
		Port   string `env:"key=KONFIG_SOCIALAPI_GATEKEEPER_PORT"`
		Pubnub Pubnub
	}

	Integration struct {
		Host string `env:"key=KONFIG_SOCIALAPI_INTEGRATION_HOST"`
		Port string `env:"key=KONFIG_SOCIALAPI_INTEGRATION_PORT"`
	}

	WebhookMiddleware struct {
		Host string `env:"key=KONFIG_SOCIALAPI_WEBHOOKMIDDLEWARE_HOST"`
		Port string `env:"key=KONFIG_SOCIALAPI_WEBHOOKMIDDLEWARE_PORT"`
	}

	Pubnub struct {
		PublishKey    string `env:"key=KONFIG_SOCIALAPI_GATEKEEPER_PUBNUB_PUBLISHKEY"`
		SubscribeKey  string `env:"key=KONFIG_SOCIALAPI_GATEKEEPER_PUBNUB_SUBSCRIBEKEY"`
		SecretKey     string `env:"key=KONFIG_SOCIALAPI_GATEKEEPER_PUBNUB_SECRETKEY"`
		ServerAuthKey string `env:"key=KONFIG_SOCIALAPI_GATEKEEPER_PUBNUB_SERVERAUTHKEY"`
		Enabled       bool   `env:"key=KONFIG_SOCIALAPI_GATEKEEPER_PUBNUB_ENABLED"`
		Origin        string `env:"key=KONFIG_SOCIALAPI_GATEKEEPER_PUBNUB_ORIGIN"`
	}

	CustomDomain struct {
		Public string `env:"key=KONFIG_SOCIALAPI_CUSTOMDOMAIN_PUBLIC"`
		Local  string `env:"key=KONFIG_SOCIALAPI_CUSTOMDOMAIN_LOCAL"`
	}

	Kloud struct {
		SecretKey string `env:"key=KONFIG_SOCIALAPI_KLOUD_SECRETKEY"`
		Address   string `env:"key=KONFIG_SOCIALAPI_KLOUD_ADDRESS"`
	}

	GoogleapiServiceAccount struct {
		ClientId              string `env:"key=KONFIG_SOCIALAPI_GOOGLEAPISERVICEACCOUNT_CLIENTID"`
		ClientSecret          string `env:"key=KONFIG_SOCIALAPI_GOOGLEAPISERVICEACCOUNT_CLIENTSECRET"`
		ServiceAccountEmail   string `env:"key=KONFIG_SOCIALAPI_GOOGLEAPISERVICEACCOUNT_SERVICEACCOUNTEMAIL"`
		ServiceAccountKeyFile string `env:"key=KONFIG_SOCIALAPI_GOOGLEAPISERVICEACCOUNT_SERVICEACCOUNTKEYFILE"`
	}

	DisabledFeatures struct {
		Moderation bool
		BotChannel bool
	}

	Janitor struct {
		Port      string `env:"key=KONFIG_SOCIALAPI_JANITOR_PORT"`
		SecretKey string `env:"key=KONFIG_SOCIALAPI_JANITOR_SECRETKEY"`
	}

	Github struct {
		ClientId     string `env:"key=KONFIG_SOCIALAPI_GITHUB_CLIENTID"`
		ClientSecret string `env:"key=KONFIG_SOCIALAPI_GITHUB_CLIENTSECRET"`
		RedirectUri  string `env:"key=KONFIG_SOCIALAPI_GITHUB_REDIRECTURI"`
	}

	Slack struct {
		ClientId          string `env:"key=KONFIG_SOCIALAPI_SLACK_CLIENTID"`
		ClientSecret      string `env:"key=KONFIG_SOCIALAPI_SLACK_CLIENTSECRET"`
		RedirectUri       string `env:"key=KONFIG_SOCIALAPI_SLACK_REDIRECTURI"`
		VerificationToken string `env:"key=KONFIG_SOCIALAPI_SLACK_VERIFICATIONTOKEN"`
	}

	SneakerS3 struct {
		//AWS_SECRET_ACCESS_KEY
		AwsSecretAccessKey string `env:"key=KONFIG_SOCIALAPI_AWS_SECRET_ACCESS_KEY"`
		// AWS_ACCESS_KEY_ID
		AwsAccesskeyId string `env:"key=KONFIG_SOCIALAPI_AWS_ACCESS_KEY_ID"`
		// SNEAKER_S3_PATH
		SneakerS3Path string `env:"key=KONFIG_SOCIALAPI_SNEAKER_S3_PATH"`
		// SNEAKER_MASTER_KEY
		SneakerMasterKey string `env:"key=KONFIG_SOCIALAPI_SNEAKER_MASTER_KEY"`
		// AWS_REGION
		AwsRegion string `env:"key=KONFIG_SOCIALAPI_AWS_REGION"`
	}

	Mailgun struct {
		Domain     string `env:"key=KONFIG_SOCIALAPI_MAILGUN_DOMAIN"`
		PrivateKey string `env:"key=KONFIG_SOCIALAPI_MAILGUN_PRIVATEKEY"`
		PublicKey  string `env:"key=KONFIG_SOCIALAPI_SLACK_PUBLICKEY"`
	}

	Druid struct {
		Host string `env:"key=KONFIG_SOCIALAPI_DRUID_HOST"`
		Port string `env:"key=KONFIG_SOCIALAPI_DRUID_PORT"`
	}
)
