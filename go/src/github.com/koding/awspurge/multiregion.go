package awspurge

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/elb"
)

var allRegions = []string{
	"ap-northeast-1",
	"ap-southeast-1",
	"ap-southeast-2",
	"eu-central-1",
	"eu-west-1",
	"sa-east-1",
	"us-east-1",
	"us-west-1",
	"us-west-2",
	// These are problematic for the first time, thus enable later. The user
	// can always define manually and set explicitly if wished.
	// "cn-north-1",
	// "us-gov-west-1",
}

type multiRegion struct {
	ec2 map[string]*ec2.EC2
	elb map[string]*elb.ELB
}

func newMultiRegion(conf *aws.Config, regions []string) *multiRegion {
	m := &multiRegion{
		ec2: make(map[string]*ec2.EC2, 0),
		elb: make(map[string]*elb.ELB, 0),
	}

	for _, region := range regions {
		conf.MergeIn(&aws.Config{Region: aws.String(region)})

		m.ec2[region] = ec2.New(session.New(), conf)
		m.elb[region] = elb.New(session.New(), conf)
	}

	return m
}

func filterRegions(regions, excludedRegions []string) []string {
	if len(regions) == 1 && regions[0] == "all" {
		regions = allRegions
	}

	inExcluded := func(r string) bool {
		for _, region := range excludedRegions {
			if r == region {
				return true
			}
		}
		return false
	}

	finalRegions := make([]string, 0)
	for _, r := range regions {
		if !inExcluded(r) {
			finalRegions = append(finalRegions, r)
		}
	}

	return finalRegions
}
