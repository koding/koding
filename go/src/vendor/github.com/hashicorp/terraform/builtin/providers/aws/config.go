package aws

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/hashicorp/go-cleanhttp"
	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/terraform/helper/logging"
	"github.com/hashicorp/terraform/terraform"

	"crypto/tls"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	awsCredentials "github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/credentials/ec2rolecreds"
	"github.com/aws/aws-sdk-go/aws/ec2metadata"
	"github.com/aws/aws-sdk-go/aws/request"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/apigateway"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/cloudformation"
	"github.com/aws/aws-sdk-go/service/cloudtrail"
	"github.com/aws/aws-sdk-go/service/cloudwatch"
	"github.com/aws/aws-sdk-go/service/cloudwatchevents"
	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
	"github.com/aws/aws-sdk-go/service/codecommit"
	"github.com/aws/aws-sdk-go/service/codedeploy"
	"github.com/aws/aws-sdk-go/service/directoryservice"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/ecr"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/aws/aws-sdk-go/service/efs"
	"github.com/aws/aws-sdk-go/service/elasticache"
	"github.com/aws/aws-sdk-go/service/elasticbeanstalk"
	elasticsearch "github.com/aws/aws-sdk-go/service/elasticsearchservice"
	"github.com/aws/aws-sdk-go/service/elb"
	"github.com/aws/aws-sdk-go/service/firehose"
	"github.com/aws/aws-sdk-go/service/glacier"
	"github.com/aws/aws-sdk-go/service/iam"
	"github.com/aws/aws-sdk-go/service/kinesis"
	"github.com/aws/aws-sdk-go/service/kms"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/aws/aws-sdk-go/service/opsworks"
	"github.com/aws/aws-sdk-go/service/rds"
	"github.com/aws/aws-sdk-go/service/redshift"
	"github.com/aws/aws-sdk-go/service/route53"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/aws/aws-sdk-go/service/sqs"
)

type Config struct {
	AccessKey     string
	SecretKey     string
	CredsFilename string
	Profile       string
	Token         string
	Region        string
	MaxRetries    int

	AllowedAccountIds   []interface{}
	ForbiddenAccountIds []interface{}

	DynamoDBEndpoint string
	KinesisEndpoint  string
	Ec2Endpoint      string
	IamEndpoint      string
	ElbEndpoint      string
	Insecure         bool
}

type AWSClient struct {
	cfconn               *cloudformation.CloudFormation
	cloudtrailconn       *cloudtrail.CloudTrail
	cloudwatchconn       *cloudwatch.CloudWatch
	cloudwatchlogsconn   *cloudwatchlogs.CloudWatchLogs
	cloudwatcheventsconn *cloudwatchevents.CloudWatchEvents
	dsconn               *directoryservice.DirectoryService
	dynamodbconn         *dynamodb.DynamoDB
	ec2conn              *ec2.EC2
	ecrconn              *ecr.ECR
	ecsconn              *ecs.ECS
	efsconn              *efs.EFS
	elbconn              *elb.ELB
	esconn               *elasticsearch.ElasticsearchService
	apigateway           *apigateway.APIGateway
	autoscalingconn      *autoscaling.AutoScaling
	s3conn               *s3.S3
	sqsconn              *sqs.SQS
	snsconn              *sns.SNS
	redshiftconn         *redshift.Redshift
	r53conn              *route53.Route53
	region               string
	rdsconn              *rds.RDS
	iamconn              *iam.IAM
	kinesisconn          *kinesis.Kinesis
	kmsconn              *kms.KMS
	firehoseconn         *firehose.Firehose
	elasticacheconn      *elasticache.ElastiCache
	elasticbeanstalkconn *elasticbeanstalk.ElasticBeanstalk
	lambdaconn           *lambda.Lambda
	opsworksconn         *opsworks.OpsWorks
	glacierconn          *glacier.Glacier
	codedeployconn       *codedeploy.CodeDeploy
	codecommitconn       *codecommit.CodeCommit
}

// Client configures and returns a fully initialized AWSClient
func (c *Config) Client() (interface{}, error) {
	// Get the auth and region. This can fail if keys/regions were not
	// specified and we're attempting to use the environment.
	var errs []error

	log.Println("[INFO] Building AWS region structure")
	err := c.ValidateRegion()
	if err != nil {
		errs = append(errs, err)
	}

	var client AWSClient
	if len(errs) == 0 {
		// store AWS region in client struct, for region specific operations such as
		// bucket storage in S3
		client.region = c.Region

		log.Println("[INFO] Building AWS auth structure")
		creds := getCreds(c.AccessKey, c.SecretKey, c.Token, c.Profile, c.CredsFilename)
		// Call Get to check for credential provider. If nothing found, we'll get an
		// error, and we can present it nicely to the user
		_, err = creds.Get()
		if err != nil {
			if awsErr, ok := err.(awserr.Error); ok && awsErr.Code() == "NoCredentialProviders" {
				errs = append(errs, fmt.Errorf(`No valid credential sources found for AWS Provider. 
  Please see https://terraform.io/docs/providers/aws/index.html for more information on 
  providing credentials for the AWS Provider`))
			} else {
				errs = append(errs, fmt.Errorf("Error loading credentials for AWS Provider: %s", err))
			}
			return nil, &multierror.Error{Errors: errs}
		}
		awsConfig := &aws.Config{
			Credentials: creds,
			Region:      aws.String(c.Region),
			MaxRetries:  aws.Int(c.MaxRetries),
			HTTPClient:  cleanhttp.DefaultClient(),
		}

		if logging.IsDebugOrHigher() {
			awsConfig.LogLevel = aws.LogLevel(aws.LogDebugWithHTTPBody)
			awsConfig.Logger = awsLogger{}
		}

		if c.Insecure {
			transport := awsConfig.HTTPClient.Transport.(*http.Transport)
			transport.TLSClientConfig = &tls.Config{
				InsecureSkipVerify: true,
			}
		}

		// Set up base session
		sess := session.New(awsConfig)
		sess.Handlers.Build.PushFrontNamed(addTerraformVersionToUserAgent)

		log.Println("[INFO] Initializing IAM Connection")
		awsIamSess := sess.Copy(&aws.Config{Endpoint: aws.String(c.IamEndpoint)})
		client.iamconn = iam.New(awsIamSess)

		err = c.ValidateCredentials(client.iamconn)
		if err != nil {
			errs = append(errs, err)
		}

		// Some services exist only in us-east-1, e.g. because they manage
		// resources that can span across multiple regions, or because
		// signature format v4 requires region to be us-east-1 for global
		// endpoints:
		// http://docs.aws.amazon.com/general/latest/gr/sigv4_changes.html
		usEast1Sess := sess.Copy(&aws.Config{Region: aws.String("us-east-1")})

		log.Println("[INFO] Initializing DynamoDB connection")
		dynamoSess := sess.Copy(&aws.Config{Endpoint: aws.String(c.DynamoDBEndpoint)})
		client.dynamodbconn = dynamodb.New(dynamoSess)

		log.Println("[INFO] Initializing ELB connection")
		awsElbSess := sess.Copy(&aws.Config{Endpoint: aws.String(c.ElbEndpoint)})
		client.elbconn = elb.New(awsElbSess)

		log.Println("[INFO] Initializing S3 connection")
		client.s3conn = s3.New(sess)

		log.Println("[INFO] Initializing SQS connection")
		client.sqsconn = sqs.New(sess)

		log.Println("[INFO] Initializing SNS connection")
		client.snsconn = sns.New(sess)

		log.Println("[INFO] Initializing RDS Connection")
		client.rdsconn = rds.New(sess)

		log.Println("[INFO] Initializing Kinesis Connection")
		kinesisSess := sess.Copy(&aws.Config{Endpoint: aws.String(c.KinesisEndpoint)})
		client.kinesisconn = kinesis.New(kinesisSess)

		log.Println("[INFO] Initializing Elastic Beanstalk Connection")
		client.elasticbeanstalkconn = elasticbeanstalk.New(sess)

		authErr := c.ValidateAccountId(client.iamconn)
		if authErr != nil {
			errs = append(errs, authErr)
		}

		log.Println("[INFO] Initializing Kinesis Firehose Connection")
		client.firehoseconn = firehose.New(sess)

		log.Println("[INFO] Initializing AutoScaling connection")
		client.autoscalingconn = autoscaling.New(sess)

		log.Println("[INFO] Initializing EC2 Connection")

		awsEc2Sess := sess.Copy(&aws.Config{Endpoint: aws.String(c.Ec2Endpoint)})
		client.ec2conn = ec2.New(awsEc2Sess)

		log.Println("[INFO] Initializing ECR Connection")
		client.ecrconn = ecr.New(sess)

		log.Println("[INFO] Initializing API Gateway")
		client.apigateway = apigateway.New(sess)

		log.Println("[INFO] Initializing ECS Connection")
		client.ecsconn = ecs.New(sess)

		log.Println("[INFO] Initializing EFS Connection")
		client.efsconn = efs.New(sess)

		log.Println("[INFO] Initializing ElasticSearch Connection")
		client.esconn = elasticsearch.New(sess)

		log.Println("[INFO] Initializing Route 53 connection")
		client.r53conn = route53.New(usEast1Sess)

		log.Println("[INFO] Initializing Elasticache Connection")
		client.elasticacheconn = elasticache.New(sess)

		log.Println("[INFO] Initializing Lambda Connection")
		client.lambdaconn = lambda.New(sess)

		log.Println("[INFO] Initializing Cloudformation Connection")
		client.cfconn = cloudformation.New(sess)

		log.Println("[INFO] Initializing CloudWatch SDK connection")
		client.cloudwatchconn = cloudwatch.New(sess)

		log.Println("[INFO] Initializing CloudWatch Events connection")
		client.cloudwatcheventsconn = cloudwatchevents.New(sess)

		log.Println("[INFO] Initializing CloudTrail connection")
		client.cloudtrailconn = cloudtrail.New(sess)

		log.Println("[INFO] Initializing CloudWatch Logs connection")
		client.cloudwatchlogsconn = cloudwatchlogs.New(sess)

		log.Println("[INFO] Initializing OpsWorks Connection")
		client.opsworksconn = opsworks.New(usEast1Sess)

		log.Println("[INFO] Initializing Directory Service connection")
		client.dsconn = directoryservice.New(sess)

		log.Println("[INFO] Initializing Glacier connection")
		client.glacierconn = glacier.New(sess)

		log.Println("[INFO] Initializing CodeDeploy Connection")
		client.codedeployconn = codedeploy.New(sess)

		log.Println("[INFO] Initializing CodeCommit SDK connection")
		client.codecommitconn = codecommit.New(usEast1Sess)

		log.Println("[INFO] Initializing Redshift SDK connection")
		client.redshiftconn = redshift.New(sess)

		log.Println("[INFO] Initializing KMS connection")
		client.kmsconn = kms.New(sess)
	}

	if len(errs) > 0 {
		return nil, &multierror.Error{Errors: errs}
	}

	return &client, nil
}

// ValidateRegion returns an error if the configured region is not a
// valid aws region and nil otherwise.
func (c *Config) ValidateRegion() error {
	var regions = [12]string{"us-east-1", "us-west-2", "us-west-1", "eu-west-1",
		"eu-central-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1",
		"ap-northeast-2", "sa-east-1", "cn-north-1", "us-gov-west-1"}

	for _, valid := range regions {
		if c.Region == valid {
			return nil
		}
	}
	return fmt.Errorf("Not a valid region: %s", c.Region)
}

// Validate credentials early and fail before we do any graph walking.
// In the case of an IAM role/profile with insuffecient privileges, fail
// silently
func (c *Config) ValidateCredentials(iamconn *iam.IAM) error {
	_, err := iamconn.GetUser(nil)

	if awsErr, ok := err.(awserr.Error); ok {
		if awsErr.Code() == "AccessDenied" || awsErr.Code() == "ValidationError" {
			log.Printf("[WARN] AccessDenied Error with iam.GetUser, assuming IAM profile")
			// User may be an IAM instance profile, or otherwise IAM role without the
			// GetUser permissions, so fail silently
			return nil
		}

		if awsErr.Code() == "SignatureDoesNotMatch" {
			return fmt.Errorf("Failed authenticating with AWS: please verify credentials")
		}
	}

	return err
}

// ValidateAccountId returns a context-specific error if the configured account
// id is explicitly forbidden or not authorised; and nil if it is authorised.
func (c *Config) ValidateAccountId(iamconn *iam.IAM) error {
	if c.AllowedAccountIds == nil && c.ForbiddenAccountIds == nil {
		return nil
	}

	log.Printf("[INFO] Validating account ID")

	out, err := iamconn.GetUser(nil)

	if err != nil {
		awsErr, _ := err.(awserr.Error)
		if awsErr.Code() == "ValidationError" {
			log.Printf("[WARN] ValidationError with iam.GetUser, assuming its an IAM profile")
			// User may be an IAM instance profile, so fail silently.
			// If it is an IAM instance profile
			// validating account might be superfluous
			return nil
		} else {
			return fmt.Errorf("Failed getting account ID from IAM: %s", err)
			// return error if the account id is explicitly not authorised
		}
	}

	account_id := strings.Split(*out.User.Arn, ":")[4]

	if c.ForbiddenAccountIds != nil {
		for _, id := range c.ForbiddenAccountIds {
			if id == account_id {
				return fmt.Errorf("Forbidden account ID (%s)", id)
			}
		}
	}

	if c.AllowedAccountIds != nil {
		for _, id := range c.AllowedAccountIds {
			if id == account_id {
				return nil
			}
		}
		return fmt.Errorf("Account ID not allowed (%s)", account_id)
	}

	return nil
}

// This function is responsible for reading credentials from the
// environment in the case that they're not explicitly specified
// in the Terraform configuration.
func getCreds(key, secret, token, profile, credsfile string) *awsCredentials.Credentials {
	// build a chain provider, lazy-evaulated by aws-sdk
	providers := []awsCredentials.Provider{
		&awsCredentials.StaticProvider{Value: awsCredentials.Value{
			AccessKeyID:     key,
			SecretAccessKey: secret,
			SessionToken:    token,
		}},
		&awsCredentials.EnvProvider{},
		&awsCredentials.SharedCredentialsProvider{
			Filename: credsfile,
			Profile:  profile,
		},
	}

	// We only look in the EC2 metadata API if we can connect
	// to the metadata service within a reasonable amount of time
	metadataURL := os.Getenv("AWS_METADATA_URL")
	if metadataURL == "" {
		metadataURL = "http://169.254.169.254:80/latest"
	}
	c := http.Client{
		Timeout: 100 * time.Millisecond,
	}

	r, err := c.Get(metadataURL)
	// Flag to determine if we should add the EC2Meta data provider. Default false
	var useIAM bool
	if err == nil {
		// AWS will add a "Server: EC2ws" header value for the metadata request. We
		// check the headers for this value to ensure something else didn't just
		// happent to be listening on that IP:Port
		if r.Header["Server"] != nil && strings.Contains(r.Header["Server"][0], "EC2") {
			useIAM = true
		}
	}

	if useIAM {
		log.Printf("[DEBUG] EC2 Metadata service found, adding EC2 Role Credential Provider")
		providers = append(providers, &ec2rolecreds.EC2RoleProvider{
			Client: ec2metadata.New(session.New(&aws.Config{
				Endpoint: aws.String(metadataURL),
			})),
		})
	} else {
		log.Printf("[DEBUG] EC2 Metadata service not found, not adding EC2 Role Credential Provider")
	}
	return awsCredentials.NewChainCredentials(providers)
}

// addTerraformVersionToUserAgent is a named handler that will add Terraform's
// version information to requests made by the AWS SDK.
var addTerraformVersionToUserAgent = request.NamedHandler{
	Name: "terraform.TerraformVersionUserAgentHandler",
	Fn: request.MakeAddToUserAgentHandler(
		"terraform", terraform.Version, terraform.VersionPrerelease),
}

type awsLogger struct{}

func (l awsLogger) Log(args ...interface{}) {
	tokens := make([]string, 0, len(args))
	for _, arg := range args {
		if token, ok := arg.(string); ok {
			tokens = append(tokens, token)
		}
	}
	log.Printf("[DEBUG] [aws-sdk-go] %s", strings.Join(tokens, " "))
}
