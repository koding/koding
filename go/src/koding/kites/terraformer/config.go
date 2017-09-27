package terraformer

// Config defines the configuration.
type Config struct {
	// Port
	Port int `required:"true"`

	// Region for terraformer kite
	Region string `required:"true"`

	// Environment for terraformer kite
	Environment string `required:"true"`

	Debug          bool // Enable debug mode
	TerraformDebug bool // Enable Terrarform debug mode
	Test           bool // Enable test mode (go test)

	// AWS secret and key
	AWS AWS

	// LocalStorePath stores base path for local store
	LocalStorePath string `required:"true"`

	// SecretKey is used for kite-to-kite communication.
	SecretKey string

	KontrolURL string // if empty, default is used: "127.0.0.1:3000"
}

// AWS holds config variables for remote AWS
type AWS struct {
	Key    string
	Secret string
	Bucket string
}
