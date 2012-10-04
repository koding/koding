// --------------------------------------------------------------------------------------------------------------------
//
// ses-config.js - class for AWS Simple Email Service
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
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

function bodyForm(options, args) {
    // set the body with the params
    var formsHash = {};
    _.each(options.forms, function(v) {
        formsHash[v.name] = v.value;
    });

    // console.log(options.forms);
    // console.log(formsHash);

    return querystring.stringify(formsHash);
}

// --------------------------------------------------------------------------------------------------------------------

// This list from: http://docs.amazonwebservices.com/ses/latest/APIReference/API_Operations.html
//
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_DeleteIdentity.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_DeleteVerifiedEmailAddress.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_GetIdentityVerificationAttributes.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_GetSendQuota.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_GetSendStatistics.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_ListIdentities.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_ListVerifiedEmailAddresses.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_SendEmail.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_SendRawEmail.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_VerifyDomainIdentity.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_VerifyEmailAddress.html
// * http://docs.amazonwebservices.com/ses/latest/APIReference/API_VerifyEmailIdentity.html

module.exports = {

    DeleteIdentity : {
        defaults : {
            Action : 'DeleteIdentity'
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
            Identity : {
                required : true,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

    DeleteVerifiedEmailAddress : {
        defaults : {
            Action : 'DeleteVerifiedEmailAddress'
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
            EmailAddress : {
                required : true,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

    GetIdentityVerificationAttributes : {
        defaults : {
            Action : 'GetIdentityVerificationAttributes'
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
            Identities : {
                // does Identities.member.N
                required : true,
                type     : 'form-array',
                prefix   : 'member',
            },
        },
        body : bodyForm,
    },

    GetSendQuota : {
        defaults : {
            Action : 'GetSendQuota',
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

    GetSendStatistics : {
        defaults : {
            Action : 'GetSendStatistics',
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

    ListIdentities : {
        defaults : {
            Action : 'ListIdentities'
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
            IdentityType : {
                required : false,
                type     : 'form',
            },
            MaxItems : {
                required : false,
                type     : 'form',
            },
            NextToken : {
                required : false,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

    ListVerifiedEmailAddresses : {
        defaults : {
            Action : 'ListVerifiedEmailAddresses'
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

    SendEmail : {
        defaults : {
            Action : 'SendEmail'
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
            // Destination
            ToAddresses : {
                // does Destination.ToAddresses.member.1, Destination.ToAddresses.member.1, ...etc...
                name     : 'Destination.ToAddresses',
                required : false,
                type     : 'form-array',
                prefix   : 'member'
            },
            CcAddresses : {
                // does Destination.CcAddresses.member.1, Destination.CcAddresses.member.1, ...etc...
                name     : 'Destination.CcAddresses',
                required : false,
                type     : 'form-array',
                prefix   : 'member'
            },
            BccAddresses : {
                // does Destination.BccAddresses.member.1, Destination.BccAddresses.member.1, ...etc...
                name     : 'Destination.BccAddresses',
                required : false,
                type     : 'form-array',
                prefix   : 'member'
            },
            Subject : {
                // does Message.Subject.Data
                name     : 'Message.Subject.Data',
                required : false,
                type     : 'form',
            },
            SubjectCharset : {
                // does Message.Subject.Charset
                name     : 'Message.Subject.Charset',
                required : false,
                type     : 'form',
            },
            Html : {
                // does Message.Body.Html.Data
                name     : 'Message.Body.Html.Data',
                required : false,
                type     : 'form',
            },
            HtmlCharset : {
                // does Message.Body.Html.Charset
                name     : 'Message.Body.Html.Charset',
                required : false,
                type     : 'form',
            },
            Text : {
                // does Message.Body.Text.Data
                name     : 'Message.Body.Text.Data',
                required : false,
                type     : 'form',
            },
            TextCharset : {
                // does Message.Body.Text.Charset
                name     : 'Message.Body.Text.Charset',
                required : false,
                type     : 'form',
            },
            ReplyToAddresses : {
                // does ReplyToAddress.member.N
                required : false,
                type     : 'form-array',
                prefix   : 'member',
            },
            ReturnPath : {
                required : false,
                type     : 'form',
            },
            Source : {
                required : true,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

    SendRawEmail : {
        defaults : {
            Action : 'SendRawEmail'
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
            Destinations : {
                required : false,
                type     : 'form-array',
                prefix   : 'member',
            },
            RawMessage : {
                name     : 'RawMessage.Data',
                required : true,
                type     : 'form-base64',
            },
            Source : {
                required : false,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

    VerifyDomainIdentity : {
        defaults : {
            Action : 'VerifyDomainIdentity'
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
            Domain : {
                required : true,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

    VerifyEmailAddress : {
        defaults : {
            Action : 'VerifyEmailAddress'
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
            EmailAddress : {
                required : true,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

    VerifyEmailIdentity : {
        defaults : {
            Action : 'VerifyEmailIdentity'
        },
        args : {
            Action : {
                required : true,
                type     : 'form',
            },
            EmailAddress : {
                required : true,
                type     : 'form',
            },
        },
        body : bodyForm,
    },

};
