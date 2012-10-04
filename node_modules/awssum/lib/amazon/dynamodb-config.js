// --------------------------------------------------------------------------------------------------------------------
//
// dynamodb-config.js - config for Amazon DynamoDB
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var _ = require('underscore');

// --------------------------------------------------------------------------------------------------------------------
// utility functions

function bodyBatchGetItems(options, args) {
    var data = {
        RequestItems : args.RequestItems,
    };

    // console.log(JSON.stringify(data));

    return JSON.stringify(data);
}

function bodyCreateTable(options, args) {
    var data = {
        TableName : args.TableName,
        KeySchema : args.KeySchema,
        ProvisionedThroughput : args.ProvisionedThroughput
    };

    // console.log(JSON.stringify(data));

    return JSON.stringify(data);
}

var optionalDeleteItemArgs = [
    'Expected', 'ReturnValues'
];
function bodyDeleteItem(options, args) {
    var data = {
        TableName : args.TableName,
        Key       : args.Key,
    };

    optionalDeleteItemArgs.forEach(function(v, i) {
        if ( !_.isUndefined(args[v]) ) {
            data[v] = args[v];
        }
    });

    // console.log(JSON.stringify(data));

    return JSON.stringify(data);
}

function bodyDeleteTable(options, args) {
    var data = {
        TableName : args.TableName,
    };

    return JSON.stringify(data);
}

// same as above
var bodyDescribeTable = bodyDeleteTable;

// GetItem
var optionalGetItemArgs = [
    'AttributesToGet', 'ConsistentRead'
];
function bodyGetItem(options, args) {
    var data = {
        TableName : args.TableName,
        Key       : args.Key,
    };

    optionalGetItemArgs.forEach(function(v, i) {
        if ( !_.isUndefined(args[v]) ) {
            data[v] = args[v];
        }
    });

    // console.log(JSON.stringify(data));

    return JSON.stringify(data);
}

function bodyListTables(options, args) {
    var data = {};

    if ( !_.isUndefined(args.Limit) ) {
        data.Limit = args.Limit;
    }

    if ( !_.isUndefined(args.ExclusiveStartTableName) ) {
        data.ExclusiveStartTableName = args.ExclusiveStartTableName;
    }

    return JSON.stringify(data);
}

var optionalPutItemArgs = [
    'Expected', 'ReturnValues'
];
function bodyPutItem(options, args) {
    var data = {
        TableName : args.TableName,
        Item      : args.Item,
    };

    optionalPutItemArgs.forEach(function(v, i) {
        if ( !_.isUndefined(args[v]) ) {
            data[v] = args[v];
        }
    });

    // console.log(JSON.stringify(data));

    return JSON.stringify(data);
}

var optionalQueryArgs = [
    'AttributesToGet', 'Limit', 'ConsistentRead', 'Count', 'ScanIndexForward', 'ExclusiveStartKey'
];
function bodyQuery(options, args) {
    var data = {
        TableName : args.TableName,
        HashKeyValue : args.HashKeyValue,
    };

    optionalQueryArgs.forEach(function(v, i) {
        if ( !_.isUndefined(args[v]) ) {
            data[v] = args[v];
        }
    });

    if ( args.AttributeValueList || args.ComparisonOperator ) {
        data.RangeKeyCondition = {
            AttributeValueList : args.AttributeValueList,
            ComparisonOperator : args.ComparisonOperator,
        };
    }

    // console.log(JSON.stringify(data));

    return JSON.stringify(data);
}

var optionalScanArgs = [
    'AttributesToGet', 'Count', 'ScanFilter', 'ExclusiveStartKey'
];
function bodyScan(options, args) {
    var data = {
        TableName : args.TableName,
    };

    optionalScanArgs.forEach(function(v, i) {
        if ( !_.isUndefined(args[v]) ) {
            data[v] = args[v];
        }
    });

    // console.log(JSON.stringify(data));

    return JSON.stringify(data);
}

var optionalUpdateItemArgs = [
    'AttributeUpdates', 'Expected', 'ReturnValues'
];
function bodyUpdateItem(options, args) {
    var data = {
        TableName : args.TableName,
        Key       : args.Key,
    };

    optionalUpdateItemArgs.forEach(function(v, i) {
        if ( !_.isUndefined(args[v]) ) {
            data[v] = args[v];
        }
    });

    // console.log(JSON.stringify(data));

    return JSON.stringify(data);
}

function bodyUpdateTable(options, args) {
    var data = {
        TableName             : args.TableName,
        ProvisionedThroughput : args.ProvisionedThroughput,
    };

    // console.log(JSON.stringify(data));

    return JSON.stringify(data);
}

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    BatchGetItems : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_BatchGetItems.html',
        defaults : {
            Target : 'BatchGetItem'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            RequestItems : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyBatchGetItems,
    },

    // can put new, or delete existing items, can't update existing items
    url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_BatchWriteItem.html',
    BatchWriteItem : {
        defaults : {
            Target : 'BatchWriteItem'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            RequestItems : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyBatchGetItems,
    },

    CreateTable : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_CreateTable.html',
        defaults : {
            Target : 'CreateTable'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            TableName : {
                required : true,
                type     : 'special',
            },
            KeySchema : {
                required : true,
                type     : 'special',
            },
            ProvisionedThroughput : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyCreateTable,
    },

    DeleteItem : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_DeleteItem.html',
        defaults : {
            Target : 'DeleteItem',
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            Key : {
                required : true,
                type     : 'special',
            },
            Expected : {
                required : true,
                type     : 'special',
            },
            ReturnValues : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyDeleteItem,
    },

    DeleteTable : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_DeleteTable.html',
        defaults : {
            Target : 'DeleteTable',
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            TableName : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyDeleteTable,
    },

    DescribeTable : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_DescribeTables.html',
        defaults : {
            Target : 'DescribeTable'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            TableName : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyDescribeTable,
    },

    GetItem : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_GetItem.html',
        defaults : {
            Target : 'GetItem'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            TableName : {
                required : true,
                type     : 'special',
            },
            Key : {
                required : true,
                type     : 'special',
            },
            AttributesToGet : {
                required : false,
                type     : 'special',
            },
            ConsistentRead : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyGetItem,
    },

    ListTables : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_ListTables.html',
        defaults : {
            Target : 'ListTables'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            Limit : {
                required : false,
                type     : 'special',
            },
            ExclusiveStartTableName : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyListTables,
    },

    PutItem : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_PutItem.html',
        defaults : {
            Target : 'PutItem'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            TableName : {
                required : true,
                type     : 'special',
            },
            Item : {
                required : true,
                type     : 'special',
            },
            Expected : {
                required : false,
                type     : 'special',
            },
            ReturnValues : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyPutItem,
    },

    Query : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_Query.html',
        defaults : {
            Target : 'Query'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            TableName : {
                required : true,
                type     : 'special',
            },
            AttributesToGet : {
                required : false,
                type     : 'special',
            },
            Limit : {
                required : false,
                type     : 'special',
            },
            ConsistentRead : {
                required : false,
                type     : 'special',
            },
            Count : {
                required : false,
                type     : 'special',
            },
            // this is a { 'S' : 'Value' } or { 'N' : 'Value' } combination
            HashKeyValue : {
                required : true,
                type     : 'special',
            },
            // list of value pairs ({ 'S' : 'Value' } or { 'N' : 'Value' })
            AttributeValueList : {
                required : false,
                type     : 'special',
            },
            ComparisonOperator : {
                required : false,
                type     : 'special',
            },
            ScanIndexForward : {
                required : false, // 'true' or 'false'
                type     : 'special',
            },
        },
        body : bodyQuery,
    },

    Scan : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_Scan.html',
        defaults : {
            Target : 'Scan'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            TableName : {
                required : true,
                type     : 'special',
            },
            AttributesToGet : {
                required : false,
                type     : 'special',
            },
            Limit : {
                required : false,
                type     : 'special',
            },
            Count : {
                required : false,
                type     : 'special',
            },
            AttributeValueList : {
                required : false,
                type     : 'special',
            },
            ComparisonOperator : {
                required : false,
                type     : 'special',
            },
            ExclusiveStartKey : {
                required : false, // of HashKeyElement and RangeKeyElement
                type     : 'special',
            },
        },
        body : bodyScan,
    },

    UpdateItem : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_UpdateItem.html',
        defaults : {
            Target : 'UpdateItem'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            TableName : {
                required : true,
                type     : 'special',
            },
            Key : {
                required : true,
                type     : 'special',
            },
            AttributeUpdates : {
                required : false,
                type     : 'special',
            },
            Expected : {
                required : false,
                type     : 'special',
            },
            ReturnValues : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyUpdateItem,
    },

    UpdateTable : {
        url : 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_UpdateTable.html',
        defaults : {
            Target : 'UpdateTable'
        },
        args : {
            Target : {
                required : true,
                type     : 'special',
            },
            TableName : {
                required : true,
                type     : 'special',
            },
            ProvisionedThroughput : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyUpdateTable,
    },

};

// --------------------------------------------------------------------------------------------------------------------
