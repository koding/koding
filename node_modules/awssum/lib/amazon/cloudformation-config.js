// --------------------------------------------------------------------------------------------------------------------
//
// cloudformation-config.js - config for AWS CloudFormation
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var required      = { required : true,  type : 'param'                          };
var optional      = { required : false, type : 'param'                          };
var requiredArray = { required : true,  type : 'param-array', prefix : 'member' };
var optionalArray = { required : false, type : 'param-array', prefix : 'member' };
var requiredData  = { required : true,  type : 'param-data',  prefix : 'member' };
var optionalData  = { required : false, type : 'param-data',  prefix : 'member' };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    CreateStack : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_CreateStack.html',
        defaults : {
            Action : 'CreateStack'
        },
        args : {
            Action           : required,
            Capabilities     : optionalArray,
            DisableRollback  : optional,
            NotificationARNs : optionalArray,
            Parameters       : optionalData,
            StackName        : required,
            Tags             : optionalData,
            TemplateBody     : optional,
            TemplateURL      : optional,
            TimeoutInMinutes : optional,
        },
    },

    DeleteStack : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DeleteStack.html',
        defaults : {
            Action : 'DeleteStack'
        },
        args : {
            Action    : required,
            StackName : required,
        },
    },

    DescribeStackEvents : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DescribeStackEvents.html',
        defaults : {
            Action : 'DescribeStackEvents'
        },
        args : {
            Action    : required,
            NextToken : optional,
            StackName : optional,
        },
    },

    DescribeStackResource : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DescribeStackResource.html',
        defaults : {
            Action : 'DescribeStackResource'
        },
        args : {
            Action            : required,
            LogicalResourceId : required,
            StackName         : required,
        },
    },

    DescribeStackResources : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DescribeStackResources.html',
        defaults : {
            Action : 'DescribeStackResources'
        },
        args : {
            Action             : required,
            LogicalResourceId  : optional,
            PhysicalResourceId : optional,
            StackName          : optional,
        },
    },

    DescribeStacks : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DescribeStacks.html',
        defaults : {
            Action : 'DescribeStacks'
        },
        args : {
            Action    : required,
            StackName : optional,
        },
    },

    EstimateTemplateCost : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_EstimateTemplateCost.html',
        defaults : {
            Action : 'EstimateTemplateCost'
        },
        args : {
            Action       : required,
            Parameters   : optionalData,
            TemplateBody : optional,
            TemplateURL  : optional,
        },
    },

    GetTemplate : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_GetTemplate.html',
        defaults : {
            Action : 'GetTemplate'
        },
        args : {
            Action    : required,
            StackName : required,
        },
    },

    ListStackResources : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_ListStackResources.html',
        defaults : {
            Action : 'ListStackResources'
        },
        args : {
            Action    : required,
            NextToken : optional,
            StackName : required,
        },
    },

    ListStacks : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_ListStacks.html',
        defaults : {
            Action : 'ListStacks'
        },
        args : {
            Action            : required,
            NextToken         : optional,
            StackStatusFilter : optionalArray,
        },
    },

    UpdateStack : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_UpdateStack.html',
        defaults : {
            Action : 'UpdateStack'
        },
        args : {
            Action       : required,
            Capabilities : optionalArray,
            Parameters   : optionalData,
            StackName    : required,
            TemplateBody : optional,
            TemplateURL  : optional,
        },
    },

    ValidateTemplate : {
        url : 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_ValidateTemplate.html',
        defaults : {
            Action : 'ValidateTemplate'
        },
        args : {
            Action       : required,
            TemplateBody : optional,
            TemplateURL  : optional,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
