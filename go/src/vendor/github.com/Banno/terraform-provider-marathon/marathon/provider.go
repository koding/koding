package marathon

import (
	"github.com/gambol99/go-marathon"
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
	"log"
	"net/http"
	"time"
)

// Provider is the provider for terraform
func Provider() terraform.ResourceProvider {
	return &schema.Provider{
		Schema: map[string]*schema.Schema{
			"url": &schema.Schema{
				Type:        schema.TypeString,
				Required:    true,
				DefaultFunc: schema.EnvDefaultFunc("MARATHON_URL", nil),
				Description: "Marathon's Base HTTP URL",
			},
			"request_timeout": &schema.Schema{
				Type:        schema.TypeInt,
				Optional:    true,
				Default:     10,
				Description: "'Request Timeout",
			},
			"deployment_timeout": &schema.Schema{
				Type:        schema.TypeInt,
				Optional:    true,
				Default:     600,
				Description: "'Deployment Timeout",
			},
			"basic_auth_user": &schema.Schema{
				Type:        schema.TypeString,
				Optional:    true,
				Default:     "",
				Description: "HTTP basic auth user",
			},
			"basic_auth_password": &schema.Schema{
				Type:        schema.TypeString,
				Optional:    true,
				Default:     "",
				Description: "HTTP basic auth password",
			},
			"log_output": &schema.Schema{
				Type:        schema.TypeBool,
				Optional:    true,
				Default:     true,
				Description: "Log output to stdout",
			},
		},

		ResourcesMap: map[string]*schema.Resource{
			"marathon_app": resourceMarathonApp(),
		},

		ConfigureFunc: providerConfigure,
	}
}

func providerConfigure(d *schema.ResourceData) (interface{}, error) {
	marathonConfig := marathon.NewDefaultConfig()

	marathonConfig.URL = d.Get("url").(string)
	marathonConfig.HTTPClient = &http.Client{
		Timeout: time.Duration(d.Get("request_timeout").(int)) * time.Second,
	}
	marathonConfig.HTTPBasicAuthUser = d.Get("basic_auth_user").(string)
	marathonConfig.HTTPBasicPassword = d.Get("basic_auth_password").(string)
	if d.Get("log_output").(bool) {
		marathonConfig.LogOutput = logWriter{}
	}
	marathonConfig.EventsTransport = marathon.EventsTransportSSE

	marathonConfig.HTTPClient = &http.Client{
		Timeout: (time.Duration(d.Get("deployment_timeout").(int)) * time.Second),
	}

	config := config{
		config: marathonConfig,
		DefaultDeploymentTimeout: time.Duration(d.Get("deployment_timeout").(int)) * time.Second,
	}

	log.Printf("Configured: %#v", config)

	if err := config.loadAndValidate(); err != nil {
		return nil, err
	}

	return config, nil
}

type logWriter struct {
}

func (lw logWriter) Write(p []byte) (n int, err error) {
	log.Print(string(p))
	return len(p), nil
}
