package terraformer

// Config defines the configuration.
type Config struct {
	// Port
	Port int `required:"true"`

	// Region
	Region string `required:"true"`

	// Environment
	Environment string `required:"true"`

	// Enable debug mode
	Debug bool

	// AWS secret and key
	AWS AWS
}

type AWS struct {
	Key    string `required:"true"`
	Secret string `required:"true"`
	Bucket string `required:"true"`
}
