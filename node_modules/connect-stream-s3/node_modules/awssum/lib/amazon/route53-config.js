// --------------------------------------------------------------------------------------------------------------------
//
// route53-config.js - class for AWS Route 53
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var _ = require('underscore');
var data2xml = require('data2xml');

// --------------------------------------------------------------------------------------------------------------------
// utility functions

function pathHostedZone(options, args) {
    return '/' + this.version() + '/hostedzone';
}

function pathHostedZoneId(options, args) {
    return '/' + this.version() + '/hostedzone/' + args.HostedZoneId;
}

function pathHostedZoneIdRRSet(options, args) {
    return '/' + this.version() + '/hostedzone/' + args.HostedZoneId + '/rrset';
}

function pathChangeId(options, args) {
    return '/' + this.version() + '/change/' + args.ChangeId;
}

function bodyCreateHostedZoneRequest(options, args) {
    var self = this;

    // create the data
    var data = {
        _attr : { 'xmlns' : 'https://route53.amazonaws.com/doc/2011-05-05/' },
        Name : args.Name,
        CallerReference : args.CallerReference,
    };

    // add the comment if defined
    if ( !_.isUndefined(args.Comment) ) {
        data.HostedZoneConfig = {};
        data.HostedZoneConfig.Comment = args.Comment;
    }

    return data2xml('CreateHostedZoneRequest', data);
}

function bodyChangeResourceRecordSetsRequest(options, args) {
    // create the data structure for the XML
    var data = {
        _attr : { 'xmlns' : 'https://route53.amazonaws.com/doc/2011-05-05/' },
        ChangeBatch : {
            Changes : {
                Change : [],
            }
        }
    };

    // add the comment if we have one
    if ( ! _.isUndefined(args.comment) ) {
        data.ChangeBatch.Comment = args.comment;
    }

    _.each(args.Changes, function(change) {
        var c = {
            Action : change.Action,
            ResourceRecordSet : {
                Name : change.Name,
                Type : change.Type,
                TTL : change. Ttl,
                ResourceRecords : {
                    ResourceRecord : {
                        Value : [],
                    },
                },
            },
        };

        // now add each resource record
        _.each(change.ResourceRecords, function(rr) {
            c.ResourceRecordSet.ResourceRecords.ResourceRecord.Value.push(rr);
        });

        // push this onto the Change array
        data.ChangeBatch.Changes.Change.push(c);
    });

    return data2xml('ChangeResourceRecordSetsRequest', data);
}

// --------------------------------------------------------------------------------------------------------------------

// This list from: http://docs.amazonwebservices.com/Route53/latest/APIReference/ActionsOnZones.html
//
// * http://docs.amazonwebservices.com/Route53/latest/APIReference/API_CreateHostedZone.html
// * http://docs.amazonwebservices.com/Route53/latest/APIReference/API_GetHostedZone.html
// * http://docs.amazonwebservices.com/Route53/latest/APIReference/API_DeleteHostedZone.html
// * http://docs.amazonwebservices.com/Route53/latest/APIReference/API_ListHostedZones.html
//
// This list from: http://docs.amazonwebservices.com/Route53/latest/APIReference/ActionsOnRRS.html
//
// * http://docs.amazonwebservices.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html
// * http://docs.amazonwebservices.com/Route53/latest/APIReference/API_ListResourceRecordSets.html
// * http://docs.amazonwebservices.com/Route53/latest/APIReference/API_GetChange.html

// Note: many params in Route53 are lowercase, but we're capitalising them to be consistent with other services.

module.exports = {

    CreateHostedZone : {
        method : 'POST',
        path : pathHostedZone,
        args : {
            Name : {
                required : true,
                type     : 'special',
            },
            CallerReference : {
                required : true,
                type     : 'special',
            },
            Comment : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyCreateHostedZoneRequest,
    },

    GetHostedZone : {
        path : pathHostedZoneId,
        args : {
            'HostedZoneId' : {
                required : true,
                type : 'special',
            },
        },
    },

    DeleteHostedZone : {
        method : 'DELETE',
        path : pathHostedZoneId,
        args : {
            'HostedZoneId' : {
                required : true,
                type : 'special',
            },
        },
    },

    ListHostedZones : {
        path : pathHostedZone,
        args : {
            'Marker' : {
                required : false,
                type : 'param',
            },
            'MaxItems' : {
                required : false,
                type : 'param',
            },
        },
    },

    ChangeResourceRecordSets : {
        method : 'POST',
        path : pathHostedZoneIdRRSet,
        args : {
            HostedZoneId : {
                required : true,
                type : 'special',
            },
            Comment : {
                required : false,
                type : 'special',
            },
        },
        body : bodyChangeResourceRecordSetsRequest,
    },

    ListResourceRecordSets : {
        path : pathHostedZoneIdRRSet,
        args : {
            HostedZoneId : {
                required : true,
                type : 'special',
            },
            Name : {
                required : false,
                type     : 'param',
            },
            Type : {
                required : false,
                type     : 'param',
            },
            Identifier : {
                required : false,
                type     : 'param',
            },
            MaxItems : {
                required : false,
                type     : 'param',
            },
        },
    },

    GetChange : {
        path : pathChangeId,
        args : {
            'ChangeId' : {
                required : true,
                type     : 'special',
            },
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
