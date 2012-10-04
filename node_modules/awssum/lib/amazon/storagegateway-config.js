// --------------------------------------------------------------------------------------------------------------------
//
// storagegateway-config.js - config for AWS Storage Gateway
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var _ = require('underscore');

// --------------------------------------------------------------------------------------------------------------------

function bodyJson(options, args) {
    var self = this;
    var data = _.extend({}, args);
    delete data.Target;
    return JSON.stringify(data);
}

// --------------------------------------------------------------------------------------------------------------------

var target        = { required : true,  type : 'special' };
var requiredJson  = { required : true,  type : 'json'  };
var optionalJson  = { required : false, type : 'json'  };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    ActivateGateway : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_ActivateGateway.html',
        defaults : {
            Target : 'ActivateGateway',
        },
        args : {
            Target          : target,
            ActivationKey   : requiredJson,
            GatewayName     : requiredJson,
            GatewayRegion   : requiredJson,
            GatewayTimezone : requiredJson,
        },
        body : bodyJson,
    },

    AddWorkingStorage : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_AddWorkingStorage.html',
        defaults : {
            Target : 'AddWorkingStorage',
        },
        args : {
            Target     : target,
            DiskIds    : requiredJson,
            GatewayARN : requiredJson,
        },
        body : bodyJson,
    },

    CreateSnapshot : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_CreateSnapshot.html',
        defaults : {
            Target : 'CreateSnapshot',
        },
        args : {
            Target              : target,
            SnapshotDescription : requiredJson,
            VolumeARN           : requiredJson,
        },
        body : bodyJson,
    },

    CreateStorediSCSIVolume : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_CreateStorediSCSIVolume.html',
        defaults : {
            Target : 'CreateStorediSCSIVolume',
        },
        args : {
            Target               : target,
            DiskId               : requiredJson,
            GatewayARN           : requiredJson,
            NetworkInterfaceId   : requiredJson,
            PreserveExistingData : requiredJson,
            SnapshotId           : optionalJson,
            TargetName           : requiredJson,
        },
        body : bodyJson,
    },

    DeleteBandwidthRateLimit : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DeleteBandwidthRateLimit.html',
        defaults : {
            Target : 'DeleteBandwidthRateLimit',
        },
        args : {
            Target        : target,
            BandwidthType : requiredJson,
            GatewayARN    : requiredJson,
        },
        body : bodyJson,
    },

    DeleteChapCredentials : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DeleteChapCredentials.html',
        defaults : {
            Target : 'DeleteChapCredentials',
        },
        args : {
            Target        : target,
            InitiatorName : requiredJson,
            TargetARN     : requiredJson,
        },
        body : bodyJson,
    },

    DeleteGateway : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DeleteGateway.html',
        defaults : {
            Target : 'DeleteGateway',
        },
        args : {
            Target     : target,
            GatewayARN : requiredJson,
        },
        body : bodyJson,
    },

    DeleteVolume : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DeleteVolume.html',
        defaults : {
            Target : 'DeleteVolume',
        },
        args : {
            Target    : target,
            VolumeARN : requiredJson,
        },
        body : bodyJson,
    },

    DescribeBandwidthRateLimit : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DescribeBandwidthRateLimit.html',
        defaults : {
            Target : 'DescribeBandwidthRateLimit',
        },
        args : {
            Target     : target,
            GatewayARN : requiredJson,
        },
        body : bodyJson,
    },

    DescribeChapCredentials : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DescribeChapCredentials.html',
        defaults : {
            Target : 'DescribeChapCredentials',
        },
        args : {
            Target    : target,
            TargetARN : requiredJson,
        },
        body : bodyJson,
    },

    DescribeGatewayInformation : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DescribeGatewayInformation.html',
        defaults : {
            Target : 'DescribeGatewayInformation',
        },
        args : {
            Target     : target,
            GatewayARN : requiredJson,
        },
        body : bodyJson,
    },

    DescribeMaintenanceStartTime : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DescribeMaintenanceStartTime.html',
        defaults : {
            Target : 'DescribeMaintenanceStartTime',
        },
        args : {
            Target     : target,
            GatewayARN : requiredJson,
        },
        body : bodyJson,
    },

    DescribeSnapshotSchedule : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DescribeSnapshotSchedule.html',
        defaults : {
            Target : 'DescribeSnapshotSchedule',
        },
        args : {
            Target    : target,
            VolumeARN : requiredJson,
        },
        body : bodyJson,
    },

    DescribeStorediSCSIVolumes : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DescribeStorediSCSIVolumes.html',
        defaults : {
            Target : 'DescribeStorediSCSIVolumes',
        },
        args : {
            Target     : target,
            VolumeARNs : requiredJson,
        },
        body : bodyJson,
    },

    DescribeWorkingStorage : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_DescribeWorkingStorage.html',
        defaults : {
            Target : 'DescribeWorkingStorage',
        },
        args : {
            Target     : target,
            GatewayARN : requiredJson,
        },
        body : bodyJson,
    },

    ListGateways : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_ListGateways.html',
        defaults : {
            Target : 'ListGateways',
        },
        args : {
            Target : target,
            Limit  : optionalJson,
            Marker : optionalJson,
        },
        body : bodyJson,
    },

    ListLocalDisks : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_ListLocalDisks.html',
        defaults : {
            Target : 'ListLocalDisks',
        },
        args : {
            Target     : target,
            GatewayARN : requiredJson,
        },
        body : bodyJson,
    },

    ListVolumes : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_ListVolumes.html',
        defaults : {
            Target : 'ListVolumes',
        },
        args : {
            Target     : target,
            GatewayARN : requiredJson,
            Limit      : optionalJson,
            Marker     : optionalJson,
        },
        body : bodyJson,
    },

    ShutdownGateway : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_ShutdownGateway.html',
        defaults : {
            Target : 'ShutdownGateway',
        },
        args : {
            Target     : target,
            GatewayARN : requiredJson,
        },
        body : bodyJson,
    },

    StartGateway : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_StartGateway.html',
        defaults : {
            Target : 'StartGateway',
        },
        args : {
            Target     : target,
            GatewayARN : requiredJson,
        },
        body : bodyJson,
    },

    UpdateBandwidthRateLimit : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_UpdateBandwidthRateLimit.html',
        defaults : {
            Target : 'UpdateBandwidthRateLimit',
        },
        args : {
            Target                               : target,
            AverageDownloadRateLimitInBitsPerSec : requiredJson,
            AverageUploadRateLimitInBitsPerSec   : requiredJson,
            GatewayARN                           : requiredJson,
        },
        body : bodyJson,
    },

    UpdateChapCredentials : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_UpdateChapCredentials.html',
        defaults : {
            Target : 'UpdateChapCredentials',
        },
        args : {
            Target                        : target,
            InitiatorName                 : requiredJson,
            SecretToAuthenticateInitiator : requiredJson,
            SecretToAuthenticateTarget    : optionalJson,
            TargetARN                     : requiredJson,
        },
        body : bodyJson,
    },

    UpdateGatewayInformation : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_UpdateGatewayInformation.html',
        defaults : {
            Target : 'UpdateGatewayInformation',
        },
        args : {
            Target          : target,
            GatewayARN      : requiredJson,
            GatewayName     : optionalJson,
            GatewayTimezone : requiredJson,
        },
        body : bodyJson,
    },

    UpdateGatewaySoftwareNow : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_UpdateGatewaySoftwareNow.html',
        defaults : {
            Target : 'UpdateGatewaySoftwareNow',
        },
        args : {
            Target     : target,
            GatewayARN : requiredJson,
        },
        body : bodyJson,
    },

    UpdateMaintenanceStartTime : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_UpdateMaintenanceStartTime.html',
        defaults : {
            Target : 'UpdateMaintenanceStartTime',
        },
        args : {
            Target       : target,
            GatewayARN   : requiredJson,
            HourOfDay    : requiredJson,
            MinuteOfHour : requiredJson,
            DayOfWeek    : requiredJson,
        },
        body : bodyJson,
    },

    UpdateSnapshotSchedule : {
        url : 'http://docs.amazonwebservices.com/storagegateway/latest/userguide/API_UpdateSnapshotSchedule.html',
        defaults : {
            Target : 'UpdateSnapshotSchedule',
        },
        args : {
            Target            : target,
            Description       : optionalJson,
            RecurrenceInHours : requiredJson,
            StartAt           : requiredJson,
            VolumeARN         : requiredJson,
        },
        body : bodyJson,
    },

};

// --------------------------------------------------------------------------------------------------------------------
