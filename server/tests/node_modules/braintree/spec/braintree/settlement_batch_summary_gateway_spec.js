require('../spec_helper');

var _ = require('underscore')._,
   braintree = specHelper.braintree;

vows.describe('SettlementBatchSummaryGateway').addBatch({
  'generate': {
    'when there is no data': {
      topic: function () {
        specHelper.defaultGateway.settlementBatchSummary.generate(
          {settlementDate: "2011-01-01"},
          this.callback
        );
      },

      'is successful': function (err, response) {
        assert.isTrue(response.success);
      },

      'returns an empty array': function (err, response) {
        assert.deepEqual(response.settlementBatchSummary.records, []);
      }
    },

    'if date can not be parsed': {
      topic: function () {
        specHelper.defaultGateway.settlementBatchSummary.generate(
          {settlementDate: "NOT A DATE"},
          this.callback
        );
      },

      'is not successful': function (err, response) {
        assert.isFalse(response.success);
      },

      'has errors on the date': function (err, response) {
        assert.equal(response.errors.for('settlementBatchSummary').on('settlementDate')[0].code, '82302');
        assert.equal(response.errors.for('settlementBatchSummary').on('settlementDate')[0].attribute, 'settlement_date');
      }
    },

    'if given a valid settlement date': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.transaction.credit({
          amount: '5.00',
          creditCard: {
            number: '4111111111111111',
            expirationDate: '05/12'
          }
        }, function (err, response) {
          specHelper.settleTransaction(response.transaction.id, function (err, response) {
            formattedDate = specHelper.dateToMdy(new Date());
            specHelper.defaultGateway.settlementBatchSummary.generate(
              {settlementDate: formattedDate},
              callback
            );
          });
        })
      },

      'is successful': function (err, response) {
        assert.isTrue(response.success);
      },

      'returns transactions on a given day': function (err, response) {
        var records = response.settlementBatchSummary.records
        var visaRecords = _.select(records, function (record) {
          return record['cardType'] === 'Visa';
        });

        assert.ok(visaRecords[0]['count'] >= 1);
        assert.ok(parseFloat(visaRecords[0]['amountSettled']) >= parseFloat("5.00"));
      }
    },

    'if given a custom field to group by': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.transaction.credit({
          amount: '5.00',
          creditCard: {
            number: '4111111111111111',
            expirationDate: '05/12'
          },
          customFields: {
            store_me: 1
          }
        }, function (err, response) {
          specHelper.settleTransaction(response.transaction.id, function (err, response) {
            formattedDate = specHelper.dateToMdy(new Date);
            specHelper.defaultGateway.settlementBatchSummary.generate(
              {settlementDate: formattedDate, groupByCustomField: "store_me"},
              callback
            );
          });
        })
      },

      'is successful': function (err, response) {
        assert.isTrue(response.success);
      },

      'groups by the custom field': function (err, response) {
        var records = response.settlementBatchSummary.records
        assert.ok(records[0]['store_me']);
      }
    }
  }
}).export(module);
