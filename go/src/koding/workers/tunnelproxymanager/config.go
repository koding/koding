package main

type Config struct {
	EBEnvName string
	Region    string // optional

	AccessKeyID     string `required:"true" default:""`
	SecretAccessKey string `required:"true" default:""`
	Debug           bool
}
