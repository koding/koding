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

var environments = map[string]string{
	"production": "awseb-e-x-AWSEBLoa-2AG3XORA8JXC",
	"latest":     "awseb-e-3-AWSEBLoa-1S2VPBAQXDRW9",
	"sandbox":    "awseb-e-2-AWSEBLoa-Z9CEV6ZDEFMC",
}

func main() {
	if len(os.Args) < 2 {
		log.Fatal("Please pass an environment")
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

	elbClient := elb.New(auth, aws.USEast)
	options := &elb.DescribeLoadBalancer{
		Names: []string{loadBalancerName},
	}

	ec2Client := ec2.New(auth, aws.USEast)

	elbResp, err := elbClient.DescribeLoadBalancers(options)
	if err != nil {
		log.Fatal(err)
	}

	elbInstances := elbResp.LoadBalancers[0].Instances
	instances := []string{}

	for _, instance := range elbInstances {
		instances = append(instances, instance.InstanceId)
	}

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

	var output string

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
