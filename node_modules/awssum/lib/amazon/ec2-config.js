// --------------------------------------------------------------------------------------------------------------------
//
// ec2-config.js - config for AWS Elastic Compute Cloud
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var required      = { required : true,  type : 'param'       };
var optional      = { required : false, type : 'param'       };
var requiredArray = { required : true,  type : 'param-array' };
var optionalArray = { required : false, type : 'param-array' };
var requiredData  = { required : true,  type : 'param-data'  };
var optionalData  = { required : false, type : 'param-data'  };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    AllocateAddress : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AllocateAddress.html',
        defaults : {
            Action : 'AllocateAddress'
        },
        args : {
            Action : required,
            Domain : optional,
        },
    },

    AssignPrivateIpAddresses : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AssignPrivateIpAddresses.html',
        defaults : {
            Action : 'AssignPrivateIpAddresses',
        },
        args : {
            Action                         : required,
            NetworkInterfaceId             : required,
            PrivateIpAddress               : optionalArray,
            SecondaryPrivateIpAddressCount : optional,
            AllowReassignment              : optional,
        },
    },

    AssociateAddress : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AssociateAddress.html',
        defaults : {
            Action : 'AssociateAddress',
        },
        args : {
            Action             : required,
            PublicIp           : optional,
            InstanceId         : optional,
            AllocationId       : optional,
            NetworkInterfaceId : optional,
            PrivateIpAddress   : optional,
            AllowReassociation : optional,
        },
    },

    AssociateDhcpOptions : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AssociateDhcpOptions.html',
        defaults : {
            Action : 'AssociateDhcpOptions',
        },
        args : {
            Action        : required,
            DhcpOptionsId : required,
            VpcId         : required,
        },
    },

    AssociateRouteTable : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AssociateRouteTable.html',
        defaults : {
            Action : 'AssociateRouteTable',
        },
        args : {
            Action       : required,
            RouteTableId : required,
            SubnetId     : required
        },
    },

    AttachInternetGateway : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AttachInternetGateway.html',
        defaults : {
            Action : 'AttachInternetGateway',
        },
        args : {
            Action            : required,
            InternetGatewayId : required,
            VpcId             : required,
        },
    },

    AttachNetworkInterface : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AttachNetworkInterface.html',
        defaults : {
            Action : 'AttachNetworkInterface',
        },
        args : {
            Action             : required,
            NetworkInterfaceId : required,
            InstanceId         : required,
            DeviceIndex        : required,
        },
    },

    AttachVolume : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AttachVolume.html',
        defaults : {
            Action : 'AttachVolume',
        },
        args : {
            Action     : required,
            VolumeId   : required,
            InstanceId : required,
            Device     : required,
        },
    },

    AttachVpnGateway : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AttachVpnGateway.html',
        defaults : {
            Action : 'AttachVpnGateway',
        },
        args : {
            Action       : required,
            VpnGatewayId : required,
            VpcId        : required,
        },
    },

    AuthorizeSecurityGroupEgress : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AuthorizeSecurityGroupEgress.html',
        defaults : {
            Action : 'AuthorizeSecurityGroupEgress',
        },
        args : {
            Action        : required,
            GroupId       : required,
            IpPermissions : requiredData,
        },
    },

    AuthorizeSecurityGroupIngress : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AuthorizeSecurityGroupIngress.html',
        defaults : {
            Action : 'AuthorizeSecurityGroupIngress',
        },
        args : {
            Action        : required,
            UserId        : optional,
            GroupId       : optional,
            GroupName     : optional,
            IpPermissions : requiredData,
        },
    },

    BundleInstance : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-BundleInstance.html',
        defaults : {
            Action : 'BundleInstance',
        },
        args : {
            Action     : required,
            InstanceId : required,
            Storage    : required,
        },
    },

    CancelBundleTask : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CancelBundleTask.html',
        defaults : {
            Action : 'CancelBundleTask',
        },
        args : {
            Action   : required,
            BundleId : required,
        },
    },

    CancelConversionTask : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CancelConversionTask.html',
        defaults : {
            Action : 'CancelConversionTask',
        },
        args : {
            Action           : required,
            ConversionTaskId : required,
        },
    },

    CancelExportTask : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CancelExportTask.html',
        defaults : {
            Action : 'CancelExportTask',
        },
        args : {
            Action       : required,
            ExportTaskId : required,
        },
    },

    CancelSpotInstanceRequests : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CancelSpotInstanceRequests.html',
        defaults : {
            Action : 'CancelSpotInstanceRequests',
        },
        args : {
            Action                : required,
            SpotInstanceRequestId : requiredArray,
        },
    },

    ConfirmProductInstance : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ConfirmProductInstance.html',
        defaults : {
            Action : 'ConfirmProductInstance',
        },
        args : {
            Action      : required,
            ProductCode : required,
            InstanceId  : required,
        },
    },

    CreateCustomerGateway : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateCustomerGateway.html',
        defaults : {
            Action : 'CreateCustomerGateway',
        },
        args : {
            Action    : required,
            Type      : required,
            IpAddress : required,
            BgpAsn    : required,
        },
    },

    CreateDhcpOptions : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateDhcpOptions.html',
        defaults : {
            Action : 'CreateDhcpOptions',
        },
        args : {
            Action            : required,
            DhcpConfiguration : requiredData,
        },
    },

    CreateImage : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateImage.html',
        defaults : {
            Action : 'CreateImage',
        },
        args : {
            Action      : required,
            InstanceId  : required,
            Name        : required,
            Description : optional,
            NoReboot    : optional,
        },
    },

    CreateInstanceExportTask : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateInstanceExportTask.html',
        defaults : {
            Action : 'CreateInstanceExportTask',
        },
        args : {
            Action            : required,
            Description       : optional,
            InstanceId        : required,
            TargetEnvironment : required,
            ExportToS3        : required,
        },
    },

    CreateInternetGateway : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateInternetGateway.html',
        defaults : {
            Action : 'CreateInternetGateway',
        },
        args : {
            Action : required,
        },
    },

    CreateKeyPair : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateKeyPair.html',
        defaults : {
            Action : 'CreateKeyPair',
        },
        args : {
            Action  : required,
            KeyName : required,
        },
    },

    CreateNetworkAcl : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateNetworkAcl.html',
        defaults : {
            Action : 'CreateNetworkAcl',
        },
        args : {
            Action : required,
            VpcId  : required,
        },
    },

    CreateNetworkAclEntry : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateNetworkAclEntry.html',
        defaults : {
            Action : 'CreateNetworkAclEntry',
        },
        args : {
            Action       : required,
            NetworkAclId : required,
            RuleNumber   : required,
            Protocol     : required,
            RuleAction   : required,
            Egress       : optional,
            CidrBlock    : required,
            Icmp         : optionalData,
            PortRange    : optionalData,
        },
    },

    CreateNetworkInterface : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateNetworkInterface.html',
        defaults : {
            Action : 'CreateNetworkInterface',
        },
        args : {
            Action                         : required,
            SubnetId                       : required,
            PrivateIpAddress               : optional,
            PrivateIpAddresses             : optional,
            SecondaryPrivateIpAddressCount : optional,
            Description                    : optional,
            SecurityGroupId                : optional,
        },
    },

    CreatePlacementGroup : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreatePlacementGroup.html',
        defaults : {
            Action : 'CreatePlacementGroup',
        },
        args : {
            Action    : required,
            GroupName : required,
            Strategy  : required,
        },
    },

    CreateRoute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateRoute.html',
        defaults : {
            Action : 'CreateRoute',
        },
        args : {
            Action               : required,
            RouteTableId         : required,
            DestinationCidrBlock : required,
            GatewayId            : optional,
            InstanceId           : optional,
            NetworkInterfaceId   : optional,
        },
    },

    CreateRouteTable : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateRouteTable.html',
        defaults : {
            Action : 'CreateRouteTable',
        },
        args : {
            Action : required,
            VpcId  : required,
        },
    },

    CreateSecurityGroup : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateSecurityGroup.html',
        defaults : {
            Action : 'CreateSecurityGroup',
        },
        args : {
            Action           : required,
            GroupName        : required,
            GroupDescription : required,
            VpcId            : optional,
        },
    },

    CreateSnapshot : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateSnapshot.html',
        defaults : {
            Action : 'CreateSnapshot',
        },
        args : {
            Action      : required,
            VolumeId    : required,
            Description : optional,
        },
    },

    CreateSpotDatafeedSubscription : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateSpotDatafeedSubscription.html',
        defaults : {
            Action : 'CreateSpotDatafeedSubscription',
        },
        args : {
            Action : required,
            Bucket : required,
            Prefix : optional,
        },
    },

    CreateSubnet : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateSubnet.html',
        defaults : {
            Action : 'CreateSubnet',
        },
        args : {
            Action           : required,
            VpcId            : required,
            CidrBlock        : required,
            AvailabilityZone : optional,
        },
    },

    CreateTags : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateTags.html',
        defaults : {
            Action : 'CreateTags',
        },
        args : {
            Action     : required,
            ResourceId : requiredArray,
            Tag        : requiredData,
        },
    },

    CreateVolume : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateVolume.html',
        defaults : {
            Action : 'CreateVolume',
        },
        args : {
            Action           : required,
            Size             : optional,
            SnapshotId       : optional,
            AvailabilityZone : required,
        },
    },

    CreateVpc : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateVpc.html',
        defaults : {
            Action : 'CreateVpc',
        },
        args : {
            Action          : required,
            CidrBlock       : required,
            InstanceTenancy : { required : false, type : 'param', name : 'instanceTenancy' },
        },
    },

    CreateVpnConnection : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateVpnConnection.html',
        defaults : {
            Action : 'CreateVpnConnection',
        },
        args : {
            Action            : required,
            Type              : required,
            CustomerGatewayId : required,
            VpnGatewayId      : required,
            AvailabilityZone  : optional,
        },
    },

    CreateVpnGateway : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateVpnGateway.html',
        defaults : {
            Action : 'CreateVpnGateway',
        },
        args : {
            Action : required,
            Type   : required,
            // AvailabilityZone - deprecated, the API ignores it anyway
        },
    },

    DeleteCustomerGateway : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteCustomerGateway.html',
        defaults : {
            Action : 'DeleteCustomerGateway',
        },
        args : {
            Action            : required,
            CustomerGatewayId : required,
        },
    },

    DeleteDhcpOptions : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteDhcpOptions.html',
        defaults : {
            Action : 'DeleteDhcpOptions',
        },
        args : {
            Action        : required,
            DhcpOptionsId : required,
        },
    },

    DeleteInternetGateway : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteInternetGateway.html',
        defaults : {
            Action : 'DeleteInternetGateway',
        },
        args : {
            Action            : required,
            InternetGatewayId : required,
        },
    },

    DeleteKeyPair : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteKeyPair.html',
        defaults : {
            Action : 'DeleteKeyPair',
        },
        args : {
            Action  : required,
            KeyName : required,
        },
    },

    DeleteNetworkAcl : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteNetworkAcl.html',
        defaults : {
            Action : 'DeleteNetworkAcl',
        },
        args : {
            Action       : required,
            NetworkAclId : required,
        },
    },

    DeleteNetworkAclEntry : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteNetworkAclEntry.html',
        defaults : {
            Action : 'DeleteNetworkAclEntry',
        },
        args : {
            Action       : required,
            NetworkAclId : required,
            RuleNumber   : required,
            Egress       : optional,
        },
    },

    DeleteNetworkInterface : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteNetworkInterface.html',
        defaults : {
            Action : 'DeleteNetworkInterface',
        },
        args : {
            Action             : required,
            NetworkInterfaceId : required,
        },
    },

    DeletePlacementGroup : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeletePlacementGroup.html',
        defaults : {
            Action : 'DeletePlacementGroup',
        },
        args : {
            Action    : required,
            GroupName : required,
        },
    },

    DeleteRoute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteRoute.html',
        defaults : {
            Action : 'DeleteRoute',
        },
        args : {
            Action               : required,
            RouteTableId         : required,
            DestinationCidrBlock : required,
        },
    },

    DeleteRouteTable : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteRouteTable.html',
        defaults : {
            Action : 'DeleteRouteTable',
        },
        args : {
            Action       : required,
            RouteTableId : required,
        },
    },

    DeleteSecurityGroup : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteSecurityGroup.html',
        defaults : {
            Action : 'DeleteSecurityGroup',
        },
        args : {
            Action    : required,
            GroupName : required,
            GroupId   : required,
        },
    },

    DeleteSnapshot : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteSnapshot.html',
        defaults : {
            Action : 'DeleteSnapshot',
        },
        args : {
            Action     : required,
            SnapshotId : required,
        },
    },

    DeleteSpotDatafeedSubscription : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteSpotDatafeedSubscription.html',
        defaults : {
            Action : 'DeleteSpotDatafeedSubscription',
        },
        args : {
            Action : required,
        },
    },

    DeleteSubnet : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteSubnet.html',
        defaults : {
            Action : 'DeleteSubnet',
        },
        args : {
            Action   : required,
            SubnetId : required,
        },
    },

    DeleteTags : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteTags.html',
        defaults : {
            Action : 'DeleteTags',
        },
        args : {
            Action     : required,
            ResourceId : requiredArray,
            Tag        : requiredData,
        },
    },

    DeleteVolume : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteVolume.html',
        defaults : {
            Action : 'DeleteVolume',
        },
        args : {
            Action   : required,
            VolumeId : required,
        },
    },

    DeleteVpc : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteVpc.html',
        defaults : {
            Action : 'DeleteVpc',
        },
        args : {
            Action : required,
            VpcId  : required,
        },
    },

    DeleteVpnConnection : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteVpnConnection.html',
        defaults : {
            Action : 'DeleteVpnConnection',
        },
        args : {
            Action          : required,
            VpnConnectionId : required,
        },
    },

    DeleteVpnGateway : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteVpnGateway.html',
        defaults : {
            Action : 'DeleteVpnGateway',
        },
        args : {
            Action       : required,
            VpnGatewayId : required,
        },
    },

    DeregisterImage : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeregisterImage.html',
        defaults : {
            Action : 'DeregisterImage',
        },
        args : {
            Action  : required,
            ImageId : required,
        },
    },

    DescribeAddresses : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeAddresses.html',
        defaults : {
            Action : 'DescribeAddresses',
        },
        args : {
            Action       : required,
            PublicIp     : optionalArray,
            AllocationId : optionalArray,
            Filter       : optionalData,
        },
    },

    DescribeAvailabilityZones : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeAvailabilityZones.html',
        defaults : {
            Action : 'DescribeAvailabilityZones',
        },
        args : {
            Action   : required,
            ZoneName : optionalArray,
            Filter   : optionalData,
        },
    },

    DescribeBundleTasks : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeBundleTasks.html',
        defaults : {
            Action : 'DescribeBundleTasks',
        },
        args : {
            Action   : required,
            BundleId : optionalArray,
            Filter   : optionalData,
        },
    },

    DescribeConversionTasks : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeConversionTasks.html',
        defaults : {
            Action : 'DescribeConversionTasks',
        },
        args : {
            Action           : required,
            ConversionTaskId : optionalArray,
        },
    },

    DescribeCustomerGateways : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeCustomerGateways.html',
        defaults : {
            Action : 'DescribeCustomerGateways',
        },
        args : {
            Action            : required,
            CustomerGatewayId : optionalArray,
            Filter            : optionalData,
        },
    },

    DescribeDhcpOptions : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeDhcpOptions.html',
        defaults : {
            Action : 'DescribeDhcpOptions',
        },
        args : {
            Action        : required,
            DhcpOptionsId : optionalArray,
            Filter        : optionalData,
        },
    },

    DescribeExportTasks : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeExportTasks.html',
        defaults : {
            Action : 'DescribeExportTasks',
        },
        args : {
            Action       : required,
            ExportTaskId : optionalArray,
        },
    },

    DescribeImageAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeImageAttribute.html',
        defaults : {
            Action : 'DescribeImageAttribute',
        },
        args : {
            Action    : required,
            ImageId   : required,
            Attribute : required,
        },
    },

    DescribeImages : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeImages.html',
        defaults : {
            Action : 'DescribeImages',
        },
        args : {
            Action       : required,
            ExecutableBy : optionalArray,
            ImageId      : optionalArray,
            Owner        : optionalArray,
            Filter       : optionalData,
        },
    },

    DescribeInstanceAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeInstanceAttribute.html',
        defaults : {
            Action : 'DescribeInstanceAttribute',
        },
        args : {
            Action     : required,
            InstanceId : required,
            Attribute  : required,
        },
    },

    DescribeInstances : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeInstances.html',
        defaults : {
            Action : 'DescribeInstances',
        },
        args : {
            Action     : required,
            InstanceId : optionalArray,
            Filter     : optionalData,
        },
    },

    DescribeInstanceStatus : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeInstanceStatus.html',
        defaults : {
            Action : 'DescribeInstanceStatus',
        },
        args : {
            Action              : required,
            InstanceId          : optional,
            IncludeAllInstances : optional,
            MaxResults          : optional,
            NextToken           : optional,
        },
    },

    DescribeInternetGateways : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeInternetGateways.html',
        defaults : {
            Action : 'DescribeInternetGateways',
        },
        args : {
            Action            : required,
            InternetGatewayId : optionalArray,
            Filter            : optionalData,
        },
    },

    DescribeKeyPairs : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeKeyPairs.html',
        defaults : {
            Action : 'DescribeKeyPairs',
        },
        args : {
            Action  : required,
            KeyName : optionalArray,
            Filter  : optionalData,
        },
    },

    DescribeNetworkAcls : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeNetworkAcls.html',
        defaults : {
            Action : 'DescribeNetworkAcls',
        },
        args : {
            Action       : required,
            NetworkAclId : optionalArray,
            Filter       : optionalData,
        },
    },

    DescribeNetworkInterfaceAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeNetworkInterfaceAttribute.html',
        defaults : {
            Action : 'DescribeNetworkInterfaceAttribute',
        },
        args : {
            Action             : required,
            NetworkInterfaceId : required,
            Attribute          : required,
        },
    },

    DescribeNetworkInterfaces : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeNetworkInterfaces.html',
        defaults : {
            Action : 'DescribeNetworkInterfaces',
        },
        args : {
            Action             : required,
            NetworkInterfaceId : optionalArray,
            Filter             : optionalData,
        },
    },

    DescribePlacementGroups : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribePlacementGroups.html',
        defaults : {
            Action : 'DescribePlacementGroups',
        },
        args : {
            Action    : required,
            GroupName : optionalArray,
            Filter    : optionalData,
        },
    },

    DescribeRegions : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeRegions.html',
        defaults : {
            Action : 'DescribeRegions',
        },
        args : {
            Action     : required,
            RegionName : optionalArray,
            Filter     : optionalData,
        },
    },

    DescribeReservedInstances : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeReservedInstances.html',
        defaults : {
            Action : 'DescribeReservedInstances',
        },
        args : {
            Action              : required,
            ReservedInstancesId : optionalArray,
            Filter              : optionalData,
            OfferingType        : { required : false, type : 'param', name : 'offeringType' },
        },
    },

    DescribeReservedInstancesOfferings : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeReservedInstancesOfferings.html',
        defaults : {
            Action : 'DescribeReservedInstancesOfferings',
        },
        args : {
            Action : required,
            ReservedInstancesOfferingId : optionalArray,
            InstanceType                : optional,
            AvailabilityZone            : optional,
            ProductDescription          : optional,
            Filter                      : optionalData,
            InstanceTenancy             : { required : false, type : 'param', name : 'instanceTenancy' },
            OfferingType                : { required : false, type : 'param', name : 'offeringType' },
        },
    },

    DescribeRouteTables : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeRouteTables.html',
        defaults : {
            Action : 'DescribeRouteTables',
        },
        args : {
            Action       : required,
            RouteTableId : optionalArray,
            Filter       : optionalData,
        },
    },

    DescribeSecurityGroups : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSecurityGroups.html',
        defaults : {
            Action : 'DescribeSecurityGroups',
        },
        args : {
            Action    : required,
            GroupName : optionalArray,
            GroupId   : optionalArray,
            Filter    : optionalData,
        },
    },

    DescribeSnapshotAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshotAttribute.html',
        defaults : {
            Action : 'DescribeSnapshotAttribute',
        },
        args : {
            Action     : required,
            SnapshotId : required,
            Attribute  : required,
        },
    },

    DescribeSnapshots : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html',
        defaults : {
            Action : 'DescribeSnapshots',
        },
        args : {
            Action       : required,
            SnapshotId   : optionalArray,
            Owner        : optionalArray,
            RestorableBy : optionalArray,
            Filter       : optionalData,
        },
    },

    DescribeSpotDatafeedSubscription : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSpotDatafeedSubscription.html',
        defaults : {
            Action : 'DescribeSpotDatafeedSubscription',
        },
        args : {
            Action : required,
        },
    },

    DescribeSpotInstanceRequests : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSpotInstanceRequests.html',
        defaults : {
            Action : 'DescribeSpotInstanceRequests',
        },
        args : {
            Action                : required,
            SpotInstanceRequestId : optionalArray,
            Filter                : optionalData,
        },
    },

    DescribeSpotPriceHistory : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSpotPriceHistory.html',
        defaults : {
            Action : 'DescribeSpotPriceHistory',
        },
        args : {
            Action             : required,
            StartTime          : optional,
            EndTime            : optional,
            InstanceType       : optionalArray,
            ProductDescription : optionalArray,
            Filter             : optionalData,
            AvailabilityZone   : optional,
            MaxResults         : optional,
            NextToken          : optional,
        },
    },

    DescribeSubnets : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSubnets.html',
        defaults : {
            Action : 'DescribeSubnets',
        },
        args : {
            Action   : required,
            SubnetId : optionalArray,
            Filter   : optionalData,
        },
    },

    DescribeTags : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeTags.html',
        defaults : {
            Action : 'DescribeTags',
        },
        args : {
            Action : required,
            Filter : optionalData,
        },
    },

    DescribeVolumes : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVolumes.html',
        defaults : {
            Action : 'DescribeVolumes',
        },
        args : {
            Action   : required,
            VolumeId : optionalArray,
            Filter   : optionalData,
        },
    },

    DescribeVolumeAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVolumeAttribute.html',
        defaults : {
            Action : 'DescribeVolumeAttribute',
        },
        args : {
            Action    : required,
            VolumeId  : required,
            Attribute : required,
        },
    },

    DescribeVolumeStatus : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVolumeStatus.html',
        defaults : {
            Action : 'DescribeVolumeStatus',
        },
        args : {
            Action     : required,
            VolumeId   : optionalArray,
            Filter     : optionalData,
            MaxResults : optional,
            NextToken  : optional,
        },
    },

    DescribeVpcs : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVpcs.html',
        defaults : {
            Action : 'DescribeVpcs',
        },
        args : {
            Action : required,
            VpcId  : optionalArray,
            Filter : optionalData,
        },
    },

    DescribeVpnConnections : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVpnConnections.html',
        defaults : {
            Action : 'DescribeVpnConnections',
        },
        args : {
            Action          : required,
            VpnConnectionId : optionalArray,
            Filter          : optionalData,
        },
    },

    DescribeVpnGateways : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeVpnGateways.html',
        defaults : {
            Action : 'DescribeVpnGateways',
        },
        args : {
            Action       : required,
            VpnGatewayId : optionalArray,
            Filter       : optionalData,
        },
    },

    DetachInternetGateway : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DetachInternetGateway.html',
        defaults : {
            Action : 'DetachInternetGateway',
        },
        args : {
            Action            : required,
            InternetGatewayId : required,
            VpcId             : required,
        },
    },

    DetachNetworkInterface : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DetachNetworkInterface.html',
        defaults : {
            Action : 'DetachNetworkInterface',
        },
        args : {
            Action       : required,
            AttachmentId : required,
            Force        : optional,
        },
    },

    DetachVolume : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DetachVolume.html',
        defaults : {
            Action : 'DetachVolume',
        },
        args : {
            Action     : required,
            VolumeId   : required,
            InstanceId : optional,
            Device     : optional,
            Force      : optional,
        },
    },

    DetachVpnGateway : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DetachVpnGateway.html',
        defaults : {
            Action : 'DetachVpnGateway',
        },
        args : {
            Action       : required,
            VpnGatewayId : required,
            VpcId        : required,
        },
    },

    DisassociateAddress : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DisassociateAddress.html',
        defaults : {
            Action : 'DisassociateAddress',
        },
        args : {
            Action        : required,
            PublicIp      : optional,
            AssociationId : optional,
        },
    },

    DisassociateRouteTable : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DisassociateRouteTable.html',
        defaults : {
            Action : 'DisassociateRouteTable',
        },
        args : {
            Action        : required,
            AssociationId : required,
        },
    },

    EnableVolumeIo : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-EnableVolumeIO.html',
        defaults : {
            Action : 'EnableVolumeIO',
        },
        args : {
            Action   : required,
            VolumeId : required,
        },
    },

    GetConsoleOutput : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-GetConsoleOutput.html',
        defaults : {
            Action : 'GetConsoleOutput',
        },
        args : {
            Action     : required,
            InstanceId : required,
        },
    },

    GetPasswordData : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-GetPasswordData.html',
        defaults : {
            Action : 'GetPasswordData',
        },
        args : {
            Action     : required,
            InstanceId : required,
        },
    },

    ImportInstance : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ImportInstance.html',
        defaults : {
            Action : 'ImportInstance',
        },
        args : {
            Action                            : required,
            Description                       : optional,
            Architecture                      : required,
            SecurityGroup                     : optionalArray,
            UserData                          : optional,
            InstanceType                      : required,
            Placement                         : optionalData,
            Monitoring                        : optionalData,
            SubnetId                          : optional,
            InstanceInitiatedShutdownBehavior : optional,
            PrivateIpAddress                  : optional,
            DiskImage                         : requiredData,
            Platform                          : required,
        },
    },

    ImportKeyPair : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ImportKeyPair.html',
        defaults : {
            Action : 'ImportKeyPair',
        },
        args : {
            Action            : required,
            KeyName           : required,
            PublicKeyMaterial : required,
        },
    },

    ImportVolume : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ImportVolume.html',
        defaults : {
            Action : 'ImportVolume',
        },
        args : {
            Action           : required,
            AvailabilityZone : required,
            Image            : requiredData,
            Description      : optional,
            Volume           : requiredData,
        },
    },

    ModifyImageAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifyImageAttribute.html',
        defaults : {
            Action : 'ModifyImageAttribute',
        },
        args : {
            Action           : required,
            ImageId          : required,
            LaunchPermission : optionalData,
            ProductCode      : optional,
            Description      : optional,
        },
    },

    ModifyInstanceAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifyInstanceAttribute.html',
        defaults : {
            Action : 'ModifyInstanceAttribute',
        },
        args : {
            Action                            : required,
            ImageId                           : required,
            InstanceType                      : optionalData,
            Kernel                            : optionalData,
            Ramdisk                           : optionalData,
            UserData                          : optionalData,
            DisableApiTermination             : optionalData,
            InstanceInitiatedShutdownBehavior : optionalData,
            BlockMappingDevice                : optionalData,
            SourceDestCheck                   : optionalData,
            GroupId                           : optionalArray,
            EbsOptimized                      : optional,
        },
    },

    ModifyNetworkInterfaceAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifyNetworkInterfaceAttribute.html',
        defaults : {
            Action : 'ModifyNetworkInterfaceAttribute',
        },
        args : {
            Action             : required,
            NetworkInterfaceId : required,
            Description        : optionalData,
            SecurityGroupId    : optionalArray,
            SourceDestCheck    : optionalData,
            Attachment         : optionalData,
        },
    },

    ModifySnapshotAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifySnapshotAttribute.html',
        defaults : {
            Action : 'ModifySnapshotAttribute',
        },
        args : {
            Action                 : required,
            SnapshotId             : required,
            CreateVolumePermission : requiredData,
        },
    },

    ModifyVolumeAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifyVolumeAttribute.html',
        defaults : {
            Action : 'ModifyVolumeAttribute',
        },
        args : {
            Action       : required,
            VolumeId     : required,
            AutoEnableIO : requiredData,
        },
    },

    MonitorInstances : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-MonitorInstances.html',
        defaults : {
            Action : 'MonitorInstances',
        },
        args : {
            Action     : required,
            InstanceId : requiredArray,
        },
    },

    PurchaseReservedInstancesOffering : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-PurchaseReservedInstancesOffering.html',
        defaults : {
            Action : 'PurchaseReservedInstancesOffering',
        },
        args : {
            Action                      : required,
            ReservedInstancesOfferingId : required,
            InstanceCount               : optional,
        },
    },

    RebootInstances : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RebootInstances.html',
        defaults : {
            Action : 'RebootInstances',
        },
        args : {
            Action     : required,
            InstanceId : requiredArray,
        },
    },

    RegisterImage : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RegisterImage.html',
        defaults : {
            Action : 'RegisterImage',
        },
        args : {
            Action             : required,
            ImageLocation      : optional,
            Name               : required,
            Description        : optional,
            Architecture       : optional,
            KernelId           : optional,
            RamdiskId          : optional,
            RootDeviceName     : optional,
            BlockDeviceMapping : optionalData,
        },
    },

    ReleaseAddress : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReleaseAddress.html',
        defaults : {
            Action : 'ReleaseAddress',
        },
        args : {
            Action       : required,
            PublicIp     : optional,
            AllocationId : optional,
        },
    },

    ReplaceNetworkAclAssociation : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReplaceNetworkAclAssociation.html',
        defaults : {
            Action : 'ReplaceNetworkAclAssociation',
        },
        args : {
            Action        : required,
            AssociationId : required,
            NetworkAclId  : required,
        },
    },

    ReplaceNetworkAclEntry : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReplaceNetworkAclEntry.html',
        defaults : {
            Action : 'ReplaceNetworkAclEntry',
        },
        args : {
            Action       : required,
            NetworkAclId : required,
            RuleNumber   : required,
            Protocol     : required,
            RuleAction   : required,
            Egress       : optional,
            CidrBlock    : required,
            Icmp         : optionalData,
            PortRange    : optionalData,
        },
    },

    ReplaceRoute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReplaceRoute.html',
        defaults : {
            Action : 'ReplaceRoute',
        },
        args : {
            Action               : required,
            RouteTableId         : required,
            DestinationCidrBlock : required,
            GatewayId            : optional,
            InstanceId           : optional,
            NetworkInterfaceId   : optional,
        },
    },

    ReplaceRouteTableAssociation : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReplaceRouteTableAssociation.html',
        defaults : {
            Action : 'ReplaceRouteTableAssociation',
        },
        args : {
            Action        : required,
            AssociationId : required,
            RouteTableId  : required,
        },
    },

    ReportInstanceStatus : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReportInstanceStatus.html',
        defaults : {
            Action : 'ReportInstanceStatus',
        },
        args : {
            Action      : required,
            InstanceID  : requiredArray,
            Status      : required,
            StartTime   : optional,
            EndTime     : optional,
            ReasonCodes : requiredArray,
            Description : optional,
        },
    },

    RequestSpotInstances : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RequestSpotInstances.html',
        defaults : {
            Action : 'RequestSpotInstances',
        },
        args : {
            Action                : required,
            SpotPrice             : required,
            InstanceCount         : optional,
            Type                  : optional,
            ValidFrom             : optional,
            ValidUntil            : optional,
            Subnet                : optional,
            LaunchGroup           : optional,
            AvailabilityZoneGroup : optional,
            Placement             : optionalData,
            LaunchSpecification   : requiredData, // because of LaunchSpecification.{ImageId,InstanceType}
        },
    },

    ResetImageAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ResetImageAttribute.html',
        defaults : {
            Action : 'ResetImageAttribute',
        },
        args : {
            Action    : required,
            ImageId   : required,
            Attribute : required,
        },
    },

    ResetInstanceAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ResetInstanceAttribute.html',
        defaults : {
            Action : 'ResetInstanceAttribute',
        },
        args : {
            Action     : required,
            InstanceId : required,
            Attribute  : required,
        },
    },

    ResetNetworkInterfaceAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ResetNetworkInterfaceAttribute.html',
        defaults : {
            Action : 'ResetNetworkInterfaceAttribute',
        },
        args : {
            Action             : required,
            NetworkInterfaceId : required,
            Attribute          : required,
        },
    },

    ResetSnapshotAttribute : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ResetSnapshotAttribute.html',
        defaults : {
            Action : 'ResetSnapshotAttribute',
        },
        args : {
            Action     : required,
            SnapshotId : required,
            Attribute  : required,
        },
    },

    RevokeSecurityGroupEgress : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RevokeSecurityGroupEgress.html',
        defaults : {
            Action : 'RevokeSecurityGroupEgress',
        },
        args : {
            Action        : required,
            GroupId       : required,
            IpPermissions : requiredData,
        },
    },

    RevokeSecurityGroupIngress : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RevokeSecurityGroupIngress.html',
        defaults : {
            Action : 'RevokeSecurityGroupIngress',
        },
        args : {
            Action        : required,
            UserId        : optional,
            GroupId       : optional,
            GroupName     : optional,
            IpPermissions : requiredData,
        },
    },

    RunInstances : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RunInstances.html',
        defaults : {
            Action : 'RunInstances',
        },
        args : {
            Action                            : required,
            ImageId                           : required,
            MinCount                          : required,
            MaxCount                          : required,
            KeyName                           : optional,
            SecurityGroupId                   : optionalArray,
            SecurityGroup                     : optionalArray,
            UserData                          : optional,
            AddressingType                    : optional,
            InstanceType                      : optional,
            Placement                         : optionalData,
            KernelId                          : optional,
            RamdiskId                         : optional,
            BlockDeviceMapping                : optionalData,
            Monitoring                        : optionalData,
            SubnetId                          : optional,
            DisableApiTermination             : optional,
            InstanceInitiatedShutdownBehavior : optional,
            PrivateIpAddress                  : optional,
            ClientToken                       : optional,
            NetworkInterface                  : optionalData,
            IamInstanceProfile                : optionalData,
            EbsOptimized                      : optional,
        },
    },

    StartInstances : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-StartInstances.html',
        defaults : {
            Action : 'StartInstances',
        },
        args : {
            Action     : required,
            InstanceId : requiredArray,
        },
    },

    StopInstances : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-StopInstances.html',
        defaults : {
            Action : 'StopInstances',
        },
        args : {
            Action     : required,
            InstanceId : requiredArray,
            Force      : optional,
        },
    },

    TerminateInstances : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-TerminateInstances.html',
        defaults : {
            Action : 'TerminateInstances',
        },
        args : {
            Action     : required,
            InstanceId : requiredArray,
        },
    },

    UnassignPrivateIpAddresses : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-UnassignPrivateIpAddresses.html',
        defaults : {
            Action : 'UnassignPrivateIpAddresses',
        },
        args : {
            Action             : required,
            NetworkInterfaceId : required,
            PrivateIpAddress   : requiredArray,
        },
    },

    UnmonitorInstances : {
        url : 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-UnmonitorInstances.html',
        defaults : {
            Action : 'UnmonitorInstances',
        },
        args : {
            Action     : required,
            InstanceId : requiredArray,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
