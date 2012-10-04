// --------------------------------------------------------------------------------------------------------------------
//
// ec2-config.js - class for AWS Elastic Compute Cloud
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// From: http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/query-apis.html
//
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AllocateAddress.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AssociateAddress.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AssociateDhcpOptions.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AssociateRouteTable.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AttachInternetGateway.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AttachVolume.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AttachVpnGateway.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AuthorizeSecurityGroupEgress.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AuthorizeSecurityGroupIngress.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-BundleInstance.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CancelBundleTask.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CancelConversionTask.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CancelSpotInstanceRequests.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ConfirmProductInstance.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateCustomerGateway.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateDhcpOptions.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateImage.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateInternetGateway.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateKeyPair.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateNetworkAcl.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateNetworkAclEntry.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreatePlacementGroup.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateRoute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateRouteTable.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateSecurityGroup.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateSnapshot.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateSpotDatafeedSubscription.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateSubnet.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateTags.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateVolume.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateVpc.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateVpnConnection.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateVpnGateway.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteCustomerGateway.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteDhcpOptions.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteInternetGateway.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteKeyPair.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteNetworkAcl.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteNetworkAclEntry.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeletePlacementGroup.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteRoute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteRouteTable.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteSecurityGroup.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteSnapshot.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteSpotDatafeedSubscription.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteSubnet.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteTags.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteVolume.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteVpc.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteVpnConnection.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteVpnGateway.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeregisterImage.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeAddresses.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeAvailabilityZones.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeBundleTasks.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeConversionTasks.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeCustomerGateways.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeDhcpOptions.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeImageAttribute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeImages.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeInstanceAttribute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeInstances.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeInstanceStatus.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeInternetGateways.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeKeyPairs.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeNetworkAcls.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribePlacementGroups.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeRegions.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeReservedInstances.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeReservedInstancesOfferings.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeRouteTables.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSecurityGroups.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshotAttribute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSpotDatafeedSubscription.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSpotInstanceRequests.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSpotPriceHistory.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSubnets.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeTags.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVolumes.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVpcs.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVpnConnections.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVpnGateways.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DetachInternetGateway.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DetachVolume.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DetachVpnGateway.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DisassociateAddress.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DisassociateRouteTable.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-GetConsoleOutput.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-GetPasswordData.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ImportInstance.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ImportKeyPair.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ImportVolume.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifyImageAttribute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifyInstanceAttribute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifySnapshotAttribute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-MonitorInstances.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-PurchaseReservedInstancesOffering.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RebootInstances.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RegisterImage.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReleaseAddress.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReplaceNetworkAclAssociation.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReplaceNetworkAclEntry.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReplaceRoute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReplaceRouteTableAssociation.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RequestSpotInstances.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ResetImageAttribute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ResetInstanceAttribute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ResetSnapshotAttribute.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RevokeSecurityGroupEgress.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RevokeSecurityGroupIngress.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RunInstances.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-StartInstances.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-StopInstances.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-TerminateInstances.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-UnmonitorInstances.html

module.exports = {

    // Operations on Distributions

    DescribeInstances : {
        defaults : {
            Action : 'DescribeInstances',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            InstanceId : {
                // does InstanceId.<i>
                name     : 'AWSAccountId',
                required : false,
                type     : 'param-array',
            },
            FilterName : {
                // does Filter.<i>.Name
                name     : 'Name',
                required : false,
                type     : 'param-array-set',
                setName  : 'Filter',
            },
            FilterValue : {
                // does Filter.<i>.Value.<j>
                name     : 'Value',
                required : false,
                type     : 'param-2d-array',
                setName  : 'Filter',
            },
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
