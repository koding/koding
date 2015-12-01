package amazon

import (
	"net/url"
	"sort"
	"strings"

	"koding/kites/kloud/machinestate"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
)

// PermAllPorts is a conveniance value for opening all ports for inbound
// requests.
//
// For use with AuthorizeSecurityGroup method.
var PermAllPorts = []*ec2.IpPermission{{
	IpProtocol: aws.String("tcp"),
	FromPort:   aws.Int64(0),
	ToPort:     aws.Int64(65535),
	IpRanges: []*ec2.IpRange{{
		CidrIp: aws.String("0.0.0.0/0"),
	}},
}}

// NewSession gives new AWS configuration.
//
// Each new session uses custom, resilient transport described by TransportConfig.
func NewSession(opts *ClientOptions) *session.Session {
	cfg := &aws.Config{
		Credentials: opts.Credentials,
	}
	if opts.Region != "" {
		cfg.Region = aws.String(opts.Region)
	}
	if opts.Log != nil {
		cfg.Logger = NewLogger(opts.Log.Debug)
	}
	return session.New(cfg, TransportConfig)
}

// TagsMatch returns true when tags contains all tags described by the m map.
func TagsMatch(tags []*ec2.Tag, m map[string]string) bool {
	matches := make(map[string]struct{})
	for _, tag := range tags {
		key := aws.StringValue(tag.Key)
		if v, ok := m[key]; ok && aws.StringValue(tag.Value) == v {
			matches[key] = struct{}{}
		}
	}
	return len(matches) == len(m)
}

// StatusToState converts a amazon status to a sensible machinestate.State
// enum.
func StatusToState(status string) machinestate.State {
	// For available state enums see:
	//
	//   https://godoc.org/github.com/aws/aws-sdk-go/service/ec2#InstanceState
	//
	switch strings.ToLower(status) {
	case ec2.InstanceStateNamePending:
		return machinestate.Starting // intentional
	case ec2.InstanceStateNameRunning:
		return machinestate.Running
	case ec2.InstanceStateNameStopped:
		return machinestate.Stopped
	case ec2.InstanceStateNameStopping:
		return machinestate.Stopping
	case ec2.InstanceStateNameShuttingDown:
		return machinestate.Terminating
	case ec2.InstanceStateNameTerminated:
		return machinestate.Terminated
	default:
		return machinestate.Unknown
	}
}

// NewTags is a conveniance function for building AWS tag slice from the m map.
//
// If the m is empty, the function returns nil.
func NewTags(tags map[string]string) []*ec2.Tag {
	if len(tags) == 0 {
		return nil
	}
	t := make([]*ec2.Tag, 0, len(tags))
	for k, v := range tags {
		tag := &ec2.Tag{
			Key:   aws.String(k),
			Value: aws.String(v),
		}
		t = append(t, tag)
	}
	return t
}

// NewFilters is a conveniance function for building AWS fitler slice from the
// given values.
//
// The resulting filters slice has all elements sorted by key name.
//
// Each empty value in the filters will be ignored. If all the values for
// a given key are empty, the filter will be ignored.
//
// If the filters are empty or all the values were ignored due to above behaviour,
// thus making the filters effectively empty, the function returns nil.
func NewFilters(filters url.Values) []*ec2.Filter {
	f := make([]*ec2.Filter, 0, len(filters))
	for k, v := range filters {
		filter := &ec2.Filter{
			Name:   aws.String(k),
			Values: make([]*string, 0, len(v)),
		}
		for _, v := range v {
			// If value is empty, ignore it.
			if v == "" {
				continue
			}
			filter.Values = append(filter.Values, aws.String(v))
		}
		// If filter has no values, ignore it.
		if len(filter.Values) != 0 {
			f = append(f, filter)
		}
	}
	// If no filters are specified or all of them were ignored, return nil.
	if len(f) == 0 {
		return nil
	}
	// Sort the filters to make the order deterministic.
	sort.Sort(filtersByName(f))
	return f
}

type filtersByName []*ec2.Filter

func (f filtersByName) Len() int {
	return len(f)
}

func (f filtersByName) Less(i, j int) bool {
	return aws.StringValue(f[i].Name) <= aws.StringValue(f[j].Name)
}

func (f filtersByName) Swap(i, j int) {
	f[i], f[j] = f[j], f[i]
}
