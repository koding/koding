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

		// Mixpanel holds configuration parameters for mixpanel
		Mixpanel Mixpanel

		// Limits holds limits for various cases
		Limits Limits

		Stripe Stripe

		// Holds access information for realtime message authenticator
		GateKeeper GateKeeper

		Kloud Kloud

		ProxyURL string

		CustomDomain CustomDomain

		GoogleapiServiceAccount GoogleapiServiceAccount

		Geoipdbpath string

		DisabledFeatures DisabledFeatures

		Github Github

		Slack Slack

		// SneakerS3 encrypts the credentials and stores these values in S3 storage system
		SneakerS3 SneakerS3

		Mailgun Mailgun

		DummyAdmins []string

		Clearbit string `env:"key=KONFIG_SOCIALAPI_CLEARBIT                             required"`

		Countly Countly
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
		BotChannel bool
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

	// Countly holds countly configuration.
	Countly struct {
		Host     string `json:"host"`
		APIPort  string `json:"apiPort"`
		Email    string `json:"email"`
		Username string `json:"username"`
		APIKey   string `json:"apiKey"`
		AppName  string `json:"appName"`
		AppOwner string `json:"appOwner"`
		AppID    string `json:"appId"`
		AppKey   string `json:"appKey"`
		Disabled bool   `json:"disabled"`
		FixApps  bool   `json:"disabled"`
	}
)
