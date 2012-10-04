// --------------------------------------------------------------------------------------------------------------------
//
// fps-config.js - config for Amazon DynamoDB
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var _ = require('underscore');

// --------------------------------------------------------------------------------------------------------------------

var required = {
    'required' : true,
    'type'     : 'param',
};

var optional = {
    'required' : false,
    'type'     : 'param',
};

function requiredWithName(name) {
    return {
        'name'     : name,
        'required' : true,
        'type'     : 'param',
    };
}

function optionalWithName(name) {
    return {
        'name'     : name,
        'required' : false,
        'type'     : 'param',
    };
}

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    Cancel : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/Cancel.html',
        defaults : {
            Action : 'Cancel',
        },
        args : {
            Action         : required,
            Description    : optional,
            OverrideIpnUrl : optionalWithName('OverrideIPNURL'),
            TransactionId  : required,
        },
    },

    CancelToken : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/CancelToken.html',
        defaults : {
            Action : 'CancelToken',
        },
        args : {
            Action         : required,
            OverrideIpnUrl : optionalWithName('OverrideIPNURL'),
            ReasonText     : optional,
            TokenId        : required,
        },
    },

    FundPrepaid : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/FundPrepaid.html',
        defaults : {
            Action : 'FundPrepaid',
        },
        args : {
            Action                              : required,
            CallerDescription                   : optional,
            CallerReference                     : required,
            'DescriptorPolicy.CSOwner'            : optional,
            'DescriptorPolicy.SoftDescriptorType' : optional,
            'FundingAmount.CurrencyCode'          : required,
            'FundingAmount.Value'                 : required,
            OverrideIpnUrl                      : optionalWithName('OverrideIPNURL'),
            PrepaidInstrumentId                 : required,
            SenderDescription                   : optional,
            SenderTokenId                       : required,
            TransactionTimeoutInMins            : optional
        },
    },

    GetAccountActivity : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetAccountActivity.html',
        defaults : {
            Action : 'GetAccountActivity',
        },
        args : {
            Action          : required,
            EndDate         : optional,
            FpsOperation    : optionalWithName('FPSOperation'),
            MaxBatchSize    : optional,
            PaymentMethod   : optional,
            ResponseGroup   : optional,
            Role            : optional,
            SortByDateOrder : optional,
            StartDate       : required,
            Status          : optional,
        },
    },

    GetAccountBalance : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetAccountBalance.html',
        defaults : {
            Action : 'GetAccountBalance',
        },
        args : {
            Action : required,
        },
    },

    GetDebtBalance : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetDebtBalance.html',
        defaults : {
            Action : 'GetDebtBalance',
        },
        args : {
            Action             : required,
            CreditInstrumentId : required,
        },
    },

    GetOutstandingDebtBalance : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetOutstandingDebtBalance.html',
        defaults : {
            Action : 'GetOutstandingDebtBalance',
        },
        args : {
            Action : required,
        },
    },

    GetPrepaidDebtBalance : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetPrepaidBalance.html',
        defaults : {
            Action : 'GetPrepaidDebtBalance',
        },
        args : {
            Action              : required,
            PrepaidInstrumentId : required,
        },
    },

    GetRecipientVerificationStatus : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetRecipientVerificationStatus.html',
        defaults : {
            Action : 'GetRecipientVerificationStatus',
        },
        args : {
            Action           : required,
            RecipientTokenId : required,
        },
    },

    GetTokens : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetTokens.html',
        defaults : {
            Action : 'GetTokens',
        },
        args : {
            Action          : required,
            CallerReference : optional,
            TokenStatus     : optional,
            TokenType       : optional,
        },
    },

    GetTokensByCaller : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetTokensByCaller.html',
        defaults : {
            Action : 'GetTokensByCaller',
        },
        args : {
            Action          : required,
            CallerReference : optional,
            TokenId         : optional,
        },
    },

    GetTokenUsage : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetTokenUsage.html',
        defaults : {
            Action : 'GetTokenUsage',
        },
        args : {
            Action  : required,
            TokenId : optional,
        },
    },

    GetTotalPrepaidLiability : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetTotalPrepaidLiability.html',
        defaults : {
            Action : 'GetTotalPrepaidLiability',
        },
        args : {
            Action  : required,
        },
    },

    GetTransaction : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetTransaction.html',
        defaults : {
            Action : 'GetTransaction',
        },
        args : {
            Action        : required,
            TransactionId : required,
        },
    },

    GetTransactionStatus : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/GetTransactionStatus.html',
        defaults : {
            Action : 'GetTransactionStatus',
        },
        args : {
            Action        : required,
            TransactionId : required,
        },
    },

    Pay : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/Pay.html',
        defaults : {
            Action : 'Pay',
        },
        args : {
            Action                   : required,
            CallerDescription        : optional,
            CallerReference          : required,
            ChargeFeeTo              : optional,
            'DescriptorPolicy.CsOwner'            : optional,
            'DescriptorPolicy.SoftDescriptorType' : optional,
            MarketplaceFixedFee      : optional,
            MarketplaceVariableFee   : optional,
            OverrideIpnUrl           : optionalWithName('OverrideIPNURL'),
            RecipientTokenId         : optional,
            SenderDescription        : optional,
            SenderTokenId            : required,
            TransactionAmount        : required,
            TransactionTimeoutInMins : optional,
        },
    },

    Refund : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/Refund.html',
        defaults : {
            Action : 'Refund',
        },
        args : {
            Action                   : required,
            CallerDescription        : optional,
            CallerReference          : required,
            OverrideIpnUrl           : optionalWithName('OverrideIPNURL'),
            RefundAmount             : optional,
            TransactionId            : required,
            MarketplaceRefundPolicy  : optional,
        },
    },

    Reserve : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/Reserve.html',
        defaults : {
            Action : 'Reserve',
        },
        args : {
            Action                   : required,
            CallerDescription        : optional,
            CallerReference          : required,
            ChargeFeeTo              : optional,
            'DescriptorPolicy.CsOwner'            : optional,
            'DescriptorPolicy.SoftDescriptorType' : optional,
            MarketplaceFixedFee      : optional,
            MarketplaceVariableFee   : optional,
            OverrideIpnUrl           : optionalWithName('OverrideIPNURL'),
            RecipientTokenId         : optional,
            SenderDescription        : optional,
            SenderTokenId            : required,
            TransactionAmount        : required,
            TransactionTimeoutInMins : optional,
        },
    },

    Settle : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/Settle.html',
        defaults : {
            Action : 'Settle',
        },
        args : {
            Action                   : required,
            OverrideIpnUrl           : optionalWithName('OverrideIPNURL'),
            ReserveTransactionId     : required,
            TransactionAmount        : required,
        },
    },

    SettleDebt : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/SettleDebt.html',
        defaults : {
            Action : 'SettleDebt',
        },
        args : {
            Action                   : required,
            CallerDescription        : optional,
            CallerReference          : required,
            CreditInstrumentId       : required,
            'DescriptorPolicy.CsOwner'            : optional,
            'DescriptorPolicy.SoftDescriptorType' : optional,
            OverrideIpnUrl           : optionalWithName('OverrideIPNURL'),
            SenderDescription        : optional,
            SenderTokenId            : required,
            SettlementAmount         : required,
            TransactionTimeoutInMins : optional,
        },
    },

    VerifySignature : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/VerifySignatureAPI.html',
        defaults : {
            Action : 'VerifySignature',
        },
        args : {
            Action         : required,
            UrlEndPoint    : required,
            HttpParameters : required,
        },
    },

    WriteOffDebt : {
        url : 'http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/WriteOffDebt.html',
        defaults : {
            Action : 'WriteOffDebt',
        },
        args : {
            Action             : required,
            AdjustmentAmount   : required,
            CallerDescription  : optional,
            CallerReference    : required,
            CreditInstrumentId : required,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
