package config

import "github.com/koding/runner"

type (
	// Config holds all the configuration variables of socialapi
	Config struct {
		// extend config with runner's
		runner.Config

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

		Paypal Paypal

		// Holds access information for realtime message authenticator
		GateKeeper GateKeeper

		Kloud Kloud

		PaymentWebhook PaymentWebhook

		ProxyURL string

		CustomDomain CustomDomain

		GoogleapiServiceAccount GoogleapiServiceAccount

		Geoipdbpath string

		DisabledFeatures DisabledFeatures
	}

	// Email holds Email Workers' config
	Email struct {
		Host            string `env:"key=KONFIG_SOCIALAPI_EMAIL_HOST                     required"`
		Protocol        string `env:"key=KONFIG_SOCIALAPI_EMAIL_PROTOCOL                 required"`
		DefaultFromMail string `env:"key=KONFIG_SOCIALAPI_EMAIL_DEFAULTFROMMAIL          required"`
		DefaultFromName string `env:"key=KONFIG_SOCIALAPI_EMAIL_DEFAULTFROMNAME          required"`
		ForcedRecipient string `env:"key=KONFIG_SOCIALAPI_EMAIL_FORCEDRECIPIENT"`
		Username        string `env:"key=KONFIG_SOCIALAPI_EMAIL_USERNAME                 required"`
		Password        string `env:"key=KONFIG_SOCIALAPI_EMAIL_PASSWORD                 required"`
		TemplateRoot    string `env:"key=KONFIG_SOCIALAPI_EMAIL_TEMPLATEROOT 	        default=workers/sitemap/files/"`
	}

	// Sitemap holds Sitemap Workers' config
	Sitemap struct {
		RedisDB        int    `env:"key=KONFIG_SOCIALAPI_SITEMAP_REDISDB"`
		UpdateInterval string `env:"key=KONFIG_SOCIALAPI_SITEMAP_UPDATEINTERVAL"`
	}

	// Algolia holds Algolia service credentials
	Algolia struct {
		AppId        string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APPID                        required"`
		ApiKey       string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APIKEY                       required"`
		ApiSecretKey string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APISECRETKEY                 required"`
		IndexSuffix  string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX                  required"`
		ApiTokenKey  string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APITOKENKEY                  required"`
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

	Paypal struct {
		Username  string `env:"key=KONFIG_SOCIALAPI_PAYPAL_USERNAME"`
		Password  string `env:"key=KONFIG_SOCIALAPI_PAYPAL_PASSWORD"`
		Signature string `env:"key=KONFIG_SOCIALAPI_PAYPAL_SIGNATURE"`
		ReturnUrl string `env:"key=KONFIG_SOCIALAPI_PAYPAL_RETURNURL"`
		CancelUrl string `env:"key=KONFIG_SOCIALAPI_PAYPAL_CANCELURL"`
		IsSandbox bool   `env:"key=KONFIG_SOCIALAPI_PAYPAL_ISANDBOX"`
	}

	GateKeeper struct {
		Host   string `env:"key=KONFIG_SOCIALAPI_GATEKEEPER_HOST"`
		Port   string `env:"key=KONFIG_SOCIALAPI_GATEKEEPER_PORT"`
		Pubnub Pubnub
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

	PaymentWebhook struct {
		Port  string `env:"key=KONFIG_SOCIALAPI_PAYMENTWEBHOOK_PORT"`
		Debug bool   `env:"key=KONFIG_SOCIALAPI_PAYMENTWEBHOOK_DEBUG"`
	}

	GoogleapiServiceAccount struct {
		ClientId              string `env:"key=KONFIG_SOCIALAPI_GOOGLEAPISERVICEACCOUNT_CLIENTID"`
		ClientSecret          string `env:"key=KONFIG_SOCIALAPI_GOOGLEAPISERVICEACCOUNT_CLIENTSECRET"`
		ServiceAccountEmail   string `env:"key=KONFIG_SOCIALAPI_GOOGLEAPISERVICEACCOUNT_SERVICEACCOUNTEMAIL"`
		ServiceAccountKeyFile string `env:"key=KONFIG_SOCIALAPI_GOOGLEAPISERVICEACCOUNT_SERVICEACCOUNTKEYFILE"`
	}

	DisabledFeatures struct {
		Moderation bool
	}
)
