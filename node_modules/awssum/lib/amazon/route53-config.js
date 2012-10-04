// --------------------------------------------------------------------------------------------------------------------
//
// route53-config.js - config for AWS Route 53
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
                    ResourceRecord : [],
                },
            },
        };

        // now add each resource record
        _.each(change.ResourceRecords, function(rr) {
            var value = { Value : rr };
            c.ResourceRecordSet.ResourceRecords.ResourceRecord.push(value);
        });

        // push this onto the Change array
        data.ChangeBatch.Changes.Change.push(c);
    });

    return data2xml('ChangeResourceRecordSetsRequest', data);
}

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    CreateHostedZone : {
        url : 'http://docs.amazonwebservices.com/Route53/latest/APIReference/API_CreateHostedZone.html',
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
        url : 'http://docs.amazonwebservices.com/Route53/latest/APIReference/API_GetHostedZone.html',
        path : pathHostedZoneId,
        args : {
            'HostedZoneId' : {
                required : true,
                type : 'special',
            },
        },
    },

    DeleteHostedZone : {
        url : 'http://docs.amazonwebservices.com/Route53/latest/APIReference/API_DeleteHostedZone.html',
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
        url : 'http://docs.amazonwebservices.com/Route53/latest/APIReference/API_ListHostedZones.html',
        path : pathHostedZone,
        args : {
            'Marker' : {
                name     : 'marker',
                required : false,
                type     : 'param',
            },
            'MaxItems' : {
                name     : 'maxitems',
                required : false,
                type     : 'param',
            },
        },
    },

    ChangeResourceRecordSets : {
        url : 'http://docs.amazonwebservices.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html',
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
        url : 'http://docs.amazonwebservices.com/Route53/latest/APIReference/API_ListResourceRecordSets.html',
        path : pathHostedZoneIdRRSet,
        args : {
            HostedZoneId : {
                required : true,
                type     : 'special',
            },
            Name : {
                name     : 'name',
                required : false,
                type     : 'param',
            },
            Type : {
                name     : 'type',
                required : false,
                type     : 'param',
            },
            Identifier : {
                name     : 'identifier',
                required : false,
                type     : 'param',
            },
            MaxItems : {
                name     : 'maxitems',
                required : false,
                type     : 'param',
            },
        },
    },

    GetChange : {
        url : 'http://docs.amazonwebservices.com/Route53/latest/APIReference/API_GetChange.html',
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
