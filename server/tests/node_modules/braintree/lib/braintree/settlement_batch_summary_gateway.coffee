{Gateway} = require('./gateway')
{Util} = require('./util')
{SettlementBatchSummary} = require('./settlement_batch_summary')

class SettlementBatchSummaryGateway extends Gateway
  constructor: (@gateway) ->

  generate: (criteria, callback) ->
    @gateway.http.post(
      "/settlement_batch_summary",
      {settlementBatchSummary: criteria},
      @responseHandler(criteria, callback)
    )

  responseHandler: (criteria, callback) ->
    @createResponseHandler "settlementBatchSummary", SettlementBatchSummary, (err, response) =>
      callback(null, @underscoreCustomField(criteria, response))

  underscoreCustomField: (criteria, response) ->
    if response.success and ('groupByCustomField' of criteria)
      camelCustomField = Util.toCamelCase(criteria.groupByCustomField)
      for record in response.settlementBatchSummary.records
        record[criteria.groupByCustomField] = record[camelCustomField]
        record[camelCustomField] = null

    response

exports.SettlementBatchSummaryGateway = SettlementBatchSummaryGateway
