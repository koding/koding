// --------------------------------------------------------------------------------------------------------------------
//
// cloudsearch-config.js - config for AWS CloudSearch
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var optional        = { required : false, type : 'param'                          };
var required        = { required : true,  type : 'param'                          };
var optionalArray   = { required : false, type : 'param-array', prefix : 'member' };
var requiredArray   = { required : true,  type : 'param-array', prefix : 'member' };
var optionalData    = { required : false, type : 'param-data',  prefix : 'member' };
var requiredData    = { required : true,  type : 'param-data',  prefix : 'member' };
var requiredJson    = { required : true,  type : 'param-json'                     };
var requiredSpecial = { required : true,  type : 'special'                        };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    // Configuration API

    CreateDomain : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_CreateDomain.html',
        defaults : {
            Action : 'CreateDomain'
        },
        args : {
            Action     : required,
            DomainName : required,
        },
    },

    DefineIndexField : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DefineIndexField.html',
        defaults : {
            Action : 'DefineIndexField'
        },
        args : {
            Action     : required,
            DomainName : required,
            IndexField : requiredData,
       },
    },

    DefineRankExpression : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DefineRankExpression.html',
        defaults : {
            Action : 'DefineRankExpression'
        },
        args : {
            Action         : required,
            DomainName     : required,
            RankExpression : requiredData,
        },
    },

    DeleteDomain : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DeleteDomain.html',
        defaults : {
            Action : 'DeleteDomain'
        },
        args : {
            Action     : required,
            DomainName : required,
        },
    },

    DeleteIndexField : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DeleteIndexField.html',
        defaults : {
            Action : 'DeleteIndexField'
        },
        args : {
            Action         : required,
            DomainName     : required,
            IndexFieldName : required,
        },
    },

    DeleteRankExpression : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DeleteRankExpression.html',
        defaults : {
            Action : 'DeleteRankExpression'
        },
        args : {
            Action     : required,
            DomainName : required,
            RankName   : required,
        },
    },

    DescribeDefaultSearchField : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DescribeDefaultSearchField.html',
        defaults : {
            Action : 'DescribeDefaultSearchField'
        },
        args : {
            Action     : required,
            DomainName : required,
        },
    },

    DescribeDomains : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DescribeDomains.html',
        defaults : {
            Action : 'DescribeDomains'
        },
        args : {
            Action      : required,
            DomainNames : optionalArray,
        },
    },

    DescribeIndexFields : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DescribeIndexFields.html',
        defaults : {
            Action : 'DescribeIndexFields'
        },
        args : {
            Action     : required,
            DomainName : required,
            FieldNames : optionalArray,
        },
    },

    DescribeRankExpressions : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DescribeRankExpressions.html',
        defaults : {
            Action : 'DescribeRankExpressions'
        },
        args : {
            Action     : required,
            DomainName : required,
            RankNames  : optionalArray,
        },
    },

    DescribeServiceAccessPolicies : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DescribeServiceAccessPolicies.html',
        defaults : {
            Action : 'DescribeServiceAccessPolicies'
        },
        args : {
            Action     : required,
            DomainName : required,
        },
    },

    DescribeStemmingOptions : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DescribeStemmingOptions.html',
        defaults : {
            Action : 'DescribeStemmingOptions'
        },
        args : {
            Action     : required,
            DomainName : required,
        },
    },

    DescribeStopwordOptions : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DescribeStopwordOptions.html',
        defaults : {
            Action : 'DescribeStopwordOptions'
        },
        args : {
            Action     : required,
            DomainName : required,
        },
    },

    DescribeSynonymOptions : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_DescribeSynonymOptions.html',
        defaults : {
            Action : 'DescribeSynonymOptions'
        },
        args : {
            Action     : required,
            DomainName : required,
        },
    },

    IndexDocuments : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_IndexDocuments.html',
        defaults : {
            Action : 'IndexDocuments'
        },
        args : {
            Action     : required,
            DomainName : required,
        },
    },

    UpdateDefaultSearchField : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_UpdateDefaultSearchField.html',
        defaults : {
            Action : 'UpdateDefaultSearchField'
        },
        args : {
            Action             : required,
            DefaultSearchField : required,
            DomainName         : required,
        },
    },

    UpdateServiceAccessPolicies : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_UpdateServiceAccessPolicies.html',
        defaults : {
            Action : 'UpdateServiceAccessPolicies'
        },
        args : {
            Action         : required,
            AccessPolicies : requiredJson,
            DomainName     : required,
        },
    },

    UpdateStemmingOptions : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_UpdateStemmingOptions.html',
        defaults : {
            Action : 'UpdateStemmingOptions'
        },
        args : {
            Action     : required,
            DomainName : required,
            Stems      : requiredJson,
        },
    },

    UpdateStopwordOptions : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_UpdateStopwordOptions.html',
        defaults : {
            Action : 'UpdateStopwordOptions'
        },
        args : {
            Action     : required,
            DomainName : required,
            Stopwords  : requiredJson,
        },
    },

    UpdateSynonymOptions : {
        url : 'http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/API_UpdateSynonymOptions.html',
        defaults : {
            Action : 'UpdateSynonymOptions'
        },
        args : {
            Action     : required,
            DomainName : required,
            Synonyms   : requiredJson,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
