// This script makes it easier to manage workers on different instances.
// Supervisor comes with a web ui, however it's only for a single instance,
// so we create a new html page that contains the iframe of all the
// instances in that environment.
package main

import (
	"fmt"
	"io/ioutil"
	"koding/tools/config"
	"log"
	"os"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
	"github.com/mitchellh/goamz/elb"
)

// elasticbeanstalk load balancer names
var environments = map[string]string{
	"production": "awseb-e-x-AWSEBLoa-2AG3XORA8JXC",
	"latest":     "awseb-e-3-AWSEBLoa-1S2VPBAQXDRW9",
	"sandbox":    "awseb-e-2-AWSEBLoa-Z9CEV6ZDEFMC",
}

var region = aws.USEast

func main() {
	if len(os.Args) < 2 {
		log.Fatal("No environment. Please pass: production, latest, sandbox")
	}

	env := os.Args[1]
	loadBalancerName, ok := environments[env]
	if !ok {
		log.Fatal("Unknown environment. Please pick: production, latest, sandbox")
	}

	conf := config.MustConfig("dev")
	auth, err := aws.GetAuth(conf.Aws.Key, conf.Aws.Secret)
	if err != nil {
		log.Fatal(err)
	}

	// get list of instances in a load balancer
	elbClient := elb.New(auth, region)
	options := &elb.DescribeLoadBalancer{
		Names: []string{loadBalancerName},
	}

	elbResp, err := elbClient.DescribeLoadBalancers(options)
	if err != nil {
		log.Fatal(err)
	}

	elbInstances := elbResp.LoadBalancers[0].Instances
	instances := []string{}

	for _, instance := range elbInstances {
		instances = append(instances, instance.InstanceId)
	}

	// get the ipaddress of the instances
	ec2Client := ec2.New(auth, region)
	resp, err := ec2Client.Instances(instances, nil)
	if err != nil {
		log.Fatal(err)
	}

	ips := []string{}

	for _, reservation := range resp.Reservations {
		for _, instance := range reservation.Instances {
			ips = append(ips, instance.PublicIpAddress)
		}
	}

	// generate html
	var output string = fmt.Sprintf("Environment: %s", env)

	for _, ip := range ips {
		output += fmt.Sprintf(template, ip)
	}

	bites := []byte(output)
	err = ioutil.WriteFile("supervisor.html", bites, 0644)
	if err != nil {
		log.Fatal(err)
	}
}

var template = `
<div>
	%[1]s<br>
	<iframe src="http://koding:1q2w3e4r@%[1]s:9001" width=800px height=1100px;">
	</iframe>
</div>
`
