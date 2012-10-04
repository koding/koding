// --------------------------------------------------------------------------------------------------------------------
//
// cloudwatch-config.js - config for AWS CloudWatch
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var required = {
    required : true,
    type     : 'param',
};

var optional = {
    required : false,
    type     : 'param',
};

var paramDataRequired = {
    // does <Name>.member.N.<whatever>
    required : true,
    type     : 'param-data',
    prefix   : 'member',
};

var paramDataOptional = {
    // does <Name>.member.N.<whatever>
    required : false,
    type     : 'param-data',
    prefix   : 'member',
};

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    DeleteAlarms : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_DeleteAlarms.html',
        defaults : {
            Action : 'DeleteAlarms',
        },
        args : {
            Action     : required,
            AlarmNames : paramDataRequired,
        },
    },

    DescribeAlarmHistory : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_DescribeAlarmHistory.html',
        defaults : {
            Action : 'DescribeAlarmHistory',
        },
        args : {
            Action          : required,
            AlarmName       : optional,
            EndDate         : optional,
            HistoryItemType : optional,
            MaxRecords      : optional,
            NextToken       : optional,
            StartDate       : optional,
        },
    },

    DescribeAlarms : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_DescribeAlarms.html',
        defaults : {
            Action : 'DescribeAlarms',
        },
        args : {
            Action          : required,
            ActionPrefix    : optional,
            AlarmNamePrefix : optional,
            AlarmNames      : paramDataOptional,
            MaxRecords      : optional,
            NextToken       : optional,
            StateValeu      : optional,
        },
    },

    DescribeAlarmsForMetric : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_DescribeAlarmsForMetric.html',
        defaults : {
            Action : 'DescribeAlarmsForMetric',
        },
        args : {
            Action       : required,
            Dimensions   : paramDataOptional,
            MetricName   : required,
            Namespace    : required,
            Period       : optional,
            Statistic    : optional,
            Unit         : optional,
        },
    },

    DisableAlarmActions : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_DisableAlarmActions.html',
        defaults : {
            Action : 'DisableAlarmActions',
        },
        args : {
            Action     : required,
            AlarmNames : paramDataRequired,
        },
    },

    EnableAlarmActions : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_EnableAlarmActions.html',
        defaults : {
            Action : 'EnableAlarmActions',
        },
        args : {
            Action     : required,
            AlarmNames : paramDataRequired,
        },
    },

    GetMetricStatistics : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_GetMetricStatistics.html',
        defaults : {
            Action : 'GetMetricStatistics',
        },
        args : {
            Action     : required,
            Dimensions : paramDataOptional,
            EndTime    : required,
            MetricName : required,
            Namespace  : required,
            Period     : required,
            StartTime  : required,
            Statistics : paramDataRequired,
            Unit       : required,
        },
    },

    ListMetrics : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_ListMetrics.html',
        defaults : {
            Action : 'ListMetrics',
        },
        args : {
            Action     : required,
            Dimensions : paramDataOptional,
            MetricName : optional,
            Namespace  : optional,
            NextToken  : optional,
        },
    },

    PutMetricAlarm : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_PutMetricAlarm.html',
        defaults : {
            Action : 'PutMetricAlarm',
        },
        args : {
            Action                  : required,
            ActionsEnabled          : optional,
            AlarmActions            : paramDataOptional,
            AlarmDescription        : optional,
            AlarmName               : required,
            ComparisonOperator      : required,
            Dimensions              : paramDataOptional,
            EvaluationPeriods       : required,
            InsufficientDataActions : paramDataOptional,
            MetricName              : required,
            Namespace               : required,
            OkActions               : {
                // does <Name>.member.N.<whatever>
                name     : 'OKActions',
                required : false,
                type     : 'param-data',
                prefix   : 'member',
            },
            Period                  : required,
            Statistic               : required,
            Threshold               : required,
            Unit                    : optional,
        },
    },

    PutMetricData : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_PutMetricData.html',
        defaults : {
            Action : 'PutMetricData',
        },
        args : {
            Action     : required,
            // does <Name>.member.<N>.<whatever>
            MetricData : paramDataRequired,
            Namespace  : required,
        },
    },

    SetAlarmState : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_SetAlarmState.html',
        defaults : {
            Action : 'SetAlarmState',
        },
        args : {
            Action          : required,
            AlarmName       : required,
            StateReason     : required,
            StateReasonData : optional,
            StateValue      : required,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
