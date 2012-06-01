require('../spec_helper');

var _ = require('underscore')._,
    braintree = specHelper.braintree;

var createTransactionToRefund = function (callback) {
  var callback = callback;
  specHelper.defaultGateway.transaction.sale(
    {
      amount: '5.00',
      creditCard: {
        number: '5105105105105100',
        expirationDate: '05/12'
      },
      options: { submitForSettlement: true }
    },
    function (err, result) {
      specHelper.settleTransaction(result.transaction.id, function (err, settleResult) {
        specHelper.defaultGateway.transaction.find(result.transaction.id, function (err, transaction) {
          callback(transaction);
        });
      });
    }
  )
};

vows.describe('TransactionGateway').addBatch({
  'credit': {
    'for a minimal case': {
      topic: function () {
        specHelper.defaultGateway.transaction.credit({
          amount: '5.00',
          creditCard: {
            number: '5105105105105100',
            expirationDate: '05/12'
          }
        }, this.callback);
      },
      'does not have an error': function (err, response) { assert.isNull(err); },
      'is succesful': function (err, response) { assert.equal(response.success, true); },
      'is a credit': function (err, response) { assert.equal(response.transaction.type, 'credit'); },
      'is for 5.00': function (err, response) { assert.equal(response.transaction.amount, '5.00'); },
      'has a masked number of 510510******5100': function (err, response) {
        assert.equal(response.transaction.creditCard.maskedNumber, '510510******5100');
      }
    },

    'with errors': {
      topic: function () {
        specHelper.defaultGateway.transaction.credit({
          creditCard: {
            number: '5105105105105100'
          }
        }, this.callback);
      },
      'is unsuccessful': function (err, response) { assert.equal(response.success, false); },
      'has a unified message': function (err, response) {
        assert.equal(response.message, 'Amount is required.\nExpiration date is required.');
      },
      'has an error on amount': function (err, response) {
        assert.equal(
          response.errors.for('transaction').on('amount')[0].code,
          '81502'
        );
      },
      'has an attribute on ValidationError objects': function (err, response) {
        assert.equal(
          response.errors.for('transaction').on('amount')[0].attribute,
          'amount'
        );
      },
      'has a nested error on creditCard.expirationDate': function (err, response) {
        assert.equal(
          response.errors.for('transaction').for('creditCard').on('expirationDate')[0].code,
          '81709'
        );
      },
      'returns deepErrors': function (err, response) {
        var errorCodes = _.map(response.errors.deepErrors(), function (error) { return error.code; });
        assert.equal(2, errorCodes.length);
        assert.include(errorCodes, '81502');
        assert.include(errorCodes, '81709');
      }
    }
  },

  'sale': {
    'for a minimal case': {
      topic: function () {
        specHelper.defaultGateway.transaction.sale({
          amount: '5.00',
          creditCard: {
            number: '5105105105105100',
            expirationDate: '05/12'
          }
        }, this.callback);
      },
      'does not have an error': function (err, response) { assert.isNull(err); },
      'is succesful': function (err, response) { assert.equal(response.success, true); },
      'is a sale': function (err, response) { assert.equal(response.transaction.type, 'sale'); },
      'is for 5.00': function (err, response) { assert.equal(response.transaction.amount, '5.00'); },
      'has a masked number of 510510******5100': function (err, response) {
        assert.equal(response.transaction.creditCard.maskedNumber, '510510******5100');
      }
    },

    'using a customer from the vault': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {
            firstName: 'Adam',
            lastName: 'Jones',
            creditCard: {
              cardholderName: 'Adam Jones',
              number: '5105105105105100',
              expirationDate: '05/2014'
            }
          },
          function (err, result) {
            specHelper.defaultGateway.transaction.sale({
              customer_id: result.customer.id,
              amount: '100.00'
            }, callback);
          }
        );
      },
      'does not have an error': function (err, response) { assert.isNull(err); },
      'is succesful': function (err, response) { assert.equal(response.success, true); },
      'is a sale': function (err, response) { assert.equal(response.transaction.type, 'sale'); },
      'snapshots customer details': function (err, response) {
        assert.equal(response.transaction.customer.firstName, 'Adam');
        assert.equal(response.transaction.customer.lastName, 'Jones');
      },
      'snapshots credit card details': function (err, response) {
        assert.equal(response.transaction.creditCard.cardholderName, 'Adam Jones');
        assert.equal(response.transaction.creditCard.maskedNumber, '510510******5100');
        assert.equal(response.transaction.creditCard.expirationDate, '05/2014');
      }
    },

    'using a credit card from the vault': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {
            firstName: 'Adam',
            lastName: 'Jones',
            creditCard: {
              cardholderName: 'Adam Jones',
              number: '5105105105105100',
              expirationDate: '05/2014'
            }
          },
          function (err, result) {
            specHelper.defaultGateway.transaction.sale({
              payment_method_token: result.customer.creditCards[0].token,
              amount: '100.00'
            }, callback);
          }
        );
      },
      'does not have an error': function (err, response) { assert.isNull(err); },
      'is succesful': function (err, response) { assert.equal(response.success, true); },
      'is a sale': function (err, response) { assert.equal(response.transaction.type, 'sale'); },
      'snapshots customer details': function (err, response) {
        assert.equal(response.transaction.customer.firstName, 'Adam');
        assert.equal(response.transaction.customer.lastName, 'Jones');
      },
      'snapshots credit card details': function (err, response) {
        assert.equal(response.transaction.creditCard.cardholderName, 'Adam Jones');
        assert.equal(response.transaction.creditCard.maskedNumber, '510510******5100');
        assert.equal(response.transaction.creditCard.expirationDate, '05/2014');
      }
    },

    'with the submit for settlement option': {
      topic: function () {
        specHelper.defaultGateway.transaction.sale({
          amount: '5.00',
          creditCard: {
            number: '5105105105105100',
            expirationDate: '05/12'
          },
          options: {
            submitForSettlement: true
          }
        }, this.callback);
      },
      'is succesful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, true);
      },
      'submits the transaction for settlement': function (err, response) {
        assert.equal(response.transaction.status, 'submitted_for_settlement');
      }
    },

    'with the store in vault option': {
      topic: function () {
        specHelper.defaultGateway.transaction.sale({
          amount: '5.00',
          creditCard: {
            number: '5105105105105100',
            expirationDate: '05/12'
          },
          options: {
            storeInVault: true
          }
        }, this.callback);
      },
      'is succesful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, true);
      },
      'stores the customer and credit card in the vault': function (err, response) {
        assert.match(response.transaction.customer.id, /^\d+$/);
        assert.match(response.transaction.creditCard.token, /^\w+$/);
      }
    },

    'with a custom field': {
      topic: function () {
        specHelper.defaultGateway.transaction.sale({
          amount: '5.00',
          creditCard: {
            number: '5105105105105100',
            expirationDate: '05/12'
          },
          customFields: {
            storeMe: 'custom value'
          }
        }, this.callback);
      },
      'does not have an error': function (err, response) { assert.isNull(err); },
      'is succesful': function (err, response) { assert.equal(response.success, true); },
      'has custom fields in response': function (err, response) {
        assert.equal(response.transaction.customFields.storeMe, 'custom value');
      }
    },

    'when processor declined': {
      topic: function () {
        specHelper.defaultGateway.transaction.sale({
          amount: '2000.00',
          creditCard: {
            number: '5105105105105100',
            expirationDate: '05/12'
          }
        }, this.callback);
      },
      'is unsuccessful': function (err, response) { assert.equal(response.success, false); },
      'has a transaction': function (err, response) {
        assert.equal(response.transaction.amount, '2000.00');
      },
      'has a status of processor_declined': function (err, response) {
        assert.equal(response.transaction.status, 'processor_declined');
      }
    },

    'with errors': {
      topic: function () {
        specHelper.defaultGateway.transaction.sale({
          creditCard: {
            number: '5105105105105100'
          }
        }, this.callback);
      },
      'is unsuccessful': function (err, response) { assert.equal(response.success, false); },
      'has a unified message': function (err, response) {
        assert.equal(response.message, 'Amount is required.\nExpiration date is required.');
      },
      'has an error on amount': function (err, response) {
        assert.equal(
          response.errors.for('transaction').on('amount')[0].code,
          '81502'
        );
      },
      'has an attribute on ValidationError objects': function (err, response) {
        assert.equal(
          response.errors.for('transaction').on('amount')[0].attribute,
          'amount'
        );
      },
      'has a nested error on creditCard.expirationDate': function (err, response) {
        assert.equal(
          response.errors.for('transaction').for('creditCard').on('expirationDate')[0].code,
          '81709'
        );
      },
      'returns deepErrors': function (err, response) {
        var errorCodes = _.map(response.errors.deepErrors(), function (error) { return error.code; });
        assert.equal(2, errorCodes.length);
        assert.include(errorCodes, '81502');
        assert.include(errorCodes, '81709');
      }
    }
  },

  'find': {
    'when found': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.transaction.sale(
          {
            amount: '5.00',
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          function (err, response) {
            specHelper.defaultGateway.transaction.find(response.transaction.id, callback);
          }
        );
      },
      'returns transaction details': function (err, transaction) {
        assert.equal('5.00', transaction.amount);
      }
    },

    'when not found': {
      topic: function () {
        specHelper.defaultGateway.transaction.find('nonexistent_transaction', this.callback);
      },
      'returns a not found error': function (err, response) {
        assert.equal(err.type, braintree.errorTypes.notFoundError);
      }
    },
  },

  'refund': {
    'when the transaction can be refunded': {
      topic: function () {
        var callback = this.callback;
        createTransactionToRefund(function (transaction) {
          specHelper.defaultGateway.transaction.refund(transaction.id, callback);
        });
      },
      'is succesful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, true);
      },
      'creates a credit with a reference to the refunded transaction': function (err, response) {
        assert.equal(response.transaction.type, 'credit');
        assert.match(response.transaction.refund_id, /^\w+$/);
      },
    },

    'for a partial amount': {
      topic: function () {
        var callback = this.callback;
        createTransactionToRefund(function (transaction) {
          specHelper.defaultGateway.transaction.refund(transaction.id, '1.00', callback);
        });
      },
      'is succesful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, true);
      },
      'creates a credit for the given amount': function (err, response) {
        assert.equal(response.transaction.type, 'credit');
        assert.match(response.transaction.refund_id, /^\w+$/);
        assert.equal(response.transaction.amount, '1.00');
      },
    },

    'when transaction cannot be refunded': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.transaction.sale(
          {
            amount: '5.00',
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            },
            options: {
              submitForSettlement: true
            }
          },
          function (err, response) {
            specHelper.defaultGateway.transaction.refund(response.transaction.id, callback);
          }
        )
      },
      'does not have an error': function (err, response) { assert.isNull(err); },
      'is not succesful': function (err, response) { assert.equal(response.success, false); },
      'has error 91507 on base': function (err, response) {
        assert.equal(response.errors.for('transaction').on('base')[0].code, '91506');
      }
    }
  },

  'submitForSettlement': {
    'when submitting an authorized transaction for settlement': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.transaction.sale(
          {
            amount: '5.00',
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          function (err, response) {
            specHelper.defaultGateway.transaction.submitForSettlement(response.transaction.id, callback);
          }
        )
      },
      'is succesful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, true);
      },
      'sets the status to submitted_for_settlement': function (err, response) {
        assert.equal(response.transaction.status, 'submitted_for_settlement');
      },
      'submits the entire amount for settlement': function (err, response) {
        assert.equal(response.transaction.amount, '5.00');
      }
    },

    'when submitted a partial amount for settlement': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.transaction.sale(
          {
            amount: '5.00',
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          function (err, response) {
            specHelper.defaultGateway.transaction.submitForSettlement(response.transaction.id, '3.00', callback);
          }
        )
      },
      'is succesful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, true);
      },
      'sets the status to submitted_for_settlement': function (err, response) {
        assert.equal(response.transaction.status, 'submitted_for_settlement');
      },
      'submits the specified amount for settlement': function (err, response) {
        assert.equal(response.transaction.amount, '3.00');
      }
    },

    'when transaction cannot be submitted for settlement': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.transaction.sale(
          {
            amount: '5.00',
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            },
            options: {
              submitForSettlement: true
            }
          },
          function (err, response) {
            specHelper.defaultGateway.transaction.submitForSettlement(response.transaction.id, callback);
          }
        )
      },
      'does not have an error': function (err, response) { assert.isNull(err); },
      'is not succesful': function (err, response) { assert.equal(response.success, false); },
      'has error 91507 on base': function (err, response) {
        assert.equal(response.errors.for('transaction').on('base')[0].code, '91507');
      }
    }
  },

  'void': {
    'when voiding an authorized transaction': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.transaction.sale(
          {
            amount: '5.00',
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          function (err, response) {
            specHelper.defaultGateway.transaction.void(response.transaction.id, callback);
          }
        )
      },
      'does not have an error': function (err, response) { assert.isNull(err); },
      'is succesful': function (err, response) { assert.equal(response.success, true); },
      'sets the status to voided': function (err, response) { assert.equal(response.transaction.status, 'voided'); },
    },

    'when transaction cannot be voided': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.transaction.sale(
          {
            amount: '5.00',
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          function (err, response) {
            specHelper.defaultGateway.transaction.void(response.transaction.id, function (err, response) {
              specHelper.defaultGateway.transaction.void(response.transaction.id, callback);
            });
          }
        )
      },
      'does not have an error': function (err, response) { assert.isNull(err); },
      'is not succesful': function (err, response) { assert.equal(response.success, false); },
      'has error 91504 on base': function (err, response) {
        assert.equal(response.errors.for('transaction').on('base')[0].code, '91504');
      }
    }
  }
}).export(module);
