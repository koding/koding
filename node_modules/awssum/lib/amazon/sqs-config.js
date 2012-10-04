// --------------------------------------------------------------------------------------------------------------------
//
// sqs-config.js - config for AWS Simple Queue Service
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

function pathQueue(options, args) {
    return '/' + this.awsAccountId() + '/' + args.QueueName;
}

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    AddPermission : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryAddPermission.html',
        path : pathQueue,
        defaults : {
            Action : 'AddPermission',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            ActionName : {
                // does ActionName.N
                required : true,
                type     : 'param-array',
            },
            AwsAccountId : {
                // does AWSAccountId.N
                name     : 'AWSAccountId',
                required : true,
                type     : 'param-array',
            },
            Label : {
                required : true,
                type     : 'param',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
        },
    },

    ChangeMessageVisibility : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryChangeMessageVisibility.html',
        path : pathQueue,
        defaults : {
            Action : 'ChangeMessageVisibility',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
            ReceiptHandle : {
                required : true,
                type     : 'param',
            },
            VisibilityTimeout : {
                required : true,
                type     : 'param',
            },
        },
    },

    ChangeMessageVisibilityBatch : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryChangeMessageVisibilityBatch.html',
        path : pathQueue,
        defaults : {
            Action : 'ChangeMessageVisibilityBatch',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
            Id : {
                required  : true,
                type      : 'param-array-set',
                setName   : 'ChangeMessageVisibilityBatchRequestEntry',
            },
            ReceiptHandle : {
                required  : true,
                type      : 'param-array-set',
                setName   : 'ChangeMessageVisibilityBatchRequestEntry',
            },
            VisibilityTimeout : {
                required  : true,
                type      : 'param-array-set',
                setName   : 'ChangeMessageVisibilityBatchRequestEntry',
            },
        },
    },

    CreateQueue : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryCreateQueue.html',
        defaults : {
            Action : 'CreateQueue',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            AttributeName : {
                name     : 'Name',
                required : false,
                type     : 'param-array-set',
                setName  : 'Attribute',
            },
            AttributeValue : {
                name     : 'Value',
                required : false,
                type     : 'param-array-set',
                setName  : 'Attribute',
            },
            QueueName : {
                required : true,
                type     : 'param',
            },
        },
    },

    DeleteMessage : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryDeleteMessage.html',
        path : pathQueue,
        defaults : {
            Action : 'DeleteMessage',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
            ReceiptHandle : {
                required : true,
                type : 'param',
            },
        },
    },

    DeleteMessageBatch : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryDeleteMessageBatch.html',
        path : pathQueue,
        defaults : {
            Action : 'DeleteMessageBatch',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            Id : {
                required  : true,
                type      : 'param-array-set',
                setName   : 'DeleteMessageBatchRequestEntry',
            },
            ReceiptHandle : {
                required  : true,
                type      : 'param-array-set',
                setName   : 'DeleteMessageBatchRequestEntry',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
        },
    },

    DeleteQueue : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryDeleteQueue.html',
        path : pathQueue,
        defaults : {
            Action : 'DeleteQueue',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
        },
    },

    GetQueueAttributes : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryGetQueueUrl.html',
        path : pathQueue,
        defaults : {
            Action : 'GetQueueAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            AttributeName : {
                required : true,
                type : 'param-array',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
        },
    },

    GetQueueUrl : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryGetQueueAttributes.html',
        defaults : {
            Action : 'GetQueueUrl',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            QueueName : {
                required : true,
                type     : 'param',
            },
            QueueOwnerAwsAccountId : {
                name     : 'QueueOwnerAWSAccountId',
                required : false,
                type     : 'param',
            },
        },
    },

    ListQueues : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryListQueues.html',
        path : '/',
        defaults : {
            Action : 'ListQueues',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            QueueNamePrefix : {
                required : false,
                type : 'param',
            },
        },
    },

    ReceiveMessage : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryReceiveMessage.html',
        path : pathQueue,
        defaults : {
            Action : 'ReceiveMessage',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            AttributeName : {
                required : false,
                type     : 'param-array-set',
            },
            MaxNumberOfMessages : {
                required : false,
                type     : 'param',
            },
            VisibilityTimeout : {
                required : false,
                type     : 'param',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
        },
    },

    RemovePermission : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryRemovePermission.html',
        path : pathQueue,
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
                type : 'param',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
        },
    },

    SendMessage : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QuerySendMessage.html',
        path : pathQueue,
        defaults : {
            Action : 'SendMessage',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            MessageBody : {
                required : true,
                type : 'param',
            },
            DelaySeconds : {
                required : false,
                type : 'param',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
        },
    },

    SendMessageBatch : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QuerySendMessageBatch.html',
        path : pathQueue,
        defaults : {
            Action : 'SendMessageBatch',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
            Id : {
                required  : true,
                type      : 'param-array-set',
                setName   : 'SendMessageBatchRequestEntry',
            },
            MessageBody : {
                required  : true,
                type      : 'param-array-set',
                setName   : 'SendMessageBatchRequestEntry',
            },
            DelaySeconds : {
                required  : true,
                type      : 'param-array-set',
                setName   : 'SendMessageBatchRequestEntry',
            },
        },
    },

    SetQueueAttributes : {
        url : 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QuerySetQueueAttributes.html',
        path : pathQueue,
        defaults : {
            Action : 'SetQueueAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            AttributeName : {
                name     : 'Attribute.Name',
                required : true,
                type     : 'param',
            },
            AttributeValue : {
                name     : 'Attribute.Value',
                required : true,
                type     : 'param',
            },
            QueueName : {
                required : true,
                type : 'special',
            },
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
