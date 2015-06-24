// THIS FILE IS AUTOMATICALLY GENERATED. DO NOT EDIT.

// Package route53iface provides an interface for the Amazon Route 53.
package route53iface

import (
	"github.com/aws/aws-sdk-go/service/route53"
)

// Route53API is the interface type for route53.Route53.
type Route53API interface {
	AssociateVPCWithHostedZone(*route53.AssociateVPCWithHostedZoneInput) (*route53.AssociateVPCWithHostedZoneOutput, error)

	ChangeResourceRecordSets(*route53.ChangeResourceRecordSetsInput) (*route53.ChangeResourceRecordSetsOutput, error)

	ChangeTagsForResource(*route53.ChangeTagsForResourceInput) (*route53.ChangeTagsForResourceOutput, error)

	CreateHealthCheck(*route53.CreateHealthCheckInput) (*route53.CreateHealthCheckOutput, error)

	CreateHostedZone(*route53.CreateHostedZoneInput) (*route53.CreateHostedZoneOutput, error)

	CreateReusableDelegationSet(*route53.CreateReusableDelegationSetInput) (*route53.CreateReusableDelegationSetOutput, error)

	DeleteHealthCheck(*route53.DeleteHealthCheckInput) (*route53.DeleteHealthCheckOutput, error)

	DeleteHostedZone(*route53.DeleteHostedZoneInput) (*route53.DeleteHostedZoneOutput, error)

	DeleteReusableDelegationSet(*route53.DeleteReusableDelegationSetInput) (*route53.DeleteReusableDelegationSetOutput, error)

	DisassociateVPCFromHostedZone(*route53.DisassociateVPCFromHostedZoneInput) (*route53.DisassociateVPCFromHostedZoneOutput, error)

	GetChange(*route53.GetChangeInput) (*route53.GetChangeOutput, error)

	GetCheckerIPRanges(*route53.GetCheckerIPRangesInput) (*route53.GetCheckerIPRangesOutput, error)

	GetGeoLocation(*route53.GetGeoLocationInput) (*route53.GetGeoLocationOutput, error)

	GetHealthCheck(*route53.GetHealthCheckInput) (*route53.GetHealthCheckOutput, error)

	GetHealthCheckCount(*route53.GetHealthCheckCountInput) (*route53.GetHealthCheckCountOutput, error)

	GetHealthCheckLastFailureReason(*route53.GetHealthCheckLastFailureReasonInput) (*route53.GetHealthCheckLastFailureReasonOutput, error)

	GetHealthCheckStatus(*route53.GetHealthCheckStatusInput) (*route53.GetHealthCheckStatusOutput, error)

	GetHostedZone(*route53.GetHostedZoneInput) (*route53.GetHostedZoneOutput, error)

	GetHostedZoneCount(*route53.GetHostedZoneCountInput) (*route53.GetHostedZoneCountOutput, error)

	GetReusableDelegationSet(*route53.GetReusableDelegationSetInput) (*route53.GetReusableDelegationSetOutput, error)

	ListGeoLocations(*route53.ListGeoLocationsInput) (*route53.ListGeoLocationsOutput, error)

	ListHealthChecks(*route53.ListHealthChecksInput) (*route53.ListHealthChecksOutput, error)

	ListHostedZones(*route53.ListHostedZonesInput) (*route53.ListHostedZonesOutput, error)

	ListHostedZonesByName(*route53.ListHostedZonesByNameInput) (*route53.ListHostedZonesByNameOutput, error)

	ListResourceRecordSets(*route53.ListResourceRecordSetsInput) (*route53.ListResourceRecordSetsOutput, error)

	ListReusableDelegationSets(*route53.ListReusableDelegationSetsInput) (*route53.ListReusableDelegationSetsOutput, error)

	ListTagsForResource(*route53.ListTagsForResourceInput) (*route53.ListTagsForResourceOutput, error)

	ListTagsForResources(*route53.ListTagsForResourcesInput) (*route53.ListTagsForResourcesOutput, error)

	UpdateHealthCheck(*route53.UpdateHealthCheckInput) (*route53.UpdateHealthCheckOutput, error)

	UpdateHostedZoneComment(*route53.UpdateHostedZoneCommentInput) (*route53.UpdateHostedZoneCommentOutput, error)
}
