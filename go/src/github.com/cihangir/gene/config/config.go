package config

// Config holds the config parameters for gene package
type Config struct {
	// Schema holds the given schema file
	Schema string `required:"true"`

	// Target holds the target folder
	Target string `required:"true" default:"./"`

	// Generators holds the generator names for processing
	Generators []string `default:"model,statements,errors,clients,tests,functions"`
}
