// --------------------------------------------------------------------------------------------------------------------
//
// simpledb-config.js - config for AWS SimepleDB Service
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    // Operations on Distributions

    BatchDeleteAttributes : {
        url : 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_BatchDeleteAttributes.html',
        defaults : {
            Action : 'BatchDeleteAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            DomainName : {
                required : true,
                type     : 'param',
            },
            ItemName : {
                required : true,
                type     : 'param-array-set',
                setName  : 'Item',
            },
            AttributeName : {
                name       : 'Name',
                required   : true,
                type       : 'param-2d-array-set',
                setName    : 'Item',
                subsetName : 'Attribute',
            },
            AttributeValue : {
                name       : 'Value',
                required   : true,
                type       : 'param-2d-array-set',
                setName    : 'Item',
                subsetName : 'Attribute',
            },
        },
    },

    BatchPutAttributes : {
        url : 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_BatchPutAttributes.html',
        defaults : {
            Action : 'BatchPutAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            DomainName : {
                required : true,
                type     : 'param',
            },
            ItemName : {
                required : true,
                type     : 'param-array-set',
                setName  : 'Item',
            },
            AttributeName : {
                name       : 'Name',
                required   : true,
                type       : 'param-2d-array-set',
                setName    : 'Item',
                subsetName : 'Attribute',
            },
            AttributeValue : {
                name       : 'Value',
                required   : true,
                type       : 'param-2d-array-set',
                setName    : 'Item',
                subsetName : 'Attribute',
            },
            AttributeReplace : {
                name       : 'Replace',
                required   : false,
                type       : 'param-2d-array-set',
                setName    : 'Item',
                subsetName : 'Attribute',
            },
        },
    },

    CreateDomain : {
        url : 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_CreateDomain.html',
        defaults : {
            Action : 'CreateDomain',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            DomainName : {
                required : true,
                type     : 'param',
            },
        },
    },

    DeleteAttributes : {
        url : 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_DeleteAttributes.html',
        defaults : {
            Action : 'DeleteAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            DomainName : {
                required : true,
                type     : 'param',
            },
            ItemName : {
                required : true,
                type     : 'param',
            },
            AttributeName : {
                // makes params like Attribute.1.Name, Attribute.2.Name, ...etc...
                name      : 'Name',
                required  : false,
                type      : 'param-array-set',
                setName   : 'Attribute',
            },
            AttributeValue : {
                // makes params like Attribute.1.Value, Attribute.2.Value, ...etc...
                name      : 'Value',
                required  : false,
                type      : 'param-array-set',
                setName   : 'Attribute',
            },
            ExpectedName : {
                // makes params like Expected.1.Name, Expected.2.Name, ...etc...
                name      : 'Name',
                required  : false,
                type      : 'param-array-set',
                setName   : 'Expected',
            },
            ExpectedValue : {
                // makes params like Expected.1.Value, Expected.2.Value, ...etc...
                name      : 'Value',
                required  : false,
                type      : 'param-array-set',
                setName   : 'Expected',
            },
        },
    },

    DeleteDomain : {
        url : 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_DeleteDomain.html',
        defaults : {
            Action : 'DeleteDomain',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            DomainName : {
                required : true,
                type     : 'param',
            },
        },
    },

    DomainMetadata : {
        url : 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_DomainMetadata.html',
        defaults : {
            Action : 'DomainMetadata',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            DomainName : {
                required : true,
                type     : 'param',
            },
        },
    },

    GetAttributes : {
        url : 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_GetAttributes.html',
        defaults : {
            Action : 'GetAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            DomainName : {
                required : true,
                type     : 'param',
            },
            ItemName : {
                required : true,
                type     : 'param',
            },
            AttributeName : {
                // adds params like AttributeName.0, AttributeName.1, ...etc...
                required : false,
                type     : 'param-array',
            },
            ConsistentRead : {
                required : false,
                type     : 'param',
            },
        },
    },

    ListDomains : {
        url : 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_ListDomains.html',
        defaults : {
            Action : 'ListDomains',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            MaxNumberOfDomains : {
                required : false,
                type     : 'param',
            },
            NextToken : {
                required : false,
                type     : 'param',
            },
        },
    },

    PutAttributes : {
        url : 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_PutAttributes.html',
        defaults : {
            Action : 'PutAttributes',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            DomainName : {
                required : true,
                type     : 'param',
            },
            ItemName : {
                required : true,
                type     : 'param',
            },
            AttributeName : {
                // makes params like Attribute.1.Name, Attribute.2.Name, ...etc...
                name      : 'Name',
                required  : true,
                type      : 'param-array-set',
                setName   : 'Attribute',
            },
            AttributeValue : {
                // makes params like Attribute.1.Value, Attribute.2.Value, ...etc...
                name      : 'Value',
                required  : true,
                type      : 'param-array-set',
                setName   : 'Attribute',
            },
            AttributeReplace : {
                // makes params like Attribute.1.Replace, Attribute.2.Replace, ...etc...
                name      : 'Replace',
                required  : false,
                type      : 'param-array-set',
                setName   : 'Attribute',
            },
            ExpectedName : {
                // makes params like Expected.1.Name, Expected.2.Name, ...etc...
                name      : 'Name',
                required  : false,
                type      : 'param-array-set',
                setName   : 'Expected',
            },
            ExpectedValue : {
                // makes params like Expected.1.Value, Expected.2.Value, ...etc...
                name      : 'Value',
                required  : false,
                type      : 'param-array-set',
                setName   : 'Expected',
            },
            ExpectedReplace : {
                // makes params like Expected.1.Replace, Expected.2.Replace, ...etc...
                name      : 'Replace',
                required  : false,
                type      : 'param-array-set',
                setName   : 'Expected',
            },
        },
    },

    Select : {
        url : 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_Select.html',
        defaults : {
            Action : 'Select',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            SelectExpression : {
                required : true,
                type     : 'param',
            },
            ConsistentRead : {
                required : false,
                type     : 'param',
            },
            NextToken : {
                required : false,
                type     : 'param',
            },
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
