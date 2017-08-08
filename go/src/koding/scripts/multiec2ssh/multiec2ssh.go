// this is just a helper package that i (cs) write for multiple ssh access to
// servers
package main

import (
	"flag"
	"fmt"
	"log"
	"os/exec"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/elb"
)

var (
	// ELB & EC2 -> AmazonEC2ReadOnlyAccess
	flagAWSSecret = flag.String("awsSecret", "", "aws secret key")
	flagAWSAccess = flag.String("awsAccess", "", "aws access key")

	flagHost       = flag.String("env", "prod", "env name")
	flagFiltered   = flag.Bool("filtered", false, "filter by ec2 tags")
	flagFolderPath = flag.String("flagFolderPath", "/Users/siesta/Documents/koding/credential", "credential repo folder path")
)

var elbs = map[string]string{
	// app
	"prod":       "awseb-e-x-AWSEBLoa-2AG3XORA8JXC",
	"latest":     "awseb-e-3-AWSEBLoa-1S2VPBAQXDRW9",
	"sandbox":    "awseb-e-p-AWSEBLoa-1POHSLP6A7STY",
	"monitoring": "awseb-e-m-AWSEBLoa-1WDL87HGH01FI",
	// proxy
	"proxy-eu-west-1":      "awseb-e-s-AWSEBLoa-1LOTB5BKTJJBW",
	"proxy-us-east-1":      "awseb-e-a-AWSEBLoa-RTLJ62SKJY5G",
	"proxy-us-west-2":      "awseb-e-7-AWSEBLoa-1V808KG9PDQH5",
	"proxy-ap-southeast-1": "awseb-e-u-AWSEBLoa-15H1DQTBBUMG",
	"proxy-dev-us-e-1-v2":  "awseb-e-b-AWSEBLoa-1VBJV8WOETX0X",

	// countly
	"countlydev": "awseb-e-w-AWSEBLoa-4M5ML08503P6",
	"countly":    "awseb-e-k-AWSEBLoa-XNAR4M9CZ9R8",
}

var tags = map[string]string{
	// app
	"prod":    "prod.koding.com",
	"latest":  "latest.koding.com",
	"sandbox": "sandbox.koding.com",
}

var elb2region = map[string]string{
	// proxies
	"awseb-e-s-AWSEBLoa-1LOTB5BKTJJBW": "eu-west-1",
	"awseb-e-a-AWSEBLoa-RTLJ62SKJY5G":  "us-east-1",
	"awseb-e-7-AWSEBLoa-1V808KG9PDQH5": "us-west-2",
	"awseb-e-u-AWSEBLoa-15H1DQTBBUMG":  "ap-southeast-1",

	// app elbs
	"awseb-e-m-AWSEBLoa-1WDL87HGH01FI": "us-east-1",
	"awseb-e-x-AWSEBLoa-2AG3XORA8JXC":  "us-east-1",
	"awseb-e-3-AWSEBLoa-1S2VPBAQXDRW9": "us-east-1",
	"awseb-e-p-AWSEBLoa-1POHSLP6A7STY": "us-east-1",
	"awseb-e-b-AWSEBLoa-1VBJV8WOETX0X": "us-east-1",

	// countly
	"awseb-e-w-AWSEBLoa-4M5ML08503P6": "us-east-1",
	"awseb-e-k-AWSEBLoa-XNAR4M9CZ9R8": "us-east-1",
}

func getEC2(elbName string) *ec2.EC2 {
	reg, ok := elb2region[elbName]
	if !ok {
		panic(elbName)
	}

	ses := session.New(&aws.Config{
		Credentials: credentials.NewStaticCredentials(
			*flagAWSAccess,
			*flagAWSSecret,
			"",
		),
		Region:     aws.String(reg),
		MaxRetries: aws.Int(5),
	})

	return ec2.New(ses)
}

func getELB(elbName string) *elb.ELB {
	reg, ok := elb2region[elbName]
	if !ok {
		panic(elbName)
	}

	ses := session.New(&aws.Config{
		Credentials: credentials.NewStaticCredentials(
			*flagAWSAccess,
			*flagAWSSecret,
			"",
		),
		Region:     aws.String(reg),
		MaxRetries: aws.Int(5),
	})

	return elb.New(ses)
}

func main() {

	flag.Parse()

	currentELBInstances := make([]string, 0)

	elbNames, ok := elbs[*flagHost]
	if !ok {
		log.Fatalf("%s not found", *flagHost)
	}

	if *flagFiltered {
		tagName := tags[*flagHost]
		var err error
		currentELBInstances, err = GetchInstancesByTag(elbNames, tagName)
		if err != nil {
			log.Fatal(err.Error())
		}
	} else {
		for _, elbName := range strings.Split(elbNames, ",") {
			currentInstances, err := fetchProdELBAttachedInstances(elbName)
			if err != nil {
				log.Fatal(err.Error())
			}
			currentELBInstances = append(currentELBInstances, currentInstances...)
		}
	}

	f := createI2csshString(*flagHost, currentELBInstances)
	_, err := exec.Command("i2cssh", strings.Fields(f)...).Output()
	if err != nil {
		log.Fatal(err.Error())
	}
}

var paramToKey = map[string]string{
	"prod":       "/private_keys/koding-eb-deployment-us-east-1-2015-06.pem",
	"latest":     "/private_keys/koding-eb-deployment-us-east-1-2015-06.pem",
	"sandbox":    "/private_keys/koding-eb-deployment-us-east-1-2015-06.pem",
	"monitoring": "/private_keys/koding-eb-deployment-us-east-1-2015-06.pem",

	"proxy-eu-west-1":      "/private_keys/koding-eb-deployment-eu-west-1-2015-06.pem",
	"proxy-us-east-1":      "/private_keys/koding-eb-deployment-us-east-1-2015-06.pem",
	"proxy-us-west-2":      "/private_keys/koding-eb-deployment-us-west-2-2015-06.pem",
	"proxy-ap-southeast-1": "/private_keys/koding-eb-deployment-ap-southeast-1-2015-06.pem",
	"proxy-dev-us-e-1-v2":  "/private_keys/koding-eb-deployment-dev-2016-10.pem",

	"countlydev": "/private_keys/koding-eb-deployment-us-east-1-2015-06.pem",
	"countly":    "/private_keys/koding-eb-deployment-us-east-1-2015-06.pem",
}

func createI2csshString(param string, instances []string) string {
	return fmt.Sprintf(
		"--forward-agent --login ec2-user --rows 3 --broadcast -Xi=%s  --machines %s",
		*flagFolderPath+paramToKey[param],
		strings.Join(instances, ","),
	)
}

// fetch currently attached instances to the prod ELB
func fetchProdELBAttachedInstances(elbName string) ([]string, error) {
	params := &elb.DescribeLoadBalancersInput{
		LoadBalancerNames: []*string{
			aws.String(elbName),
		},
	}
	res, err := getELB(elbName).DescribeLoadBalancers(params)
	if err != nil {
		return nil, err
	}

	if len(res.LoadBalancerDescriptions) < 1 {
		return nil, fmt.Errorf("%s ELB not found!", elbName)
	}

	attachedInstances := make([]*string, 0)
	for _, inst := range res.LoadBalancerDescriptions[0].Instances {
		attachedInstances = append(attachedInstances, inst.InstanceId)
	}

	resp, err := getEC2(elbName).DescribeInstances(
		&ec2.DescribeInstancesInput{
			InstanceIds: attachedInstances,
		},
	)
	if err != nil {
		return nil, err
	}

	instanceIps := make([]string, 0)
	for _, reservations := range resp.Reservations {
		for _, instance := range reservations.Instances {
			if *instance.PublicIpAddress != "" {
				instanceIps = append(instanceIps, *instance.PublicIpAddress)
			}
		}
	}

	return instanceIps, nil
}

func GetchInstancesByTag(elbName string, environmentTag string) ([]string, error) {
	params := &ec2.DescribeInstancesInput{
		Filters: []*ec2.Filter{
			{
				Name: aws.String("tag-key"),
				Values: []*string{
					aws.String("environment"),
				},
			},
			{
				Name: aws.String("tag-value"),
				Values: []*string{
					aws.String(environmentTag),
				},
			},
		},
	}
	resp, err := getEC2(elbName).DescribeInstances(params)
	if err != nil {
		return nil, err
	}

	instances := make([]string, 0)
	for _, reservations := range resp.Reservations {
		for _, instance := range reservations.Instances {
			if *instance.PublicIpAddress != "" {
				instances = append(instances, *instance.PublicIpAddress)
			}
		}
	}

	return instances, nil
}
