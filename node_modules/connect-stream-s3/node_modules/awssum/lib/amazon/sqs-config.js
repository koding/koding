// --------------------------------------------------------------------------------------------------------------------
//
// sqs-config.js - class for AWS Simple Queue Service
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

// This list from: http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Operations.html
//
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryAddPermission.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryChangeMessageVisibility.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryChangeMessageVisibilityBatch.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryCreateQueue.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryDeleteMessage.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryDeleteMessageBatch.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryDeleteQueue.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryGetQueueUrl.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryGetQueueAttributes.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryListQueues.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryReceiveMessage.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QueryRemovePermission.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QuerySendMessage.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QuerySendMessageBatch.html
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Query_QuerySetQueueAttributes.html

module.exports = {

    AddPermission : {
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
            VisbilityTimeout : {
                required : true,
                type     : 'param',
            },
        },
    },

    ChangeMessageVisibilityBatch : {
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
