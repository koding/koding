// --------------------------------------------------------------------------------------------------------------------
//
// autoscaling-config.js - config for AWS AutoScaling
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
var requiredData  = { required : true,  type : 'param-data',  prefix : 'member' };
var optionalData  = { required : false, type : 'param-data',  prefix : 'member' };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    CreateAutoScalingGroup : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_CreateAutoScalingGroup.html',
        defaults : {
            Action : 'CreateAutoScalingGroup'
        },
        args : {
            Action                  : required,
            AutoScalingGroupName    : required,
            AvailabilityZones       : requiredArray,
            DefaultCooldown         : optional,
            DesiredCapacity         : optional,
            HealthCheckGracePeriod  : optional,
            HealthCheckType         : optional,
            LaunchConfigurationName : required,
            LoadBalancerNames       : optionalArray,
            MaxSize                 : required,
            MinSize                 : required,
            PlacementGroup          : optional,
            Tags                    : optionalData,
            VPCZoneIdentifier       : optional,
        },
    },

    CreateLaunchConfiguration : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_CreateLaunchConfiguration.html',
        defaults : {
            Action : 'CreateLaunchConfiguration'
        },
        args : {
            Action                  : required,
            BlockDeviceMappings     : optionalData,
            IamInstanceProfile      : optional,
            ImageId                 : required,
            InstanceMonitoring      : optional,
            InstanceType            : required,
            KernelId                : optional,
            KeyName                 : optional,
            LaunchConfigurationName : required,
            RamdiskId               : optional,
            SecurityGroups          : optionalArray,
            SpotPrice               : optional,
            UserData                : optional,
        },
    },

    CreateOrUpdateTags : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_CreateOrUpdateTags.html',
        defaults : {
            Action : 'CreateOrUpdateTags'
        },
        args : {
            Action : required,
            Tags   : requiredData,
        },
    },

    DeleteAutoScalingGroup : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeleteAutoScalingGroup.html',
        defaults : {
            Action : 'DeleteAutoScalingGroup'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : required,
            ForceDelete          : optional,
        },
    },

    DeleteLaunchConfiguration : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeleteLaunchConfiguration.html',
        defaults : {
            Action : 'DeleteLaunchConfiguration'
        },
        args : {
            Action                  : required,
            LaunchConfigurationName : required,
        },
    },

    DeleteNotificationConfiguration : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeleteNotificationConfiguration.html',
        defaults : {
            Action : 'DeleteNotificationConfiguration'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : required,
            TopicARN             : required,
        },
    },

    DeletePolicy : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeletePolicy.html',
        defaults : {
            Action : 'DeletePolicy'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : optional,
            PolicyName           : required,
        },
    },

    DeleteScheduledAction : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeleteScheduledAction.html',
        defaults : {
            Action : 'DeleteScheduledAction'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : optional,
            ScheduledActionName  : required,
        },
    },

    DeleteTags : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeleteTags.html',
        defaults : {
            Action : 'DeleteTags'
        },
        args : {
            Action : required,
            Tags   : requiredData,
        },
    },

    DescribeAdjustmentTypes : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeAdjustmentTypes.html',
        defaults : {
            Action : 'DescribeAdjustmentTypes'
        },
        args : {
            Action : required,
        },
    },

    DescribeAutoScalingGroups : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeAutoScalingGroups.html',
        defaults : {
            Action : 'DescribeAutoScalingGroups'
        },
        args : {
            Action                : required,
            AutoScalingGroupNames : optionalArray,
            MaxRecords            : optional,
            NextToken             : optional,
        },
    },

    DescribeAutoScalingInstances : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeAutoScalingInstances.html',
        defaults : {
            Action : 'DescribeAutoScalingInstances'
        },
        args : {
            Action      : required,
            InstanceIds : optionalArray,
            MaxRecords  : optional,
            NextToken   : optional,
        },
    },

    DescribeAutoScalingNotificationTypes : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeAutoScalingNotificationTypes.html',
        defaults : {
            Action : 'DescribeAutoScalingNotificationTypes'
        },
        args : {
            Action : required,
        },
    },

    DescribeLaunchConfigurations : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeLaunchConfigurations.html',
        defaults : {
            Action : 'DescribeLaunchConfigurations'
        },
        args : {
            Action                   : required,
            LaunchConfigurationNames : optionalArray,
            MaxRecords               : optional,
            NextToken                : optional,
        },
    },

    DescribeMetricCollectionTypes : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeMetricCollectionTypes.html',
        defaults : {
            Action : 'DescribeMetricCollectionTypes'
        },
        args : {
            Action : required,
        },
    },

    DescribeNotificationConfigurations : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeNotificationConfigurations.html',
        defaults : {
            Action : 'DescribeNotificationConfigurations'
        },
        args : {
            Action                : required,
            AutoScalingGroupNames : optionalArray,
            MaxRecords            : optional,
            NextToken             : optional,
        },
    },

    DescribePolicies : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribePolicies.html',
        defaults : {
            Action : 'DescribePolicies'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : optional,
            MaxRecords           : optional,
            NextToken            : optional,
            PolicyNames          : optionalArray,
        },
    },

    DescribeScalingActivities : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeScalingActivities.html',
        defaults : {
            Action : 'DescribeScalingActivities'
        },
        args : {
            Action               : required,
            ActivityIds          : optionalArray,
            AutoScalingGroupName : optional,
            MaxRecords           : optional,
            NextToken            : optional,
        },
    },

    DescribeScalingProcessTypes : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeScalingProcessTypes.html',
        defaults : {
            Action : 'DescribeScalingProcessTypes'
        },
        args : {
            Action : required,
        },
    },

    DescribeScheduledActions : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeScheduledActions.html',
        defaults : {
            Action : 'DescribeScheduledActions'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : optional,
            EndTime              : optional,
            MaxRecords           : optional,
            NextToken            : optional,
            ScheduledActionNames : optionalArray,
            StartTime            : optional,
        },
    },

    DescribeTags : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeTags.html',
        defaults : {
            Action : 'DescribeTags'
        },
        args : {
            Action     : required,
            Filters    : optionalData,
            MaxRecords : optional,
            NextToken  : optional,
        },
    },

    DisableMetricsCollection : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DisableMetricsCollection.html',
        defaults : {
            Action : 'DisableMetricsCollection'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : required,
            Metrics              : optionalArray,
        },
    },

    EnableMetricsCollection : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_EnableMetricsCollection.html',
        defaults : {
            Action : 'EnableMetricsCollection'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : required,
            Granularity          : required,
            Metrics              : optionalArray,
        },
    },

    ExecutePolicy : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_ExecutePolicy.html',
        defaults : {
            Action : 'ExecutePolicy'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : optional,
            HonorCooldown        : optional,
            PolicyName           : required,
        },
    },

    PutNotificationConfiguration : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_PutNotificationConfiguration.html',
        defaults : {
            Action : 'PutNotificationConfiguration'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : required,
            NotificationTypes    : requiredArray,
            TopicARN             : required,
        },
    },

    PutScalingPolicy : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_PutScalingPolicy.html',
        defaults : {
            Action : 'PutScalingPolicy'
        },
        args : {
            Action               : required,
            AdjustmentType       : required,
            AutoScalingGroupName : required,
            Cooldown             : optional,
            MinAdjustmentStep    : optional,
            PolicyName           : required,
            ScalingAdjustment    : required,
        },
    },

    PutScheduledUpdateGroupAction : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_PutScheduledUpdateGroupAction.html',
        defaults : {
            Action : 'PutScheduledUpdateGroupAction'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : required,
            DesiredCapacity      : optional,
            EndTime              : optional,
            MaxSize              : optional,
            MinSize              : optional,
            Recurrence           : optional,
            ScheduledActionName  : required,
            StartTime            : optional,
            Time                 : optional,
        },
    },

    ResumeProcesses : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_ResumeProcesses.html',
        defaults : {
            Action : 'ResumeProcesses'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : required,
            ScalingProcesses     : optionalArray,
        },
    },

    SetDesiredCapacity : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_SetDesiredCapacity.html',
        defaults : {
            Action : 'SetDesiredCapacity'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : required,
            DesiredCapacity      : required,
            HonorCooldown        : optional,
        },
    },

    SetInstanceHealth : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_SetInstanceHealth.html',
        defaults : {
            Action : 'SetInstanceHealth'
        },
        args : {
            Action                   : required,
            HealthStatus             : required,
            InstanceId               : required,
            ShouldRespectGracePeriod : optional,
        },
    },

    SuspendProcesses : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_SuspendProcesses.html',
        defaults : {
            Action : 'SuspendProcesses'
        },
        args : {
            Action               : required,
            AutoScalingGroupName : required,
            ScalingProcesses     : optionalArray,
        },
    },

    TerminateInstanceInAutoScalingGroup : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_SuspendProcesses.html',
        defaults : {
            Action : 'TerminateInstanceInAutoScalingGroup'
        },
        args : {
            Action                         : required,
            InstanceId                     : required,
            ShouldDecrementDesiredCapacity : required,
        },
    },

    UpdateAutoScalingGroup : {
        url : 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_UpdateAutoScalingGroup.html',
        defaults : {
            Action : 'UpdateAutoScalingGroup'
        },
        args : {
            Action                  : required,
            AutoScalingGroupName    : required,
            AvailabilityZones       : optionalArray,
            DefaultCooldown         : optional,
            DesiredCapacity         : optional,
            HealthCheckGracePeriod  : optional,
            HealthCheckType         : optional,
            LaunchConfigurationName : optional,
            MaxSize                 : optional,
            MinSize                 : optional,
            PlacementGroup          : optional,
            VPCZoneIdentifier       : optional,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
