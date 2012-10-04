// --------------------------------------------------------------------------------------------------------------------
//
// sns-config.js - class for AWS Simple Notification Service
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// This list from: http://docs.amazonwebservices.com/sns/latest/api/API_Operations.html
//
// * http://docs.amazonwebservices.com/sns/latest/api/API_AddPermission.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_ConfirmSubscription.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_CreateTopic.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_DeleteTopic.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_GetSubscriptionAttributes.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_GetTopicAttributes.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_ListSubscriptions.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_ListSubscriptionsByTopic.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_ListTopics.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_Publish.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_RemovePermission.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_SetSubscriptionAttributes.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_SetTopicAttributes.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_Subscribe.html
// * http://docs.amazonwebservices.com/sns/latest/api/API_Unsubscribe.html

module.exports = {

    // Operations on Distributions

    AddPermission : {
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
