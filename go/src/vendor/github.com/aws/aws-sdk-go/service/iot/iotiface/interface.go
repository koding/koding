// THIS FILE IS AUTOMATICALLY GENERATED. DO NOT EDIT.

// Package iotiface provides an interface for the AWS IoT.
package iotiface

import (
	"github.com/aws/aws-sdk-go/aws/request"
	"github.com/aws/aws-sdk-go/service/iot"
)

// IoTAPI is the interface type for iot.IoT.
type IoTAPI interface {
	AcceptCertificateTransferRequest(*iot.AcceptCertificateTransferInput) (*request.Request, *iot.AcceptCertificateTransferOutput)

	AcceptCertificateTransfer(*iot.AcceptCertificateTransferInput) (*iot.AcceptCertificateTransferOutput, error)

	AttachPrincipalPolicyRequest(*iot.AttachPrincipalPolicyInput) (*request.Request, *iot.AttachPrincipalPolicyOutput)

	AttachPrincipalPolicy(*iot.AttachPrincipalPolicyInput) (*iot.AttachPrincipalPolicyOutput, error)

	AttachThingPrincipalRequest(*iot.AttachThingPrincipalInput) (*request.Request, *iot.AttachThingPrincipalOutput)

	AttachThingPrincipal(*iot.AttachThingPrincipalInput) (*iot.AttachThingPrincipalOutput, error)

	CancelCertificateTransferRequest(*iot.CancelCertificateTransferInput) (*request.Request, *iot.CancelCertificateTransferOutput)

	CancelCertificateTransfer(*iot.CancelCertificateTransferInput) (*iot.CancelCertificateTransferOutput, error)

	CreateCertificateFromCsrRequest(*iot.CreateCertificateFromCsrInput) (*request.Request, *iot.CreateCertificateFromCsrOutput)

	CreateCertificateFromCsr(*iot.CreateCertificateFromCsrInput) (*iot.CreateCertificateFromCsrOutput, error)

	CreateKeysAndCertificateRequest(*iot.CreateKeysAndCertificateInput) (*request.Request, *iot.CreateKeysAndCertificateOutput)

	CreateKeysAndCertificate(*iot.CreateKeysAndCertificateInput) (*iot.CreateKeysAndCertificateOutput, error)

	CreatePolicyRequest(*iot.CreatePolicyInput) (*request.Request, *iot.CreatePolicyOutput)

	CreatePolicy(*iot.CreatePolicyInput) (*iot.CreatePolicyOutput, error)

	CreatePolicyVersionRequest(*iot.CreatePolicyVersionInput) (*request.Request, *iot.CreatePolicyVersionOutput)

	CreatePolicyVersion(*iot.CreatePolicyVersionInput) (*iot.CreatePolicyVersionOutput, error)

	CreateThingRequest(*iot.CreateThingInput) (*request.Request, *iot.CreateThingOutput)

	CreateThing(*iot.CreateThingInput) (*iot.CreateThingOutput, error)

	CreateTopicRuleRequest(*iot.CreateTopicRuleInput) (*request.Request, *iot.CreateTopicRuleOutput)

	CreateTopicRule(*iot.CreateTopicRuleInput) (*iot.CreateTopicRuleOutput, error)

	DeleteCACertificateRequest(*iot.DeleteCACertificateInput) (*request.Request, *iot.DeleteCACertificateOutput)

	DeleteCACertificate(*iot.DeleteCACertificateInput) (*iot.DeleteCACertificateOutput, error)

	DeleteCertificateRequest(*iot.DeleteCertificateInput) (*request.Request, *iot.DeleteCertificateOutput)

	DeleteCertificate(*iot.DeleteCertificateInput) (*iot.DeleteCertificateOutput, error)

	DeletePolicyRequest(*iot.DeletePolicyInput) (*request.Request, *iot.DeletePolicyOutput)

	DeletePolicy(*iot.DeletePolicyInput) (*iot.DeletePolicyOutput, error)

	DeletePolicyVersionRequest(*iot.DeletePolicyVersionInput) (*request.Request, *iot.DeletePolicyVersionOutput)

	DeletePolicyVersion(*iot.DeletePolicyVersionInput) (*iot.DeletePolicyVersionOutput, error)

	DeleteRegistrationCodeRequest(*iot.DeleteRegistrationCodeInput) (*request.Request, *iot.DeleteRegistrationCodeOutput)

	DeleteRegistrationCode(*iot.DeleteRegistrationCodeInput) (*iot.DeleteRegistrationCodeOutput, error)

	DeleteThingRequest(*iot.DeleteThingInput) (*request.Request, *iot.DeleteThingOutput)

	DeleteThing(*iot.DeleteThingInput) (*iot.DeleteThingOutput, error)

	DeleteTopicRuleRequest(*iot.DeleteTopicRuleInput) (*request.Request, *iot.DeleteTopicRuleOutput)

	DeleteTopicRule(*iot.DeleteTopicRuleInput) (*iot.DeleteTopicRuleOutput, error)

	DescribeCACertificateRequest(*iot.DescribeCACertificateInput) (*request.Request, *iot.DescribeCACertificateOutput)

	DescribeCACertificate(*iot.DescribeCACertificateInput) (*iot.DescribeCACertificateOutput, error)

	DescribeCertificateRequest(*iot.DescribeCertificateInput) (*request.Request, *iot.DescribeCertificateOutput)

	DescribeCertificate(*iot.DescribeCertificateInput) (*iot.DescribeCertificateOutput, error)

	DescribeEndpointRequest(*iot.DescribeEndpointInput) (*request.Request, *iot.DescribeEndpointOutput)

	DescribeEndpoint(*iot.DescribeEndpointInput) (*iot.DescribeEndpointOutput, error)

	DescribeThingRequest(*iot.DescribeThingInput) (*request.Request, *iot.DescribeThingOutput)

	DescribeThing(*iot.DescribeThingInput) (*iot.DescribeThingOutput, error)

	DetachPrincipalPolicyRequest(*iot.DetachPrincipalPolicyInput) (*request.Request, *iot.DetachPrincipalPolicyOutput)

	DetachPrincipalPolicy(*iot.DetachPrincipalPolicyInput) (*iot.DetachPrincipalPolicyOutput, error)

	DetachThingPrincipalRequest(*iot.DetachThingPrincipalInput) (*request.Request, *iot.DetachThingPrincipalOutput)

	DetachThingPrincipal(*iot.DetachThingPrincipalInput) (*iot.DetachThingPrincipalOutput, error)

	DisableTopicRuleRequest(*iot.DisableTopicRuleInput) (*request.Request, *iot.DisableTopicRuleOutput)

	DisableTopicRule(*iot.DisableTopicRuleInput) (*iot.DisableTopicRuleOutput, error)

	EnableTopicRuleRequest(*iot.EnableTopicRuleInput) (*request.Request, *iot.EnableTopicRuleOutput)

	EnableTopicRule(*iot.EnableTopicRuleInput) (*iot.EnableTopicRuleOutput, error)

	GetLoggingOptionsRequest(*iot.GetLoggingOptionsInput) (*request.Request, *iot.GetLoggingOptionsOutput)

	GetLoggingOptions(*iot.GetLoggingOptionsInput) (*iot.GetLoggingOptionsOutput, error)

	GetPolicyRequest(*iot.GetPolicyInput) (*request.Request, *iot.GetPolicyOutput)

	GetPolicy(*iot.GetPolicyInput) (*iot.GetPolicyOutput, error)

	GetPolicyVersionRequest(*iot.GetPolicyVersionInput) (*request.Request, *iot.GetPolicyVersionOutput)

	GetPolicyVersion(*iot.GetPolicyVersionInput) (*iot.GetPolicyVersionOutput, error)

	GetRegistrationCodeRequest(*iot.GetRegistrationCodeInput) (*request.Request, *iot.GetRegistrationCodeOutput)

	GetRegistrationCode(*iot.GetRegistrationCodeInput) (*iot.GetRegistrationCodeOutput, error)

	GetTopicRuleRequest(*iot.GetTopicRuleInput) (*request.Request, *iot.GetTopicRuleOutput)

	GetTopicRule(*iot.GetTopicRuleInput) (*iot.GetTopicRuleOutput, error)

	ListCACertificatesRequest(*iot.ListCACertificatesInput) (*request.Request, *iot.ListCACertificatesOutput)

	ListCACertificates(*iot.ListCACertificatesInput) (*iot.ListCACertificatesOutput, error)

	ListCertificatesRequest(*iot.ListCertificatesInput) (*request.Request, *iot.ListCertificatesOutput)

	ListCertificates(*iot.ListCertificatesInput) (*iot.ListCertificatesOutput, error)

	ListCertificatesByCARequest(*iot.ListCertificatesByCAInput) (*request.Request, *iot.ListCertificatesByCAOutput)

	ListCertificatesByCA(*iot.ListCertificatesByCAInput) (*iot.ListCertificatesByCAOutput, error)

	ListPoliciesRequest(*iot.ListPoliciesInput) (*request.Request, *iot.ListPoliciesOutput)

	ListPolicies(*iot.ListPoliciesInput) (*iot.ListPoliciesOutput, error)

	ListPolicyPrincipalsRequest(*iot.ListPolicyPrincipalsInput) (*request.Request, *iot.ListPolicyPrincipalsOutput)

	ListPolicyPrincipals(*iot.ListPolicyPrincipalsInput) (*iot.ListPolicyPrincipalsOutput, error)

	ListPolicyVersionsRequest(*iot.ListPolicyVersionsInput) (*request.Request, *iot.ListPolicyVersionsOutput)

	ListPolicyVersions(*iot.ListPolicyVersionsInput) (*iot.ListPolicyVersionsOutput, error)

	ListPrincipalPoliciesRequest(*iot.ListPrincipalPoliciesInput) (*request.Request, *iot.ListPrincipalPoliciesOutput)

	ListPrincipalPolicies(*iot.ListPrincipalPoliciesInput) (*iot.ListPrincipalPoliciesOutput, error)

	ListPrincipalThingsRequest(*iot.ListPrincipalThingsInput) (*request.Request, *iot.ListPrincipalThingsOutput)

	ListPrincipalThings(*iot.ListPrincipalThingsInput) (*iot.ListPrincipalThingsOutput, error)

	ListThingPrincipalsRequest(*iot.ListThingPrincipalsInput) (*request.Request, *iot.ListThingPrincipalsOutput)

	ListThingPrincipals(*iot.ListThingPrincipalsInput) (*iot.ListThingPrincipalsOutput, error)

	ListThingsRequest(*iot.ListThingsInput) (*request.Request, *iot.ListThingsOutput)

	ListThings(*iot.ListThingsInput) (*iot.ListThingsOutput, error)

	ListTopicRulesRequest(*iot.ListTopicRulesInput) (*request.Request, *iot.ListTopicRulesOutput)

	ListTopicRules(*iot.ListTopicRulesInput) (*iot.ListTopicRulesOutput, error)

	RegisterCACertificateRequest(*iot.RegisterCACertificateInput) (*request.Request, *iot.RegisterCACertificateOutput)

	RegisterCACertificate(*iot.RegisterCACertificateInput) (*iot.RegisterCACertificateOutput, error)

	RegisterCertificateRequest(*iot.RegisterCertificateInput) (*request.Request, *iot.RegisterCertificateOutput)

	RegisterCertificate(*iot.RegisterCertificateInput) (*iot.RegisterCertificateOutput, error)

	RejectCertificateTransferRequest(*iot.RejectCertificateTransferInput) (*request.Request, *iot.RejectCertificateTransferOutput)

	RejectCertificateTransfer(*iot.RejectCertificateTransferInput) (*iot.RejectCertificateTransferOutput, error)

	ReplaceTopicRuleRequest(*iot.ReplaceTopicRuleInput) (*request.Request, *iot.ReplaceTopicRuleOutput)

	ReplaceTopicRule(*iot.ReplaceTopicRuleInput) (*iot.ReplaceTopicRuleOutput, error)

	SetDefaultPolicyVersionRequest(*iot.SetDefaultPolicyVersionInput) (*request.Request, *iot.SetDefaultPolicyVersionOutput)

	SetDefaultPolicyVersion(*iot.SetDefaultPolicyVersionInput) (*iot.SetDefaultPolicyVersionOutput, error)

	SetLoggingOptionsRequest(*iot.SetLoggingOptionsInput) (*request.Request, *iot.SetLoggingOptionsOutput)

	SetLoggingOptions(*iot.SetLoggingOptionsInput) (*iot.SetLoggingOptionsOutput, error)

	TransferCertificateRequest(*iot.TransferCertificateInput) (*request.Request, *iot.TransferCertificateOutput)

	TransferCertificate(*iot.TransferCertificateInput) (*iot.TransferCertificateOutput, error)

	UpdateCACertificateRequest(*iot.UpdateCACertificateInput) (*request.Request, *iot.UpdateCACertificateOutput)

	UpdateCACertificate(*iot.UpdateCACertificateInput) (*iot.UpdateCACertificateOutput, error)

	UpdateCertificateRequest(*iot.UpdateCertificateInput) (*request.Request, *iot.UpdateCertificateOutput)

	UpdateCertificate(*iot.UpdateCertificateInput) (*iot.UpdateCertificateOutput, error)

	UpdateThingRequest(*iot.UpdateThingInput) (*request.Request, *iot.UpdateThingOutput)

	UpdateThing(*iot.UpdateThingInput) (*iot.UpdateThingOutput, error)
}

var _ IoTAPI = (*iot.IoT)(nil)
