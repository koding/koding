package awspurge

import (
	"fmt"
	"sync"

	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/go-multierror"
)

// resourceLimit defines the number of resources that can be terminated at once
// for a given resource
const resourceLimit = 100

func (p *Purge) terminateResources(fn func(*ec2.EC2) error) error {
	var (
		wg sync.WaitGroup
		mu sync.Mutex

		multiErrors error
	)

	for r, s := range p.services.ec2 {
		wg.Add(1)

		go func(region string, svc *ec2.EC2) {
			err := fn(svc)
			if err != nil {
				mu.Lock()
				multiErrors = multierror.Append(multiErrors, err)
				mu.Unlock()
			}
			wg.Done()
		}(r, s)
	}

	wg.Wait()
	return multiErrors
}

// DescribeVolumes returns all volumes per region.
func (p *Purge) TerminateInstances() error {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.instances == nil {
			return fmt.Errorf("Instances are not fetched for region %s", region)
		}

		instanceIds := make([]*string, len(resources.instances))
		for i, instance := range resources.instances {
			instanceIds[i] = instance.InstanceId
		}

		if len(instanceIds) > resourceLimit {
			return fmt.Errorf("Too many instances(%d) found for region '%s'. Aborting", len(instanceIds), region)
		}

		input := &ec2.TerminateInstancesInput{
			InstanceIds: instanceIds,
		}

		_, err := svc.TerminateInstances(input)
		return err
	}

	return p.terminateResources(fn)
}
