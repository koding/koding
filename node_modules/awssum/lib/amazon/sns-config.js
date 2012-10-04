// --------------------------------------------------------------------------------------------------------------------
//
// sns-config.js - config for AWS Simple Notification Service
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    // Operations on Distributions

    AddPermission : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_AddPermission.html',
        defaults : {
            Action : 'AddPermission',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            AwsAccountId : {
                // does ActionName.member.N
                name     : 'AWSAccountId',
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
            ActionName : {
                // does ActionName.member.N
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
            Label : {
                required : true,
                type     : 'param',
            },
            TopicArn : {
                required : true,
                type     : 'param',
            },
        },
    },

    ConfirmSubscription : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_ConfirmSubscription.html',
        defaults : {
            Action : 'ConfirmSubscription',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            TopicArn : {
                required : true,
                type     : 'param',
            },
            Token : {
                required : true,
                type     : 'param',
            },
            AuthenticateOnUnsubscribe : {
                required : false,
                type     : 'param',
            },
        },
    },

    CreateTopic : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_CreateTopic.html',
        defaults : {
            Action : 'CreateTopic',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            Name : {
                required : true,
                type     : 'param',
            },
        },
    },

    DeleteTopic : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_DeleteTopic.html',
        defaults : {
            Action : 'DeleteTopic',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            TopicArn : {
                required : true,
                type     : 'param',
            },
        },
    },

    GetSubscriptionAttributes : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_GetSubscriptionAttributes.html',
        defaults : {
            Action : 'GetSubscriptionAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            SubscriptionArn : {
                required : true,
                type     : 'param',
            },
        },
    },

    GetTopicAttributes : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_GetTopicAttributes.html',
        defaults : {
            Action : 'GetTopicAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            TopicArn : {
                required : true,
                type     : 'param',
            },
        },
    },

    ListSubscriptions : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_ListSubscriptions.html',
        defaults : {
            Action : 'ListSubscriptions',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            NextToken : {
                required : false,
                type     : 'param',
            },
        },
    },

    ListSubscriptionsByTopic : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_ListSubscriptionsByTopic.html',
        defaults : {
            Action : 'ListSubscriptionsByTopic',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            TopicArn : {
                required : true,
                type     : 'param',
            },
            NextToken : {
                required : false,
                type     : 'param',
            },
        },
    },

    ListTopics : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_ListTopics.html',
        defaults : {
            Action : 'ListTopics',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            NextToken : {
                required : false,
                type     : 'param',
            },
        },
    },

    Publish : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_Publish.html',
        defaults : {
            Action : 'Publish',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            Message : {
                required : true,
                type     : 'param',
            },
            MessageStructure : {
                required : false,
                type     : 'param',
            },
            TopicArn : {
                required : true,
                type     : 'param',
            },
            Subject : {
                required : false,
                type     : 'param',
            },
        },
    },

    RemovePermission : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_RemovePermission.html',
        defaults : {
            Action : 'RemovePermission',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            Label : {
                required : true,
                type     : 'param',
            },
            TopicArn : {
                required : true,
                type     : 'param',
            },
        },
    },

    SetSubscriptionAttributes : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_SetSubscriptionAttributes.html',
        defaults : {
            Action : 'SetSubscriptionAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            AttributeName : {
                required : true,
                type     : 'param',
            },
            AttributeValue : {
                required : true,
                type     : 'param',
            },
            SubscriptionArn : {
                required : true,
                type     : 'param',
            },
        },
    },

    SetTopicAttributes : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_SetTopicAttributes.html',
        defaults : {
            Action : 'SetTopicAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            AttributeName : {
                required : true,
                type     : 'param',
            },
            AttributeValue : {
                required : true,
                type     : 'param',
            },
            TopicArn : {
                required : true,
                type     : 'param',
            },
        },
    },

    Subscribe : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_Subscribe.html',
        defaults : {
            Action : 'Subscribe',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            Endpoint : {
                required : true,
                type     : 'param',
            },
            Protocol : {
                required : true,
                type     : 'param',
            },
            TopicArn : {
                required : true,
                type     : 'param',
            },
        },
    },

    Unsubscribe : {
        url : 'http://docs.amazonwebservices.com/sns/latest/api/API_Unsubscribe.html',
        defaults : {
            Action : 'Unsubscribe',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            SubscriptionArn : {
                required : true,
                type     : 'param',
            },
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
