// --------------------------------------------------------------------------------------------------------------------
//
// beanstalk-config.js - config for AWS Elastic Compute Cloud
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
var optionalArray = { required : false, type : 'param-array', prefix : 'member' };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    CheckDNSAvailability : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CheckDNSAvailability.html',
        defaults : {
            Action : 'CheckDNSAvailability'
        },
        args : {
            Action      : required,
            CNAMEPrefix : required,
        },
    },

    CreateApplication : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateApplication.html',
        defaults : {
            Action : 'CreateApplication'
        },
        args : {
            Action          : required,
            ApplicationName : required,
            Description     : optional,
        },
    },

    CreateApplicationVersion : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateApplicationVersion.html',
        defaults : {
            Action : 'CreateApplicationVersion'
        },
        args : {
            Action                : required,
            ApplicationName       : required,
            AutoCreateApplication : optional,
            Description           : optional,
            SourceBundle          : optional,
            VersionLabel          : required,
        },
    },

    CreateConfigurationTemplate : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateConfigurationTemplate.html',
        defaults : {
            Action : 'CreateConfigurationTemplate'
        },
        args : {
            Action              : required,
            ApplicationName     : required,
            Description         : optional,
            EnvironmentId       : optional,
            OptionSettings      : optionalArray,
            SolutionStackName   : optional,
            SourceConfiguration : optional,
            TemplateName        : required,
        },
    },

    CreateEnvironment : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateEnvironment.html',
        defaults : {
            Action : 'CreateEnvironment'
        },
        args : {
            Action            : required,
            ApplicationName   : required,
            CNAMEPrefix       : optional,
            Description       : optional,
            EnvironmentName   : required,
            OptionSettings    : optionalArray,
            OptionsToRemove   : optionalArray,
            SolutionStackName : optional,
            TemplateName      : optional,
            VersionLabel      : optional,
        },
    },

    CreateStorageLocation : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateStorageLocation.html',
        defaults : {
            Action : 'CreateStorageLocation'
        },
        args : {
            Action              : required,
        },
    },

    DeleteApplication : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DeleteApplication.html',
        defaults : {
            Action : 'DeleteApplication'
        },
        args : {
            Action              : required,
            ApplicationName     : required,
            TerminateEnvByForce : optional,
        },
    },

    DeleteApplicationVersion : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DeleteApplicationVersion.html',
        defaults : {
            Action : 'DeleteApplicationVersion'
        },
        args : {
            Action             : required,
            ApplicationName    : required,
            DeleteSourceBundle : optional,
            VersionLabel       : required,
        },
    },

    DeleteConfigurationTemplate : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DeleteConfigurationTemplate.html',
        defaults : {
            Action : 'DeleteConfigurationTemplate'
        },
        args : {
            Action          : required,
            ApplicationName : required,
            TemplateName    : required,
        },
    },

    DeleteEnvironmentConfiguration : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DeleteEnvironmentConfiguration.html',
        defaults : {
            Action : 'DeleteEnvironmentConfiguration'
        },
        args : {
            Action          : required,
            ApplicationName : required,
            EnvironmentName : required,
        },
    },

    DescribeApplicationVersions : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeApplicationVersions.html',
        defaults : {
            Action : 'DescribeApplicationVersions'
        },
        args : {
            Action          : optional,
            ApplicationName : optional,
            VersionLabels   : optionalArray,
        },
    },

    DescribeApplications : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeApplications.html',
        defaults : {
            Action : 'DescribeApplications'
        },
        args : {
            Action           : required,
            ApplicationNames : optionalArray,
        },
    },

    DescribeConfigurationOptions : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeConfigurationOptions.html',
        defaults : {
            Action : 'DescribeConfigurationOptions'
        },
        args : {
            Action            : required,
            ApplicationName   : optional,
            EnvironmentName   : optional,
            Options           : optionalArray,
            SolutionStackName : optional,
            TemplateName      : optional,
        },
    },

    DescribeConfigurationSettings : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeConfigurationSettings.html',
        defaults : {
            Action : 'DescribeConfigurationSettings'
        },
        args : {
            Action          : required,
            ApplicationName : required,
            EnvironmentName : optional,
            TemplateName    : optional,
        },
    },

    DescribeEnvironmentResources : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeEnvironmentResources.html',
        defaults : {
            Action : 'DescribeEnvironmentResources'
        },
        args : {
            Action          : required,
            EnvironmentId   : optional,
            EnvironmentName : optional,
        },
    },

    DescribeEnvironments : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeEnvironments.html',
        defaults : {
            Action : 'DescribeEnvironments'
        },
        args : {
            Action                : required,
            ApplicationName       : optional,
            EnvironmentIds        : optionalArray,
            EnvironmentNames      : optionalArray,
            IncludeDeleted        : optional,
            IncludedDeletedBackTo : optional,
            VersionLabel          : optional,
        },
    },

    DescribeEvents : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeEvents.html',
        defaults : {
            Action : 'DescribeEvents'
        },
        args : {
            Action          : required,
            ApplicationName : optional,
            EndTime         : optional,
            EnvironmentId   : optional,
            EnvironmentName : optional,
            MaxRecords      : optional,
            NextToken       : optional,
            RequestId       : optional,
            Severity        : optional,
            StartTime       : optional,
            TemplateName    : optional,
            VersionLabel    : optional,
        },
    },

    ListAvailableSolutionStacks : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_ListAvailableSolutionStacks.html',
        defaults : {
            Action : 'ListAvailableSolutionStacks'
        },
        args : {
            Action : required,
        },
    },

    RebuildEnvironment : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_RebuildEnvironment.html',
        defaults : {
            Action : 'RebuildEnvironment'
        },
        args : {
            Action          : required,
            EnvironmentId   : optional,
            EnvironmentName : optional,
        },
    },

    RequestEnvironmentInfo : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_RequestEnvironmentInfo.html',
        defaults : {
            Action : 'RequestEnvironmentInfo'
        },
        args : {
            Action          : required,
            EnvironmentId   : optional,
            EnvironmentName : optional,
            InfoType        : required,
        },
    },

    RestartAppServer : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_RestartAppServer.html',
        defaults : {
            Action : 'RestartAppServer'
        },
        args : {
            Action          : required,
            EnvironmentId   : optional,
            EnvironmentName : optional,
        },
    },

    RetrieveEnvironmentInfo : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_RetrieveEnvironmentInfo.html',
        defaults : {
            Action : 'RetrieveEnvironmentInfo'
        },
        args : {
            Action          : required,
            EnvironmentId   : optional,
            EnvironmentName : optional,
            InfoType        : required,
        },
    },

    SwapEnvironmentCNAMEs : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_SwapEnvironmentCNAMEs.html',
        defaults : {
            Action : 'SwapEnvironmentCNAMEs'
        },
        args : {
            Action                     : required,
            DestinationEnvironmentId   : optional,
            DestinationEnvironmentName : optional,
            SourceEnvironmentId        : optional,
            SourceEnvironmentName      : optional,
        },
    },

    TerminateEnvironment : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_TerminateEnvironment.html',
        defaults : {
            Action : 'TerminateEnvironment'
        },
        args : {
            Action             : required,
            EnvironmentId      : optional,
            EnvironmentName    : optional,
            TerminateResources : optional,
        },
    },

    UpdateApplication : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_UpdateApplication.html',
        defaults : {
            Action : 'UpdateApplication'
        },
        args : {
            Action          : required,
            ApplicationName : required,
            Description     : optional,
        },
    },

    UpdateApplicationVersion : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_UpdateApplicationVersion.html',
        defaults : {
            Action : 'UpdateApplicationVersion'
        },
        args : {
            Action          : required,
            ApplicationName : required,
            Description     : optional,
            VersionLabel    : required,
        },
    },

    UpdateConfigurationTemplate : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_UpdateConfigurationTemplate.html',
        defaults : {
            Action : 'UpdateConfigurationTemplate'
        },
        args : {
            Action          : required,
            Description     : optional,
            EnvironmentId   : optional,
            EnvironmentName : optional,
            OptionSettings  : optionalArray,
            OptionsToRemove : optionalArray,
            TemplateName    : optional,
            VersionLabel    : optional,
        },
    },

    UpdateEnvironment : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_UpdateEnvironment.html',
        defaults : {
            Action : 'UpdateEnvironment'
        },
        args : {
            Action          : required,
            Description     : optional,
            EnvironmentId   : optional,
            EnvironmentName : optional,
            OptionSettings  : optionalArray,
            OptionsToRemove : optionalArray,
            TemplateName    : optional,
            VersionLabel    : optional,
        },
    },

    ValidateConfigurationSettings : {
        url : 'http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_ValidateConfigurationSettings.html',
        defaults : {
            Action : 'ValidateConfigurationSettings'
        },
        args : {
            Action          : required,
            ApplicationName : required,
            EnvironmentName : optional,
            OptionSettings  : requiredArray,
            TemplateName    : optional,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
