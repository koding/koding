package aws

import (
	"github.com/hashicorp/terraform/helper/hashcode"
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

// Provider returns a terraform.ResourceProvider.
func Provider() terraform.ResourceProvider {
	// TODO: Move the validation to this, requires conditional schemas
	// TODO: Move the configuration to this, requires validation

	return &schema.Provider{
		Schema: map[string]*schema.Schema{
			"access_key": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				DefaultFunc: schema.MultiEnvDefaultFunc([]string{
					"AWS_ACCESS_KEY",
					"AWS_ACCESS_KEY_ID",
				}, nil),
				Description: descriptions["access_key"],
			},

			"secret_key": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				DefaultFunc: schema.MultiEnvDefaultFunc([]string{
					"AWS_SECRET_KEY",
					"AWS_SECRET_ACCESS_KEY",
				}, nil),
				Description: descriptions["secret_key"],
			},

			"token": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				DefaultFunc: schema.MultiEnvDefaultFunc([]string{
					"AWS_SESSION_TOKEN",
					"AWS_SECURITY_TOKEN",
				}, ""),
				Description: descriptions["token"],
			},

			"region": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				DefaultFunc: schema.MultiEnvDefaultFunc([]string{
					"AWS_REGION",
					"AWS_DEFAULT_REGION",
				}, nil),
				Description:  descriptions["region"],
				InputDefault: "us-east-1",
			},

			"max_retries": &schema.Schema{
				Type:        schema.TypeInt,
				Optional:    true,
				Default:     11,
				Description: descriptions["max_retries"],
			},

			"allowed_account_ids": &schema.Schema{
				Type:          schema.TypeSet,
				Elem:          &schema.Schema{Type: schema.TypeString},
				Optional:      true,
				ConflictsWith: []string{"forbidden_account_ids"},
				Set: func(v interface{}) int {
					return hashcode.String(v.(string))
				},
			},

			"forbidden_account_ids": &schema.Schema{
				Type:          schema.TypeSet,
				Elem:          &schema.Schema{Type: schema.TypeString},
				Optional:      true,
				ConflictsWith: []string{"allowed_account_ids"},
				Set: func(v interface{}) int {
					return hashcode.String(v.(string))
				},
			},
		},

		ResourcesMap: map[string]*schema.Resource{
			"aws_app_cookie_stickiness_policy": resourceAwsAppCookieStickinessPolicy(),
			"aws_autoscaling_group":            resourceAwsAutoscalingGroup(),
			"aws_autoscaling_notification":     resourceAwsAutoscalingNotification(),
			"aws_autoscaling_policy":           resourceAwsAutoscalingPolicy(),
			"aws_cloudwatch_metric_alarm":      resourceAwsCloudWatchMetricAlarm(),
			"aws_customer_gateway":             resourceAwsCustomerGateway(),
			"aws_db_instance":                  resourceAwsDbInstance(),
			"aws_db_parameter_group":           resourceAwsDbParameterGroup(),
			"aws_db_security_group":            resourceAwsDbSecurityGroup(),
			"aws_db_subnet_group":              resourceAwsDbSubnetGroup(),
			"aws_dynamodb_table":               resourceAwsDynamoDbTable(),
			"aws_ebs_volume":                   resourceAwsEbsVolume(),
			"aws_ecs_cluster":                  resourceAwsEcsCluster(),
			"aws_ecs_service":                  resourceAwsEcsService(),
			"aws_ecs_task_definition":          resourceAwsEcsTaskDefinition(),
			"aws_eip":                          resourceAwsEip(),
			"aws_elasticache_cluster":          resourceAwsElasticacheCluster(),
			"aws_elasticache_security_group":   resourceAwsElasticacheSecurityGroup(),
			"aws_elasticache_subnet_group":     resourceAwsElasticacheSubnetGroup(),
			"aws_elb":                          resourceAwsElb(),
			"aws_flow_log":                     resourceAwsFlowLog(),
			"aws_iam_access_key":               resourceAwsIamAccessKey(),
			"aws_iam_group_policy":             resourceAwsIamGroupPolicy(),
			"aws_iam_group":                    resourceAwsIamGroup(),
			"aws_iam_group_membership":         resourceAwsIamGroupMembership(),
			"aws_iam_instance_profile":         resourceAwsIamInstanceProfile(),
			"aws_iam_policy":                   resourceAwsIamPolicy(),
			"aws_iam_role_policy":              resourceAwsIamRolePolicy(),
			"aws_iam_role":                     resourceAwsIamRole(),
			"aws_iam_server_certificate":       resourceAwsIAMServerCertificate(),
			"aws_iam_user_policy":              resourceAwsIamUserPolicy(),
			"aws_iam_user":                     resourceAwsIamUser(),
			"aws_instance":                     resourceAwsInstance(),
			"aws_internet_gateway":             resourceAwsInternetGateway(),
			"aws_key_pair":                     resourceAwsKeyPair(),
			"aws_kinesis_stream":               resourceAwsKinesisStream(),
			"aws_lambda_function":              resourceAwsLambdaFunction(),
			"aws_launch_configuration":         resourceAwsLaunchConfiguration(),
			"aws_lb_cookie_stickiness_policy":  resourceAwsLBCookieStickinessPolicy(),
			"aws_main_route_table_association": resourceAwsMainRouteTableAssociation(),
			"aws_network_acl":                  resourceAwsNetworkAcl(),
			"aws_network_interface":            resourceAwsNetworkInterface(),
			"aws_proxy_protocol_policy":        resourceAwsProxyProtocolPolicy(),
			"aws_route53_delegation_set":       resourceAwsRoute53DelegationSet(),
			"aws_route53_record":               resourceAwsRoute53Record(),
			"aws_route53_zone_association":     resourceAwsRoute53ZoneAssociation(),
			"aws_route53_zone":                 resourceAwsRoute53Zone(),
			"aws_route53_health_check":         resourceAwsRoute53HealthCheck(),
			"aws_route_table":                  resourceAwsRouteTable(),
			"aws_route_table_association":      resourceAwsRouteTableAssociation(),
			"aws_s3_bucket":                    resourceAwsS3Bucket(),
			"aws_security_group":               resourceAwsSecurityGroup(),
			"aws_security_group_rule":          resourceAwsSecurityGroupRule(),
			"aws_spot_instance_request":        resourceAwsSpotInstanceRequest(),
			"aws_sqs_queue":                    resourceAwsSqsQueue(),
			"aws_sns_topic":                    resourceAwsSnsTopic(),
			"aws_sns_topic_subscription":       resourceAwsSnsTopicSubscription(),
			"aws_subnet":                       resourceAwsSubnet(),
			"aws_volume_attachment":            resourceAwsVolumeAttachment(),
			"aws_vpc_dhcp_options_association": resourceAwsVpcDhcpOptionsAssociation(),
			"aws_vpc_dhcp_options":             resourceAwsVpcDhcpOptions(),
			"aws_vpc_peering_connection":       resourceAwsVpcPeeringConnection(),
			"aws_vpc":                          resourceAwsVpc(),
			"aws_vpn_connection":               resourceAwsVpnConnection(),
			"aws_vpn_connection_route":         resourceAwsVpnConnectionRoute(),
			"aws_vpn_gateway":                  resourceAwsVpnGateway(),
		},

		ConfigureFunc: providerConfigure,
	}
}

var descriptions map[string]string

func init() {
	descriptions = map[string]string{
		"region": "The region where AWS operations will take place. Examples\n" +
			"are us-east-1, us-west-2, etc.",

		"access_key": "The access key for API operations. You can retrieve this\n" +
			"from the 'Security & Credentials' section of the AWS console.",

		"secret_key": "The secret key for API operations. You can retrieve this\n" +
			"from the 'Security & Credentials' section of the AWS console.",

		"token": "session token. A session token is only required if you are\n" +
			"using temporary security credentials.",

		"max_retries": "The maximum number of times an AWS API request is\n" +
			"being executed. If the API request still fails, an error is\n" +
			"thrown.",
	}
}

func providerConfigure(d *schema.ResourceData) (interface{}, error) {
	config := Config{
		AccessKey:  d.Get("access_key").(string),
		SecretKey:  d.Get("secret_key").(string),
		Token:      d.Get("token").(string),
		Region:     d.Get("region").(string),
		MaxRetries: d.Get("max_retries").(int),
	}

	if v, ok := d.GetOk("allowed_account_ids"); ok {
		config.AllowedAccountIds = v.(*schema.Set).List()
	}

	if v, ok := d.GetOk("forbidden_account_ids"); ok {
		config.ForbiddenAccountIds = v.(*schema.Set).List()
	}

	return config.Client()
}
