// --------------------------------------------------------------------------------------------------------------------
//
// ses-config.js - config for AWS Simple Email Service
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

var required = {
    required : true,
    type     : 'form',
};

var optional = {
    required : false,
    type     : 'form',
};

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    DeleteIdentity : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_DeleteIdentity.html',
        defaults : {
            Action : 'DeleteIdentity'
        },
        args : {
            Action   : required,
            Identity : required,
        },
        body : bodyForm,
    },

    DeleteVerifiedEmailAddress : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_DeleteVerifiedEmailAddress.html',
        defaults : {
            Action : 'DeleteVerifiedEmailAddress'
        },
        args : {
            Action       : required,
            EmailAddress : required,
        },
        body : bodyForm,
    },

    GetIdentityDkimAttributes : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_GetIdentityDkimAttributes.html',
        defaults : {
            Action : 'GetIdentityDkimAttributes'
        },
        args : {
            Action     : required,
            Identities : {
                // does Identities.member.N
                required : true,
                type     : 'form-array',
                prefix   : 'member',
            },
        },
        body : bodyForm,
    },

    GetIdentityNotificationAttributes : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_GetIdentityNotificationAttributes.html',
        defaults : {
            Action : 'GetIdentityNotificationAttributes'
        },
        args : {
            Action     : required,
            Identities : {
                // does Identities.member.N
                required : true,
                type     : 'form-array',
                prefix   : 'member',
            },
        },
        body : bodyForm,
    },

    GetIdentityVerificationAttributes : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_GetIdentityVerificationAttributes.html',
        defaults : {
            Action : 'GetIdentityVerificationAttributes'
        },
        args : {
            Action     : required,
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
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_GetSendQuota.html',
        defaults : {
            Action : 'GetSendQuota',
        },
        args : {
            Action : required,
        },
        body : bodyForm,
    },

    GetSendStatistics : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_GetSendStatistics.html',
        defaults : {
            Action : 'GetSendStatistics',
        },
        args : {
            Action : required,
        },
        body : bodyForm,
    },

    ListIdentities : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_ListIdentities.html',
        defaults : {
            Action : 'ListIdentities'
        },
        args : {
            Action       : required,
            IdentityType : optional,
            MaxItems     : optional,
            NextToken    : optional,
        },
        body : bodyForm,
    },

    ListVerifiedEmailAddresses : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_ListVerifiedEmailAddresses.html',
        defaults : {
            Action : 'ListVerifiedEmailAddresses'
        },
        args : {
            Action : required,
        },
        body : bodyForm,
    },

    SendEmail : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_SendEmail.html',
        defaults : {
            Action : 'SendEmail'
        },
        args : {
            Action      : required,
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
            Subject      : {
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
            Text         : {
                // does Message.Body.Text.Data
                name     : 'Message.Body.Text.Data',
                required : false,
                type     : 'form',
            },
            TextCharset  : {
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
            ReturnPath   : optional,
            Source       : required,
        },
        body : bodyForm,
    },

    SendRawEmail : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_SendRawEmail.html',
        defaults : {
            Action : 'SendRawEmail'
        },
        args : {
            Action : required,
            Destinations : {
                required : false,
                type     : 'form-array',
                prefix   : 'member',
            },
            RawMessage   : {
                name     : 'RawMessage.Data',
                required : true,
                type     : 'form-base64',
            },
            Source       : optional,
        },
        body : bodyForm,
    },

    SetIdentityDkimEnabled : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_SetIdentityDkimEnabled.html',
        defaults : {
            Action : 'SetIdentityDkimEnabled'
        },
        args : {
            Action      : required,
            DkimEnabled : required,
            Identity    : required,
        },
        body : bodyForm,
    },

    SetIdentityFeedbackForwardingEnabled : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_SetIdentityFeedbackForwardingEnabled.html',
        defaults : {
            Action : 'SetIdentityFeedbackForwardingEnabled'
        },
        args : {
            Action            : required,
            ForwardingEnabled : required,
            Identity          : required,
        },
        body : bodyForm,
    },

    SetIdentityNotificationTopic : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_SetIdentityNotificationTopic.html',
        defaults : {
            Action : 'SetIdentityNotificationTopic'
        },
        args : {
            Action           : required,
            Identity         : required,
            NotificationType : required,
            SnsTopic         : optional,
        },
        body : bodyForm,
    },

    VerifyDomainDkim : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_VerifyDomainDkim.html',
        defaults : {
            Action : 'VerifyDomainDkim'
        },
        args : {
            Action : required,
            Domain : required,
        },
        body : bodyForm,
    },

    VerifyDomainIdentity : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_VerifyDomainIdentity.html',
        defaults : {
            Action : 'VerifyDomainIdentity'
        },
        args : {
            Action : required,
            Domain : required,
        },
        body : bodyForm,
    },

    VerifyEmailAddress : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_VerifyEmailAddress.html',
        defaults : {
            Action : 'VerifyEmailAddress'
        },
        args : {
            Action       : required,
            EmailAddress : required,
        },
        body : bodyForm,
    },

    VerifyEmailIdentity : {
        url : 'http://docs.amazonwebservices.com/ses/latest/APIReference/API_VerifyEmailIdentity.html',
        defaults : {
            Action : 'VerifyEmailIdentity'
        },
        args : {
            Action       : required,
            EmailAddress : required,
        },
        body : bodyForm,
    },

};
