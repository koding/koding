{Http} = require('./http')
{AddressGateway} = require("./address_gateway")
{CreditCardGateway} = require("./credit_card_gateway")
{CustomerGateway} = require("./customer_gateway")
{SettlementBatchSummaryGateway} = require("./settlement_batch_summary_gateway")
{SubscriptionGateway} = require("./subscription_gateway")
{TransactionGateway} = require("./transaction_gateway")
{TransparentRedirectGateway} = require("./transparent_redirect_gateway")

class BraintreeGateway
  constructor: (@config) ->
    @http = new Http(@config)
    @address = new AddressGateway(this)
    @creditCard = new CreditCardGateway(this)
    @customer = new CustomerGateway(this)
    @settlementBatchSummary = new SettlementBatchSummaryGateway(this)
    @subscription = new SubscriptionGateway(this)
    @transaction = new TransactionGateway(this)
    @transparentRedirect = new TransparentRedirectGateway(this)

exports.BraintreeGateway = BraintreeGateway
