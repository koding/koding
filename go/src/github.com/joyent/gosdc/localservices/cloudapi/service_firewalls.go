package cloudapi

import (
	"fmt"
	"strings"

	"github.com/joyent/gosdc/cloudapi"
	"github.com/joyent/gosdc/localservices"
)

// FirewallRule APIs

// ListFirewallRules gets a list of firewall rules from the double
func (c *CloudAPI) ListFirewallRules() ([]*cloudapi.FirewallRule, error) {
	if err := c.ProcessFunctionHook(c); err != nil {
		return nil, err
	}

	return c.firewallRules, nil
}

// GetFirewallRule gets a single firewall rule by ID
func (c *CloudAPI) GetFirewallRule(fwRuleID string) (*cloudapi.FirewallRule, error) {
	if err := c.ProcessFunctionHook(c, fwRuleID); err != nil {
		return nil, err
	}

	for _, r := range c.firewallRules {
		if strings.EqualFold(r.Id, fwRuleID) {
			return r, nil
		}
	}

	return nil, fmt.Errorf("Firewall rule %s not found", fwRuleID)
}

// CreateFirewallRule creates a new firewall rule and returns it
func (c *CloudAPI) CreateFirewallRule(rule string, enabled bool) (*cloudapi.FirewallRule, error) {
	if err := c.ProcessFunctionHook(c, rule, enabled); err != nil {
		return nil, err
	}

	fwRuleID, err := localservices.NewUUID()
	if err != nil {
		return nil, fmt.Errorf("Error creating firewall rule: %q", err)
	}

	fwRule := &cloudapi.FirewallRule{Id: fwRuleID, Rule: rule, Enabled: enabled}
	c.firewallRules = append(c.firewallRules, fwRule)

	return fwRule, nil
}

// UpdateFirewallRule makes changes to a given firewall rule
func (c *CloudAPI) UpdateFirewallRule(fwRuleID, rule string, enabled bool) (*cloudapi.FirewallRule, error) {
	if err := c.ProcessFunctionHook(c, fwRuleID, rule, enabled); err != nil {
		return nil, err
	}

	for _, r := range c.firewallRules {
		if strings.EqualFold(r.Id, fwRuleID) {
			r.Rule = rule
			r.Enabled = enabled
			return r, nil
		}
	}

	return nil, fmt.Errorf("Firewall rule %s not found", fwRuleID)
}

// EnableFirewallRule enables the given firewall rule
func (c *CloudAPI) EnableFirewallRule(fwRuleID string) (*cloudapi.FirewallRule, error) {
	if err := c.ProcessFunctionHook(c, fwRuleID); err != nil {
		return nil, err
	}

	for _, r := range c.firewallRules {
		if strings.EqualFold(r.Id, fwRuleID) {
			r.Enabled = true
			return r, nil
		}
	}

	return nil, fmt.Errorf("Firewall rule %s not found", fwRuleID)
}

// DisableFirewallRule disables the given firewall rule
func (c *CloudAPI) DisableFirewallRule(fwRuleID string) (*cloudapi.FirewallRule, error) {
	if err := c.ProcessFunctionHook(c, fwRuleID); err != nil {
		return nil, err
	}

	for _, r := range c.firewallRules {
		if strings.EqualFold(r.Id, fwRuleID) {
			r.Enabled = false
			return r, nil
		}
	}

	return nil, fmt.Errorf("Firewall rule %s not found", fwRuleID)
}

// DeleteFirewallRule deletes the given firewall rule
func (c *CloudAPI) DeleteFirewallRule(fwRuleID string) error {
	if err := c.ProcessFunctionHook(c, fwRuleID); err != nil {
		return err
	}

	for i, r := range c.firewallRules {
		if strings.EqualFold(r.Id, fwRuleID) {
			c.firewallRules = append(c.firewallRules[:i], c.firewallRules[i+1:]...)
			return nil
		}
	}

	return fmt.Errorf("Firewall rule %s not found", fwRuleID)
}

// ListFirewallRuleMachines should list the machines that are affected by a
// given firewall rule. In this double, it just returns all the machines.
func (c *CloudAPI) ListFirewallRuleMachines(fwRuleID string) ([]*cloudapi.Machine, error) {
	if err := c.ProcessFunctionHook(c, fwRuleID); err != nil {
		return nil, err
	}

	out := make([]*cloudapi.Machine, len(c.machines))
	for i, machine := range c.machines {
		out[i] = &machine.Machine
	}

	return out, nil
}
