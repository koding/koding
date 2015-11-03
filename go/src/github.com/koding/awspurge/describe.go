package awspurge

import (
	"sync"

	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/go-multierror"
)

func (p *Purge) describeResources(fn func(*ec2.EC2) (interface{}, error)) (map[string]interface{}, error) {
	var (
		wg sync.WaitGroup
		mu sync.Mutex

		multiErrors error
	)

	output := make(map[string]interface{})

	for r, s := range p.services.regions {
		wg.Add(1)

		go func(region string, svc *ec2.EC2) {
			out, err := fn(svc)
			if err != nil {
				mu.Lock()
				multiErrors = multierror.Append(multiErrors, err)
				mu.Unlock()
				wg.Done()
				return
			}

			mu.Lock()
			output[region] = out
			mu.Unlock()

			wg.Done()
		}(r, s)
	}

	wg.Wait()

	return output, multiErrors
}

// DescribeVolumes returns all volumes per region.
func (p *Purge) DescribeVolumes() (map[string][]*ec2.Volume, error) {
	describeVolumes := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeVolumes(nil)
		if err != nil {
			return nil, err
		}

		return resp.Volumes, nil
	}

	out, err := p.describeResources(describeVolumes)
	if err != nil {
		return nil, err
	}

	volumes := make(map[string][]*ec2.Volume)
	for region, v := range out {
		vols, ok := v.([]*ec2.Volume)
		if !ok {
			continue
		}
		volumes[region] = vols
	}

	return volumes, nil
}

// DescribeInstances returns all instances per region.
func (p *Purge) DescribeInstances() (map[string][]*ec2.Instance, error) {
	describeInstances := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeInstances(nil)
		if err != nil {
			return nil, err
		}

		instances := make([]*ec2.Instance, 0)
		if resp.Reservations != nil {
			for _, reserv := range resp.Reservations {
				if len(reserv.Instances) != 0 {
					instances = append(instances, reserv.Instances...)
				}
			}
		}

		return instances, nil
	}

	out, err := p.describeResources(describeInstances)
	if err != nil {
		return nil, err
	}

	instances := make(map[string][]*ec2.Instance)
	for region, i := range out {
		ins, ok := i.([]*ec2.Instance)
		if !ok {
			continue
		}
		instances[region] = ins
	}

	return instances, nil
}

// DescribePairs returns all key pairs per region
func (p *Purge) DescribeKeyPairs() (map[string][]*ec2.KeyPairInfo, error) {
	describeKeyPairs := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeKeyPairs(nil)
		if err != nil {
			return nil, err
		}

		return resp.KeyPairs, nil
	}

	out, err := p.describeResources(describeKeyPairs)
	if err != nil {
		return nil, err
	}

	keyPairs := make(map[string][]*ec2.KeyPairInfo)
	for region, k := range out {
		keys, ok := k.([]*ec2.KeyPairInfo)
		if !ok {
			continue
		}
		keyPairs[region] = keys
	}

	return keyPairs, nil
}
