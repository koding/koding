// --------------------------------------------------------------------------------------------------------------------
//
// emr-config.js - config for AWS Elastic Map Reduce
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var required      = { required : true,  type : 'param' };
var optional      = { required : false, type : 'param' };
var requiredArray = { required : true,  type : 'param-array', prefix : 'member' };
var optionalArray = { required : false, type : 'param-array', prefix : 'member' };
var requiredData  = { required : true,  type : 'param-data',  prefix : 'member' };
var optionalData  = { required : false, type : 'param-data',  prefix : 'member' };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

   AddInstanceGroups  : {
       url : 'http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_AddInstanceGroups.html',
        defaults : {
            Action : 'AddInstanceGroups',
        },
        args : {
            Action         : required,
            InstanceGroups : requiredData,
            JobFlowId      : required,
        },
    },

    AddJobFlowSteps : {
        url : 'http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_AddJobFlowSteps.html',
        defaults : {
            Action : 'AddJobFlowSteps',
        },
        args : {
            Action    : required,
            JobFlowId : required,
            Steps     : requiredData,
        },
    },

    DescribeJobFlows : {
        url : 'http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_DescribeJobFlows.html',
        defaults : {
            Action : 'DescribeJobFlows',
        },
        args : {
            Action        : required,
            CreatedAfter  : optional,
            CreatedBefore : optional,
            JobFlowIds    : optionalArray,
            JobFlowStates : optionalArray,
        },
    },

    ModifyInstanceGroups : {
        url : 'http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_ModifyInstanceGroups.html',
        defaults : {
            Action : 'ModifyInstanceGroups',
        },
        args : {
            Action         : required,
            InstanceGroups : optionalData,
        },
    },

    RunJobFlow : {
        url : 'http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_RunJobFlow.html',
        defaults : {
            Action : 'RunJobFlow',
        },
        args : {
            Action            : required,
            AdditionalInfo    : optional,
            AmiVersion        : optional,
            BootstrapActions  : optionalData,
            Instances         : requiredData,
            LogUri            : optional,
            Name              : required,
            Steps             : optionalData,
            SupportedProducts : optionalArray,
        },
    },

    SetTerminationProtection : {
        url : 'http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_SetTerminationProtection.html',
        defaults : {
            Action : 'SetTerminationProtection',
        },
        args : {
            Action               : required,
            JobFlowIds           : requiredArray,
            TerminationProtected : required,
        },
    },

    TerminateJobFlows : {
        url : 'http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_TerminateJobFlows.html',
        defaults : {
            Action : 'TerminateJobFlows',
        },
        args : {
            Action     : required,
            JobFlowIds : requiredArray,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
