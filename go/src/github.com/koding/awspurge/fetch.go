package awspurge

import "github.com/hashicorp/go-multierror"

func (p *Purge) FetchInstances() {
	p.wg.Add(1)
	go func() {
		allInstances, err := p.DescribeInstances()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}
		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].instances = allInstances[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchVolumes() {
	p.wg.Add(1)
	go func() {
		allVolumes, err := p.DescribeVolumes()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}
		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].volumes = allVolumes[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchKeyPairs() {
	p.wg.Add(1)
	go func() {
		allKeyPairs, err := p.DescribeKeyPairs()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].keyPairs = allKeyPairs[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchPlacementGroups() {
	p.wg.Add(1)
	go func() {
		allPlacementGroups, err := p.DescribePlacementGroups()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].placementGroups = allPlacementGroups[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchAddresses() {
	p.wg.Add(1)
	go func() {
		allAddresses, err := p.DescribeAddresses()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].addresses = allAddresses[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchSnapshots() {
	p.wg.Add(1)
	go func() {
		allSnaphots, err := p.DescribeSnapshots()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].snapshots = allSnaphots[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchLoadBalancers() {
	p.wg.Add(1)
	go func() {
		allLoadBalancers, err := p.DescribeLoadBalancers()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].loadBalancers = allLoadBalancers[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchSecurityGroups() {
	p.wg.Add(1)
	go func() {
		allSecurityGroups, err := p.DescribeSecurityGroups()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].securityGroups = allSecurityGroups[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchVpcs() {
	p.wg.Add(1)
	go func() {
		resources, err := p.DescribeVpcs()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].vpcs = resources[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchSubnets() {
	p.wg.Add(1)
	go func() {
		resources, err := p.DescribeSubnets()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].subnets = resources[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchNetworkAcls() {
	p.wg.Add(1)
	go func() {
		resources, err := p.DescribeNetworkAcls()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].networkAcls = resources[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchInternetGateways() {
	p.wg.Add(1)
	go func() {
		resources, err := p.DescribeInternetGateways()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].internetGateways = resources[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}

func (p *Purge) FetchRouteTables() {
	p.wg.Add(1)
	go func() {
		resources, err := p.DescribeRouteTables()
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
			return
		}

		for _, region := range p.regions {
			p.resourceMu.Lock()
			p.resources[region].routeTables = resources[region]
			p.resourceMu.Unlock()
		}
		p.wg.Done()
	}()
}
