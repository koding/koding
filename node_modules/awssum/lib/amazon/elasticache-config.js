// --------------------------------------------------------------------------------------------------------------------
//
// elasticache-config.js - config for AWS ElastiCache
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    AuthorizeCacheSecurityGroupIngress : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_AuthorizeCacheSecurityGroupIngress.html',
        defaults : {
            Action : 'AuthorizeCacheSecurityGroupIngress'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheSecurityGroupName : {
                required : true,
                type     : 'param',
            },
            EC2SecurityGroupName : {
                required : true,
                type     : 'param',
            },
            EC2SecurityGroupOwnerId : {
                required : true,
                type     : 'param',
            },
        },
    },

    CreateCacheCluster : {
        url : 'http://docs.htmlamazonwebservices.com/AmazonElastiCache/latest/APIReference/API_CreateCacheCluster.html',
        defaults : {
            Action : 'CreateCacheCluster'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            AutoMinorVersionUpgrade : {
                required : false,
                type     : 'param',
            },
            CacheClusterId : {
                required : true,
                type     : 'param',
            },
            CacheNodeType : {
                required : true,
                type     : 'param',
            },
            CacheParameterGroupName : {
                required : false,
                type     : 'param',
            },
            CacheSecurityGroupNames : {
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
            Engine : {
                required : true,
                type     : 'param',
            },
            EngineVersion : {
                required : false,
                type     : 'param',
            },
            NotificationTopicArn : {
                required : false,
                type     : 'param',
            },
            NumCacheNodes : {
                required : true,
                type     : 'param',
            },
            Port : {
                required : false,
                type     : 'param',
            },
            PreferredAvailabilityZone : {
                required : false,
                type     : 'param',
            },
            PreferredMaintenanceWindow : {
                required : false,
                type     : 'param',
            },
        },
    },

    CreateCacheParameterGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_CreateCacheParameterGroup.html',
        defaults : {
            Action : 'CreateCacheParameterGroup'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheParameterGroupFamily : {
                required : true,
                type     : 'param',
            },
            CacheParameterGroupName : {
                required : true,
                type     : 'param',
            },
            Description : {
                required : true,
                type     : 'param',
            },
        },
    },

    CreateCacheSecurityGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_CreateCacheSecurityGroup.html',
        defaults : {
            Action : 'CreateCacheSecurityGroup'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheSecurityGroupName : {
                required : true,
                type     : 'param',
            },
            Description : {
                required : true,
                type     : 'param',
            },
        },
    },

    DeleteCacheCluster : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DeleteCacheCluster.html',
        defaults : {
            Action : 'DeleteCacheCluster'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheClusterId : {
                required : true,
                type     : 'param',
            },
        },
    },

    DeleteCacheParameterGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DeleteCacheParameterGroup.html',
        defaults : {
            Action : 'DeleteCacheParameterGroup'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheParameterGroupName : {
                required : true,
                type     : 'param',
            },
        },
    },

    DeleteCacheSecurityGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DeleteCacheSecurityGroup.html',
        defaults : {
            Action : 'DeleteCacheSecurityGroup'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheSecurityGroupName : {
                required : true,
                type     : 'param',
            },
        },
    },

    DescribeCacheClusters : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DescribeCacheClusters.html',
        defaults : {
            Action : 'DescribeCacheClusters'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheClusterId : {
                required : false,
                type     : 'param',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxRecords : {
                required : false,
                type     : 'param',
            },
            ShowCacheNodeInfo : {
                required : false,
                type     : 'param',
            },
        },
    },

    DescribeCacheParameterGroups : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DescribeCacheParameterGroups.html',
        defaults : {
            Action : 'DescribeCacheParameterGroups'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheParameterGroupName : {
                required : false,
                type     : 'param',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxRecords : {
                required : false,
                type     : 'param',
            },
        },
    },

    DescribeCacheParameters : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DescribeCacheParameters.html',
        defaults : {
            Action : 'DescribeCacheParameters'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheParameterGroupName : {
                required : true,
                type     : 'param',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxRecords : {
                required : false,
                type     : 'param',
            },
            Source : {
                required : false,
                type     : 'param',
            },
        },
    },

    DescribeCacheSecurityGroups : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DescribeCacheSecurityGroups.html',
        defaults : {
            Action : 'DescribeCacheSecurityGroups'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheSecurityGroupName : {
                required : false,
                type     : 'param',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxRecords : {
                required : false,
                type     : 'param',
            },
        },
    },

    DescribeEngineDefaultParameters : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DescribeEngineDefaultParameters.html',
        defaults : {
            Action : 'DescribeEngineDefaultParameters'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheParameterGroupFamily : {
                required : true,
                type     : 'param',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxRecords : {
                required : false,
                type     : 'param',
            },
       },
    },

    DescribeEvents : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DescribeEvents.html',
        defaults : {
            Action : 'DescribeEvents'
        },
        args : {
            Action : {
                required : false,
                type     : 'param',
            },
            Duration : {
                required : false,
                type     : 'param',
            },
            EndTime : {
                required : false,
                type     : 'param',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxRecords : {
                required : false,
                type     : 'param',
            },
            SourceIdentifier : {
                required : false,
                type     : 'param',
            },
            SourceType : {
                required : false,
                type     : 'param',
            },
            StartTime : {
                required : false,
                type     : 'param',
            },
        },
    },

    DescribeReservedCacheNodes : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DescribeReservedCacheNodes.html',
        defaults : {
            Action : 'DescribeReservedCacheNodes'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheNodeType : {
                required : false,
                type     : 'param',
            },
            Duration : {
                required : false,
                type     : 'param',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxRecords : {
                required : false,
                type     : 'param',
            },
            OfferingType : {
                required : false,
                type     : 'param',
            },
            ProductDescription : {
                required : false,
                type     : 'param',
            },
            ReservedCacheNodeId : {
                required : false,
                type     : 'param',
            },
            ReservedCacheNodesOfferingId : {
                required : false,
                type     : 'param',
            },
        },
    },

    DescribeReservedCacheNodesOfferings : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_DescribeReservedCacheNodesOfferings.html',
        defaults : {
            Action : 'DescribeReservedCacheNodesOfferings'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheNodeType : {
                required : false,
                type     : 'param',
            },
            Duration : {
                required : false,
                type     : 'param',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxRecords : {
                required : false,
                type     : 'param',
            },
            OfferingType : {
                required : false,
                type     : 'param',
            },
            ProductDescription : {
                required : false,
                type     : 'param',
            },
            ReservedCacheNodesOfferingId : {
                required : false,
                type     : 'param',
            },
        },
    },

    ModifyCacheCluster : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_ModifyCacheCluster.html',
        defaults : {
            Action : 'ModifyCacheCluster'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            ApplyImmediately : {
                required : false,
                type     : 'param',
            },
            AutoMinorVersionUpgrade : {
                required : false,
                type     : 'param',
            },
            CacheClusterId : {
                required : true,
                type     : 'param',
            },
            CacheNodeIdsToRemove : {
                required : false,
                type     : 'param-array',
                prefix   : 'member',
            },
            CacheParameterGroupName : {
                required : false,
                type     : 'param',
            },
            CacheSecurityGroupNames : {
                required : false,
                type     : 'param-array',
                prefix   : 'member',
            },
            EngineVersion : {
                required : false,
                type     : 'param',
            },
            NotificationTopicArn : {
                required : false,
                type     : 'param',
            },
            NotificationTopicStatus : {
                required : false,
                type     : 'param',
            },
            NumCacheNodes : {
                required : false,
                type     : 'param',
            },
            PreferredMaintenanceWindow : {
                required : false,
                type     : 'param',
            },
        },
    },

    ModifyCacheParameterGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_ModifyCacheParameterGroup.html',
        defaults : {
            Action : 'ModifyCacheParameterGroup'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheParameterGroupName : {
                required : true,
                type     : 'param',
            },
            ParameterNameValues : {
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
        },
    },

    PurchaseReservedCacheNodesOffering : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_PurchaseReservedCacheNodesOffering.html',
        defaults : {
            Action : 'PurchaseReservedCacheNodesOffering'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheNodeCount : {
                required : false,
                type     : 'param',
            },
            ReservedCacheNodeId : {
                required : false,
                type     : 'param',
            },
            ReservedCacheNodesOfferingId : {
                required : true,
                type     : 'param',
            },
        },
    },

    RebootCacheCluster : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_RebootCacheCluster.html',
        defaults : {
            Action : 'RebootCacheCluster'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheClusterId : {
                required : true,
                type     : 'param',
            },
            CacheNodeIdsToReboot : {
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
        },
    },

    ResetCacheParameterGroup : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_ResetCacheParameterGroup.html',
        defaults : {
            Action : 'ResetCacheParameterGroup'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheParameterGroupName : {
                required : true,
                type     : 'param',
            },
            ParameterNameValues : {
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
            ResetAllParameters : {
                required : false,
                type     : 'param',
            },
        },
    },

    RevokeCacheSecurityGroupIngress : {
        url : 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/API_RevokeCacheSecurityGroupIngress.html',
        defaults : {
            Action : 'RevokeCacheSecurityGroupIngress'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CacheSecurityGroupName : {
                required : true,
                type     : 'param',
            },
            EC2SecurityGroupName : {
                required : true,
                type     : 'param',
            },
            EC2SecurityGroupOwnerId : {
                required : true,
                type     : 'param',
            },
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
