// --------------------------------------------------------------------------------------------------------------------
//
// rds-config.js - config for AWS Relational Database Service
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var required      = { required : true,  type : 'param'       };
var optional      = { required : false, type : 'param'       };
var requiredArray = { required : true,  type : 'param-array', prefix : 'member' };
var optionalArray = { required : false, type : 'param-array', prefix : 'member' };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    AuthorizeDBSecurityGroupIngress : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_AuthorizeDBSecurityGroupIngress.html',
        defaults : {
            Action : 'AuthorizeDBSecurityGroupIngress'
        },
        args : {
            Action                  : required,
            CIDRIP                  : optional,
            DBSecurityGroupName     : required,
            EC2SecurityGroupId      : optional,
            EC2SecurityGroupName    : optional,
            EC2SecurityGroupOwnerId : optional,
        },
    },

    CopyDBSnapshot : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CopyDBSnapshot.html',
        defaults : {
            Action : 'CopyDBSnapshot'
        },
        args : {
            Action                     : required,
            SourceDBSnapshotIdentifier : required,
            TargetDBSnapshotIdentifier : required,
        },
    },

    CreateDBInstance : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html',
        defaults : {
            Action : 'CreateDBInstance'
        },
        args : {
            Action                     : required,
            AllocatedStorage           : required,
            AutoMinorVersionUpgrade    : optional,
            AvailabilityZone           : optional,
            BackupRetentionPeriod      : optional,
            CharacterSetName           : optional,
            DBInstanceClass            : required,
            DBInstanceIdentifier       : required,
            DBName                     : optional,
            DBParameterGroupName       : optional,
            DBSecurityGroups           : requiredArray,
            DBSubnetGroupName          : optional,
            Engine                     : required,
            EngineVersion              : optional,
            LicenseModel               : optional,
            MasterUserPassword         : required,
            MasterUsername             : required,
            MultiAZ                    : optional,
            OptionGroupName            : optional,
            Port                       : optional,
            PreferredBackupWindow      : optional,
            PreferredMaintenanceWindow : optional,
        },
    },

    CreateDBInstanceReadReplica : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CreateDBInstanceReadReplica.html',
        defaults : {
            Action : 'CreateDBInstanceReadReplica'
        },
        args : {
            Action                     : required,
            AutoMinorVersionUpgrade    : optional,
            AvailabilityZone           : optional,
            DBInstanceClass            : optional,
            DBInstanceIdentifier       : required,
            OptionGroupName            : optional,
            Port                       : optional,
            SourceDBInstanceIdentifier : required,
        },
    },

    CreateDBParameterGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CreateDBParameterGroup.html',
        defaults : {
            Action : 'CreateDBParameterGroup'
        },
        args : {
            Action                 : required,
            DBParameterGroupFamily : required,
            DBParameterGroupName   : required,
            Description            : required,
        },
    },

    CreateDBSecurityGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CreateDBSecurityGroup.html',
        defaults : {
            Action : 'CreateDBSecurityGroup'
        },
        args : {
            Action                     : required,
            DBSecurityGroupDescription : required,
            DBSecurityGroupName        : required,
            EC2VpcId                   : required,
        },
    },

    CreateDBSnapshot : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CreateDBSnapshot.html',
        defaults : {
            Action : 'CreateDBSnapshot'
        },
        args : {
            Action               : required,
            DBInstanceIdentifier : required,
            DBSnapshotIdentifier : required,
        },
    },

    CreateDBSubnetGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CreateDBSubnetGroup.html',
        defaults : {
            Action : 'CreateDBSubnetGroup'
        },
        args : {
            Action                   : required,
            DBSubnetGroupDescription : required,
            DBSubnetGroupName        : required,
            SubnetIds                : requiredArray,
        },
    },

    CreateOptionGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CreateOptionGroup.html',
        defaults : {
            Action : 'CreateOptionGroup'
        },
        args : {
            Action                 : required,
            EngineName             : required,
            MajorEngineVersion     : required,
            OptionGroupDescription : required,
            OptionGroupName        : required,
        },
    },

    DeleteDBInstance : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DeleteDBInstance.html',
        defaults : {
            Action : 'DeleteDBInstance'
        },
        args : {
            Action                    : required,
            DBInstanceIdentifier      : required,
            FinalDBSnapshotIdentifier : optional,
            SkipFinalSnapshot         : optional,
        },
    },

    DeleteDBParameterGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DeleteDBParameterGroup.html',
        defaults : {
            Action : 'DeleteDBParameterGroup'
        },
        args : {
            Action               : required,
            DBParameterGroupName : required,
        },
    },

    DeleteDBSecurityGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DeleteDBSecurityGroup.html',
        defaults : {
            Action : 'DeleteDBSecurityGroup'
        },
        args : {
            Action              : required,
            DBSecurityGroupName : required,
        },
    },

    DeleteDBSnapshot : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DeleteDBSnapshot.html',
        defaults : {
            Action : 'DeleteDBSnapshot'
        },
        args : {
            Action               : required,
            DBSnapshotIdentifier : required,
        },
    },

    DeleteDBSubnetGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DeleteDBSubnetGroup.html',
        defaults : {
            Action : 'DeleteDBSubnetGroup'
        },
        args : {
            Action            : required,
            DBSubnetGroupName : required,
        },
    },

    DeleteOptionGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DeleteOptionGroup.html',
        defaults : {
            Action : 'DeleteOptionGroup'
        },
        args : {
            Action          : required,
            OptionGroupName : required,
        },
    },

    DescribeDBEngineVersions : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeDBEngineVersions.html',
        defaults : {
            Action : 'DescribeDBEngineVersions'
        },
        args : {
            Action                     : required,
            DBParameterGroupFamily     : optional,
            DefaultOnly                : optional,
            Engine                     : optional,
            EngineVersion              : optional,
            ListSupportedCharacterSets : optional,
            Marker                     : optional,
            MaxRecords                 : optional,
        },
    },

    DescribeDBInstances : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeDBInstances.html',
        defaults : {
            Action : 'DescribeDBInstances'
        },
        args : {
            Action               : required,
            DBInstanceIdentifier : optional,
            Marker               : optional,
            MaxRecords           : optional,
        },
    },

    DescribeDBParameterGroups : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeDBParameterGroups.html',
        defaults : {
            Action : 'DescribeDBParameterGroups'
        },
        args : {
            Action               : required,
            DBParameterGroupName : optional,
            Marker               : optional,
            MaxRecords           : optional,
        },
    },

    DescribeDBParameters : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeDBParameters.html',
        defaults : {
            Action : 'DescribeDBParameters'
        },
        args : {
            Action               : required,
            DBParameterGroupName : required,
            Marker               : optional,
            MaxRecords           : optional,
            Source               : optional,
        },
    },

    DescribeDBSecurityGroups : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeDBSecurityGroups.html',
        defaults : {
            Action : 'DescribeDBSecurityGroups'
        },
        args : {
            Action              : required,
            DBSecurityGroupName : optional,
            Marker              : optional,
            MaxRecords          : optional,
        },
    },

    DescribeDBSnapshots : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeDBSnapshots.html',
        defaults : {
            Action : 'DescribeDBSnapshots'
        },
        args : {
            Action : required,
            DBInstanceIdentifier : optional,
            DBSnapshotIdentifier : optional,
            Marker               : optional,
            MaxRecords           : optional,
            SnapshotType         : optional,
        },
    },

    DescribeDBSubnetGroups : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeDBSubnetGroups.html',
        defaults : {
            Action : 'DescribeDBSubnetGroups'
        },
        args : {
            Action            : required,
            DBSubnetGroupName : required,
            Marker            : optional,
            MaxRecords        : optional,
        },
    },

    DescribeEngineDefaultParameters : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeEngineDefaultParameters.html',
        defaults : {
            Action : 'DescribeEngineDefaultParameters'
        },
        args : {
            Action                 : required,
            DBParameterGroupFamily : required,
            Marker                 : optional,
            MaxRecords             : optional,
        },
    },

    DescribeEvents : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeEvents.html',
        defaults : {
            Action : 'DescribeEvents'
        },
        args : {
            Action           : required,
            Duration         : optional,
            EndTime          : optional,
            Marker           : optional,
            MaxRecords       : optional,
            SourceIdentifier : optional,
            SourceType       : optional,
            StartTime        : optional,
        },
    },

    DescribeOptionGroupOptions : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeOptionGroupOptions.html',
        defaults : {
            Action : 'DescribeOptionGroupOptions'
        },
        args : {
            Action             : required,
            EngineName         : required,
            MajorEngineVersion : optional,
            Marker             : optional,
            MaxRecords         : optional,
        },
    },

    DescribeOptionGroups : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeOptionGroups.html',
        defaults : {
            Action : 'DescribeOptionGroups'
        },
        args : {
            Action : required,
            EngineName         : optional,
            MajorEngineVersion : optional,
            Marker             : optional,
            MaxRecords         : optional,
            OptionGroupName    : optional,
        },
    },

    DescribeOrderableDBInstanceOptions : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeOrderableDBInstanceOptions.html',
        defaults : {
            Action : 'DescribeOrderableDBInstanceOptions'
        },
        args : {
            Action          : required,
            DBInstanceClass : optional,
            Engine          : required,
            EngineVersion   : optional,
            LicenseModel    : optional,
            Marker          : optional,
            MaxRecords      : optional,
        },
    },

    DescribeReservedDBInstances : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeReservedDBInstances.html',
        defaults : {
            Action : 'DescribeReservedDBInstances'
        },
        args : {
            Action                        : required,
            DBInstanceClass               : optional,
            Duration                      : optional,
            Marker                        : optional,
            MaxRecords                    : optional,
            MultiAZ                       : optional,
            ProductDescription            : optional,
            ReservedDBInstanceId          : optional,
            ReservedDBInstancesOfferingId : optional,
        },
    },

    DescribeReservedDBInstancesOfferings : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeReservedDBInstancesOfferings.html',
        defaults : {
            Action : 'DescribeReservedDBInstancesOfferings'
        },
        args : {
            Action : required,
            DBInstanceClass               : optional,
            Duration                      : optional,
            Marker                        : optional,
            MaxRecords                    : optional,
            MultiAZ                       : optional,
            OfferingType                  : optional,
            ProductDescription            : optional,
            ReservedDBInstancesOfferingId : optional,
        },
    },

    ModifyDBInstance : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_ModifyDBInstance.html',
        defaults : {
            Action : 'ModifyDBInstance'
        },
        args : {
            Action                     : required,
            AllocatedStorage           : optional,
            AllowMajorVersionUpgrade   : optional,
            ApplyImmediately           : optional,
            AutoMinorVersionUpgrade    : optional,
            BackupRetentionPeriod      : optional,
            DBInstanceClass            : optional,
            DBInstanceIdentifier       : required,
            DBParameterGroupName       : optional,
            DBSecurityGroups           : optionalArray,
            EngineVersion              : optional,
            MasterUserPassword         : optional,
            MultiAZ                    : optional,
            OptionGroupName            : optional,
            PreferredBackupWindow      : optional,
            PreferredMaintenanceWindow : optional,
        },
    },

    ModifyDBParameterGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_ModifyDBParameterGroup.html',
        defaults : {
            Action : 'ModifyDBParameterGroup'
        },
        args : {
            Action               : required,
            DBParameterGroupName : required,
            Parameters           : requiredArray,
        },
    },

    ModifyDBSubnetGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_ModifyDBSubnetGroup.html',
        defaults : {
            Action : 'ModifyDBSubnetGroup'
        },
        args : {
            Action                   : required,
            DBSubnetGroupDescription : optional,
            DBSubnetGroupName        : required,
            SubnetIds                : requiredArray,
        },
    },

    ModifyOptionGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_ModifyOptionGroup.html',
        defaults : {
            Action : 'ModifyOptionGroup'
        },
        args : {
            Action           : required,
            ApplyImmediately : optional,
            OptionGroupName  : required,
            OptionsToInclude : optionalArray,
            OptionsToRemove  : optionalArray,
        },
    },

    PurchaseReservedDBInstancesOffering : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_PurchaseReservedDBInstancesOffering.html',
        defaults : {
            Action : 'PurchaseReservedDBInstancesOffering'
        },
        args : {
            Action                        : required,
            DBInstanceCount               : optional,
            ReservedDBInstanceId          : optional,
            ReservedDBInstancesOfferingId : required,
        },
    },

    RebootDBInstance : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_RebootDBInstance.html',
        defaults : {
            Action : 'RebootDBInstance'
        },
        args : {
            Action               : required,
            DBInstanceIdentifier : required,
            ForceFailover        : optional,
        },
    },

    ResetDBParameterGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_ResetDBParameterGroup.html',
        defaults : {
            Action : 'ResetDBParameterGroup'
        },
        args : {
            Action               : required,
            DBParameterGroupName : required,
            Parameters           : optionalArray,
            ResetAllParameters   : optional,
        },
    },

    RestoreDBInstanceFromDBSnapshot : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_RestoreDBInstanceFromDBSnapshot.html',
        defaults : {
            Action : 'RestoreDBInstanceFromDBSnapshot'
        },
        args : {
            Action                  : required,
            AutoMinorVersionUpgrade : optional,
            AvailabilityZone        : optional,
            DBInstanceClass         : optional,
            DBInstanceIdentifier    : required,
            DBName                  : optional,
            DBSnapshotIdentifier    : required,
            DBSubnetGroupName       : optional,
            Engine                  : optional,
            LicenseModel            : optional,
            MultiAZ                 : optional,
            OptionGroupName         : optional,
            Port                    : optional,
        },
    },

    RestoreDBInstanceToPointInTime : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_RestoreDBInstanceToPointInTime.html',
        defaults : {
            Action : 'RestoreDBInstanceToPointInTime'
        },
        args : {
            Action                     : required,
            AutoMinorVersionUpgrade    : optional,
            AvailabilityZone           : optional,
            DBInstanceClass            : optional,
            DBName                     : optional,
            DBSubnetGroupName          : optional,
            Engine                     : optional,
            LicenseModel               : optional,
            MultiAZ                    : optional,
            OptionGroupName            : optional,
            Port                       : optional,
            RestoreTime                : optional,
            SourceDBInstanceIdentifier : required,
            TargetDBInstanceIdentifier : required,
            UseLatestRestorableTime    : optional,
        },
    },

    RevokeDBSecurityGroupIngress : {
        url : 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_RevokeDBSecurityGroupIngress.html',
        defaults : {
            Action : 'RevokeDBSecurityGroupIngress'
        },
        args : {
            Action                  : required,
            CIDRIP                  : optional,
            DBSecurityGroupName     : required,
            EC2SecurityGroupId      : optional,
            EC2SecurityGroupName    : optional,
            EC2SecurityGroupOwnerId : optional,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
