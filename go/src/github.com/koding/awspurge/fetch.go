package awspurge

import "github.com/hashicorp/go-multierror"

// FetchInstances fetches all instances and stores them into internally
func (p *Purge) FetchInstances() (err error) {
	defer func() {
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
		}
		p.wg.Done()
	}()

	allInstances, err := p.DescribeInstances()
	if err != nil {
		return err
	}
	for _, region := range allRegions {
		p.resourceMu.Lock()
		p.resources[region].instances = allInstances[region]
		p.resourceMu.Unlock()
	}
	return nil
}

// FetchVolumes fetches all volumes and stores them into internally
func (p *Purge) FetchVolumes() (err error) {
	defer func() {
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
		}
		p.wg.Done()
	}()
	allVolumes, err := p.DescribeVolumes()
	if err != nil {
		return err
	}
	for _, region := range allRegions {
		p.resourceMu.Lock()
		p.resources[region].volumes = allVolumes[region]
		p.resourceMu.Unlock()
	}
	return nil
}

// FetchKeyParis fetches all key pairs and stores them into internally
func (p *Purge) FetchKeyPairs() (err error) {
	defer func() {
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
		}
		p.wg.Done()
	}()

	allKeyPairs, err := p.DescribeKeyPairs()
	if err != nil {
		return err
	}

	for _, region := range allRegions {
		p.resourceMu.Lock()
		p.resources[region].keyPairs = allKeyPairs[region]
		p.resourceMu.Unlock()
	}
	return nil
}

// FetchPlacementGroups fetches all placement groups and stores them into
// internally
func (p *Purge) FetchPlacementGroups() (err error) {
	defer func() {
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
		}
		p.wg.Done()
	}()

	allPlacementGroups, err := p.DescribePlacementGroups()
	if err != nil {
		return err
	}

	for _, region := range allRegions {
		p.resourceMu.Lock()
		p.resources[region].placementGroups = allPlacementGroups[region]
		p.resourceMu.Unlock()
	}
	return nil
}

// FetchAddresses fetches all addresses and stores them into internally
func (p *Purge) FetchAddresses() (err error) {
	defer func() {
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
		}
		p.wg.Done()
	}()

	allAddresses, err := p.DescribeAddresses()
	if err != nil {
		return err
	}

	for _, region := range allRegions {
		p.resourceMu.Lock()
		p.resources[region].addresses = allAddresses[region]
		p.resourceMu.Unlock()
	}
	return nil
}

// FetchSnapshots fetches all snapshots and stores them into internally
func (p *Purge) FetchSnapshots() (err error) {
	defer func() {
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
		}
		p.wg.Done()
	}()

	allSnaphots, err := p.DescribeSnapshots()
	if err != nil {
		return err
	}

	for _, region := range allRegions {
		p.resourceMu.Lock()
		p.resources[region].snapshots = allSnaphots[region]
		p.resourceMu.Unlock()
	}
	return nil
}

// FetchLoadBalancers fetches all load balancers and stores them into
// internally
func (p *Purge) FetchLoadBalancers() (err error) {
	defer func() {
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
		}
		p.wg.Done()
	}()

	allLoadBalancers, err := p.DescribeLoadBalancers()
	if err != nil {
		return err
	}

	for _, region := range allRegions {
		p.resourceMu.Lock()
		p.resources[region].loadBalancers = allLoadBalancers[region]
		p.resourceMu.Unlock()
	}
	return nil
}

// FetchSecurityGroups fetches all security groups and stores them into
// internally
func (p *Purge) FetchSecurityGroups() (err error) {
	defer func() {
		if err != nil {
			p.mu.Lock()
			p.errs = multierror.Append(p.errs, err)
			p.mu.Unlock()
		}
		p.wg.Done()
	}()

	allSecurityGroups, err := p.DescribeSecurityGroups()
	if err != nil {
		return err
	}

	for _, region := range allRegions {
		p.resourceMu.Lock()
		p.resources[region].securityGroups = allSecurityGroups[region]
		p.resourceMu.Unlock()
	}
	return nil
}
