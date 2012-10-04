// --------------------------------------------------------------------------------------------------------------------
//
// swf-config.js - config for AWS Simple Workflow Service
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// built-ins
var querystring = require('querystring');

// dependencies
var _ = require('underscore');

// --------------------------------------------------------------------------------------------------------------------
// bodies

function bodyJson(options, args) {
    return JSON.stringify(options.json);
}

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    CountClosedWorkflowExecutions : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_CountClosedWorkflowExecutions.html',
        defaults : {
            'Target' : 'CountClosedWorkflowExecutions',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'CloseStatusFilter' : {
                'name'     : 'closeStatusFilter',
                'required' : false,
                'type'     : 'json',
            },
            'CloseTimeFilter' : {
                'name'     : 'closeTimeFilter',
                'required' : false,
                'type'     : 'json',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'ExecutionFilter' : {
                'name'     : 'executionFilter',
                'required' : false,
                'type'     : 'json',
            },
            'StartTimeFilter' : {
                'name'     : 'startTimeFilter',
                'required' : false,
                'type'     : 'json',
            },
            'TagFilter' : {
                'name'     : 'tagFilter',
                'required' : false,
                'type'     : 'json',
            },
            'TypeFilter' : {
                'name'     : 'typeFilter',
                'required' : false,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    CountOpenWorkflowExecutions : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_CountOpenWorkflowExecutions.html',
        defaults : {
            'Target' : 'CountOpenWorkflowExecutions',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'ExecutionFilter' : {
                'name'     : 'executionFilter',
                'required' : false,
                'type'     : 'json',
            },
            'StartTimeFilter' : {
                'name'     : 'startTimeFilter',
                'required' : true,
                'type'     : 'json',
            },
            'TagFilter' : {
                'name'     : 'tagFilter',
                'required' : false,
                'type'     : 'json',
            },
            'TypeFilter' : {
                'name'     : 'typeFilter',
                'required' : false,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    CountPendingActivityTasks : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_CountPendingActivityTasks.html',
        defaults : {
            'Target' : 'CountPendingActivityTasks',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'TaskList' : {
                'name'     : 'taskList',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    CountPendingDecisionTasks : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_CountPendingDecisionTasks.html',
        defaults : {
            'Target' : 'CountPendingDecisionTasks',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'TaskList' : {
                'name'     : 'taskList',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    DeprecateActivityType : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_DeprecateActivityType.html',
        // request
        defaults : {
            'Target' : 'DeprecateActivityType',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'ActivityType' : {
                'name'     : 'activityType',
                'required' : true,
                'type'     : 'json',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    DeprecateDomain : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_DeprecateDomain.html',
        // request
        defaults : {
            'Target' : 'DeprecateDomain',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    DeprecateWorkflowType : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_DeprecateWorkflowType.html',
        // request
        defaults : {
            'Target' : 'DeprecateWorkflowType',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'WorkflowType' : {
                'name'     : 'workflowType',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    DescribeActivityType : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_DescribeActivityType.html',
        // request
        defaults : {
            'Target' : 'DescribeActivityType',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'ActivityType' : {
                'name'     : 'activityType',
                'required' : true,
                'type'     : 'json',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    DescribeDomain : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_DescribeDomain.html',
        // request
        defaults : {
            'Target' : 'DescribeDomain',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Name' : {
                'name'     : 'name',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    DescribeWorkflowExecution : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_DescribeWorkflowExecution.html',
        // request
        defaults : {
            'Target' : 'DescribeWorkflowExecution',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'Execution' : {
                'name'     : 'execution',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    DescribeWorkflowType : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_DescribeWorkflowType.html',
        // request
        defaults : {
            'Target' : 'DescribeWorkflowType',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'WorkflowType' : {
                'name'     : 'workflowType',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    GetWorkflowExecutionHistory : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_GetWorkflowExecutionHistory.html',
        // request
        defaults : {
            'Target' : 'GetWorkflowExecutionHistory',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'Execution' : {
                'name'     : 'execution',
                'required' : true,
                'type'     : 'json',
            },
            'MaximumPageSize' : {
                'name'     : 'maximumPageSize',
                'required' : false,
                'type'     : 'json',
            },
            'NextPageToken' : {
                'name'     : 'nextPageToken',
                'required' : false,
                'type'     : 'json',
            },
            'ReverseOrder' : {
                'name'     : 'reverseOrder',
                'required' : false,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    ListActivityTypes : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_ListActivityTypes.html',
        // request
        defaults : {
            'Target' : 'ListActivityTypes',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'MaximumPageSize' : {
                'name'     : 'maximumPageSize',
                'required' : false,
                'type'     : 'json',
            },
            'Name' : {
                'name'     : 'name',
                'required' : false,
                'type'     : 'json',
            },
            'NextPageToken' : {
                'name'     : 'nextPageToken',
                'required' : false,
                'type'     : 'json',
            },
            'RegistrationStatus' : {
                'name'     : 'registrationStatus',
                'required' : true,
                'type'     : 'json',
            },
            'ReverseOrder' : {
                'name'     : 'reverseOrder',
                'required' : false,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    ListClosedWorkflowExecutions : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_ListClosedWorkflowExecutions.html',
        // request
        defaults : {
            'Target' : 'ListClosedWorkflowExecutions',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'CloseStatusFilter' : {
                'name'     : 'closeStatusFilter',
                'required' : false,
                'type'     : 'json',
            },
            'CloseTimeFilter' : {
                'name'     : 'closeTimeFilter',
                'required' : false,
                'type'     : 'json',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'ExecutionFilter' : {
                'name'     : 'executionFilter',
                'required' : false,
                'type'     : 'json',
            },
            'MaximumPageSize' : {
                'name'     : 'maximumPageSize',
                'required' : false,
                'type'     : 'json',
            },
            'NextPageToken' : {
                'name'     : 'nextPageToken',
                'required' : false,
                'type'     : 'json',
            },
            'ReverseOrder' : {
                'name'     : 'reverseOrder',
                'required' : false,
                'type'     : 'json',
            },
            'StartTimeFilter' : {
                'name'     : 'startTimeFilter',
                'required' : true,
                'type'     : 'json',
            },
            'TagFilter' : {
                'name'     : 'tagFilter',
                'required' : false,
                'type'     : 'json',
            },
            'TypeFilter' : {
                'name'     : 'typeFilter',
                'required' : false,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    ListDomains : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_ListDomains.html',
        // request
        defaults : {
            'Target' : 'ListDomains',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'MaximumPageSize' : {
                'name'     : 'maximumPageSize',
                'required' : false,
                'type'     : 'json',
            },
            'NextPageToken' : {
                'name'     : 'nextPageToken',
                'required' : false,
                'type'     : 'json',
            },
            'RegistrationStatus' : {
                'name'     : 'registrationStatus',
                'required' : true,
                'type'     : 'json',
            },
            'ReverseOrder' : {
                'name'     : 'reverseOrder',
                'required' : false,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    ListOpenWorkflowExecutions : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_ListOpenWorkflowExecutions.html',
        // request
        defaults : {
            'Target' : 'ListOpenWorkflowExecutions',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'ExecutionFilter' : {
                'name'     : 'executionFilter',
                'required' : false,
                'type'     : 'json',
            },
            'MaximumPageSize' : {
                'name'     : 'maximumPageSize',
                'required' : false,
                'type'     : 'json',
            },
            'NextPageToken' : {
                'name'     : 'nextPageToken',
                'required' : false,
                'type'     : 'json',
            },
            'ReverseOrder' : {
                'name'     : 'reverseOrder',
                'required' : false,
                'type'     : 'json',
            },
            'StartTimeFilter' : {
                'name'     : 'startTimeFilter',
                'required' : true,
                'type'     : 'json',
            },
            'TagFilter' : {
                'name'     : 'tagFilter',
                'required' : false,
                'type'     : 'json',
            },
            'TypeFilter' : {
                'name'     : 'typeFilter',
                'required' : false,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    ListWorkflowTypes : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_ListWorkflowTypes.html',
        // request
        defaults : {
            'Target' : 'ListWorkflowTypes',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'MaximumPageSize' : {
                'name'     : 'maximumPageSize',
                'required' : false,
                'type'     : 'json',
            },
            'Name' : {
                'name'     : 'name',
                'required' : false,
                'type'     : 'json',
            },
            'NextPageToken' : {
                'name'     : 'nextPageToken',
                'required' : false,
                'type'     : 'json',
            },
            'RegistrationStatus' : {
                'name'     : 'registrationStatus',
                'required' : false,
                'type'     : 'json',
            },
            'ReverseOrder' : {
                'name'     : 'reverseOrder',
                'required' : false,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    PollForActivityTask : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_PollForActivityTask.html',
        // request
        defaults : {
            'Target' : 'PollForActivityTask',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'Identity' : {
                'name'     : 'identity',
                'required' : false,
                'type'     : 'json',
            },
            'TaskList' : {
                'name'     : 'taskList',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    PollForDecisionTask : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_PollForDecisionTask.html',
        // request
        defaults : {
            'Target' : 'PollForDecisionTask',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'Identity' : {
                'name'     : 'identity',
                'required' : false,
                'type'     : 'json',
            },
            'MaximumPageSize' : {
                'name'     : 'maximumPageSize',
                'required' : false,
                'type'     : 'json',
            },
            'NextPageToken' : {
                'name'     : 'nextPageToken',
                'required' : false,
                'type'     : 'json',
            },
            'ReverseOrder' : {
                'name'     : 'reverseOrder',
                'required' : false,
                'type'     : 'json',
            },
            'TaskList' : {
                'name'     : 'taskList',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    RecordActivityTaskHeartbeat : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_RecordActivityTaskHeartbeat.html',
        // request
        defaults : {
            'Target' : 'RecordActivityTaskHeartbeat',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Details' : {
                'name'     : 'details',
                'required' : false,
                'type'     : 'json',
            },
            'TaskToken' : {
                'name'     : 'taskToken',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    RegisterActivityType : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_RegisterActivityType.html',
        // request
        defaults : {
            'Target' : 'RegisterActivityType',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'DefaultTaskHeartbeatTimeout' : {
                'name'     : 'defaultTaskHeartbeatTimeout',
                'required' : false,
                'type'     : 'json',
            },
            'DefaultTaskList' : {
                'name'     : 'defaultTaskList',
                'required' : false,
                'type'     : 'json',
            },
            'DefaultTaskScheduleToCloseTimeout' : {
                'name'     : 'defaultTaskScheduleToCloseTimeout',
                'required' : false,
                'type'     : 'json',
            },
            'DefaultTaskScheduleToStartTimeout' : {
                'name'     : 'defaultTaskScheduleToStartTimeout',
                'required' : false,
                'type'     : 'json',
            },
            'DefaultTaskStartToCloseTimeout' : {
                'name'     : 'defaultTaskStartToCloseTimeout',
                'required' : false,
                'type'     : 'json',
            },
            'Description' : {
                'name'     : 'description',
                'required' : false,
                'type'     : 'json',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'Name' : {
                'name'     : 'name',
                'required' : true,
                'type'     : 'json',
            },
            'Version' : {
                'name'     : 'version',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    RegisterDomain : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_RegisterDomain.html',
        // request
        defaults : {
            'Target' : 'RegisterDomain',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Description' : {
                'name'     : 'description',
                'required' : false,
                'type'     : 'json',
            },
            'Name' : {
                'name'     : 'name',
                'required' : true,
                'type'     : 'json',
            },
            'WorkflowExecutionRetentionPeriodInDays' : {
                'name'     : 'workflowExecutionRetentionPeriodInDays',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    RegisterWorkflowType : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_RegisterWorkflowType.html',
        // request
        defaults : {
            'Target' : 'RegisterWorkflowType',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'DefaultChildPolicy' : {
                'name'     : 'defaultChildPolicy',
                'required' : false,
                'type'     : 'json',
            },
            'DefaultExecutionStartToCloseTimeout' : {
                'name'     : 'defaultExecutionStartToCloseTimeout',
                'required' : false,
                'type'     : 'json',
            },
            'DefaultTaskList' : {
                'name'     : 'defaultTaskList',
                'required' : false,
                'type'     : 'json',
            },
            'DefaultTaskStartToCloseTimeout' : {
                'name'     : 'defaultTaskStartToCloseTimeout',
                'required' : false,
                'type'     : 'json',
            },
            'Description' : {
                'name'     : 'description',
                'required' : false,
                'type'     : 'json',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'Name' : {
                'name'     : 'name',
                'required' : true,
                'type'     : 'json',
            },
            'Version' : {
                'name'     : 'version',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    RequestCancelWorkflowExecution : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_RequestCancelWorkflowExecution.html',
        // request
        defaults : {
            'Target' : 'RequestCancelWorkflowExecution',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'RunId' : {
                'name'     : 'runId',
                'required' : false,
                'type'     : 'json',
            },
            'WorkflowId' : {
                'name'     : 'workflowId',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    RespondActivityTaskCanceled : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_RespondActivityTaskCanceled.html',
        // request
        defaults : {
            'Target' : 'RespondActivityTaskCanceled',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Details' : {
                'name'     : 'details',
                'required' : false,
                'type'     : 'json',
            },
            'TaskToken' : {
                'name'     : 'taskToken',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    RespondActivityTaskCompleted : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_RespondActivityTaskCompleted.html',
        // request
        defaults : {
            'Target' : 'RespondActivityTaskCompleted',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Result' : {
                'name'     : 'result',
                'required' : false,
                'type'     : 'json',
            },
            'TaskToken' : {
                'name'     : 'taskToken',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    RespondActivityTaskFailed : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_RespondActivityTaskFailed.html',
        // request
        defaults : {
            'Target' : 'RespondActivityTaskFailed',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Details' : {
                'name'     : 'details',
                'required' : false,
                'type'     : 'json',
            },
            'Reason' : {
                'name'     : 'reason',
                'required' : false,
                'type'     : 'json',
            },
            'TaskToken' : {
                'name'     : 'taskToken',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    RespondDecisionTaskCompleted : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_RespondDecisionTaskCompleted.html',
        // request
        defaults : {
            'Target' : 'RespondDecisionTaskCompleted',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Decisions' : {
                'name'     : 'decisions',
                'required' : false,
                'type'     : 'json',
            },
            'ExecutionContext' : {
                'name'     : 'executionContext',
                'required' : false,
                'type'     : 'json',
            },
            'TaskToken' : {
                'name'     : 'taskToken',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    SignalWorkflowExecution : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_SignalWorkflowExecution.html',
        // request
        defaults : {
            'Target' : 'SignalWorkflowExecution',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'Input' : {
                'name'     : 'input',
                'required' : false,
                'type'     : 'json',
            },
            'RunId' : {
                'name'     : 'runId',
                'required' : false,
                'type'     : 'json',
            },
            'SignalName' : {
                'name'     : 'signalName',
                'required' : true,
                'type'     : 'json',
            },
            'WorkflowId' : {
                'name'     : 'workflowId',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
        // response
        extractBody : 'none',
    },

    StartWorkflowExecution : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_StartWorkflowExecution.html',
        // request
        defaults : {
            'Target' : 'StartWorkflowExecution',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'ChildPolicy' : {
                'name'     : 'childPolicy',
                'required' : false,
                'type'     : 'json',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'ExecutionStartToCloseTimeout' : {
                'name'     : 'executionStartToCloseTimeout',
                'required' : false,
                'type'     : 'json',
            },
            'Input' : {
                'name'     : 'input',
                'required' : false,
                'type'     : 'json',
            },
            'TagList' : {
                'name'     : 'tagList',
                'required' : false,
                'type'     : 'json',
            },
            'TaskList' : {
                'name'     : 'taskList',
                'required' : false,
                'type'     : 'json',
            },
            'TaskStartToCloseTimeout' : {
                'name'     : 'taskStartToCloseTimeout',
                'required' : false,
                'type'     : 'json',
            },
            'WorkflowId' : {
                'name'     : 'workflowId',
                'required' : true,
                'type'     : 'json',
            },
            'WorkflowType' : {
                'name'     : 'workflowType',
                'required' : true,
                'type'     : 'json',
            },
        },
        body : bodyJson,
    },

    TerminateWorkflowExecution : {
        url : 'http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_TerminateWorkflowExecution.html',
        // request
        defaults : {
            'Target' : 'TerminateWorkflowExecution',
        },
        args : {
            'Target' : {
                'required' : true,
                'type'     : 'special',
            },
            'ChildPolicy' : {
                'name'     : 'childPolicy',
                'required' : false,
                'type'     : 'json',
            },
            'Details' : {
                'name'     : 'details',
                'required' : false,
                'type'     : 'json',
            },
            'Domain' : {
                'name'     : 'domain',
                'required' : true,
                'type'     : 'json',
            },
            'Reason' : {
                'name'     : 'reason',
                'required' : false,
                'type'     : 'json',
            },
            'RunId' : {
                'name'     : 'runId',
                'required' : false,
                'type'     : 'json',
            },
            'WorkflowId' : {
                'name'     : 'workflowId',
                'required' : true,
                'type'     : 'json',
            },
        },
        // response
        extractBody : 'none',
    },

};
