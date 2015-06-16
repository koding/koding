package main

type Config struct {
	Environment string `required:"true" default:"dev"`
	Queue       string
	EBEnvName   string
	Region      string `required:"true"`

	AccessKeyID     string `required:"true" default:""`
	SecretAccessKey string `required:"true" default:""`
	Debug           bool
}
