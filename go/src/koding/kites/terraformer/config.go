package terraformer

// Config defines the configuration.
type Config struct {
	// IP
	IP string `required:"true"`

	// Port
	Port int `required:"true"`

	// Region
	Region string `required:"true"`

	// Environment
	Environment string `required:"true"`

	// Enable debug mode
	Debug bool

	KontrolURL string `required:"true"`

	// Public
	Public bool // Try to register with a public ip
}
