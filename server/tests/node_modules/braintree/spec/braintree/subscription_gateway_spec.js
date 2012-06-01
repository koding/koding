require('../spec_helper');
dateFormat = require('dateformat')

var _ = require('underscore')._,
    braintree = specHelper.braintree;

vows.describe('SubscriptionGateway').addBatch({
  'cancel': {
    'when the subscription can be canceled': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          function (err, result) {
            specHelper.defaultGateway.subscription.create(
              {
                paymentMethodToken: result.customer.creditCards[0].token,
                planId: specHelper.plans.trialless.id
              },
              function (err, result) {
                specHelper.defaultGateway.subscription.cancel(result.subscription.id, callback);
              }
            );
          }
        );
      },
      'does not have an error': function (err, response) { assert.isNull(err); },
      'is succesful': function (err, response) { assert.equal(response.success, true); },
      'cancels the subscription': function (err, result) {
        assert.equal(result.subscription.status, 'Canceled');
      }
    },
    'when the subscription cannot be canceled': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          function (err, result) {
            specHelper.defaultGateway.subscription.create(
              {
                paymentMethodToken: result.customer.creditCards[0].token,
                planId: specHelper.plans.trialless.id
              },
              function (err, result) {
                specHelper.defaultGateway.subscription.cancel(result.subscription.id, function (err, result) {
                  specHelper.defaultGateway.subscription.cancel(result.subscription.id, callback);
                });
              }
            );
          }
        );
      },
      'is unsuccessful': function (err, response) { assert.equal(response.success, false); },
      'has a unified message': function (err, response) {
        assert.equal(response.message, 'Subscription has already been canceled.');
      },
      'has an error on base': function (err, response) {
        assert.equal(response.errors.for('subscription').on('status')[0].code, '81905');
      },
    },
    'when the subscription cannot be found': {
      topic: function () {
        specHelper.defaultGateway.subscription.cancel('nonexistent_subscription', this.callback);
      },
      'has a not found error': function (err, response) {
        assert.equal(err.type, braintree.errorTypes.notFoundError);
      },
    }
  },

  'create': {
    'using a payment method token': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          callback
        );
      },

      'for a minimal case': {
        topic: function (result) {
          var callback = this.callback;
          var token = result.customer.creditCards[0].token;
          specHelper.defaultGateway.subscription.create({
            paymentMethodToken: token,
            planId: specHelper.plans.trialless.id
          }, callback);
        },
        'does not have an error': function (err, response) { assert.isNull(err); },
        'is succesful': function (err, response) { assert.equal(response.success, true); },
        'has the expected plan id and amount': function (err, response) {
          assert.equal(response.subscription.planId, specHelper.plans.trialless.id);
          assert.equal(response.subscription.price, specHelper.plans.trialless.price);
        },
        'returns transactions': function (err, response) {
          assert.match(response.subscription.transactions[0].id, /^\w{6,7}$/);
          assert.equal(response.subscription.transactions[0].creditCard.maskedNumber, '510510******5100');
        }
      },

      'when setting the first billing date': {
        topic: function (result) {
          var callback = this.callback;
          var token = result.customer.creditCards[0].token;
          var firstBillingDate = new Date();
          firstBillingDate.setFullYear(firstBillingDate.getFullYear() + 1);
          specHelper.defaultGateway.subscription.create({
            paymentMethodToken: token,
            planId: specHelper.plans.trialless.id,
            firstBillingDate: firstBillingDate
          }, callback);
        },
        'is succesful': function (err, response) {
          assert.isNull(err);
          assert.equal(response.success, true);
        },
        'has the expected first billing date': function (err, response) {
          var expectedDate = new Date();
          expectedDate.setFullYear(expectedDate.getFullYear() + 1);
          var expectedDateString = dateFormat(expectedDate, 'yyyy-mm-dd', true);

          assert.equal(response.subscription.firstBillingDate, expectedDateString);
        },
      },

      'when the transaction is declined': {
        topic: function (result) {
          var callback = this.callback;
          var token = result.customer.creditCards[0].token;
          specHelper.defaultGateway.subscription.create({
            paymentMethodToken: token,
            planId: specHelper.plans.trialless.id,
            price: '2000.00'
          }, callback);
        },
        'is not succesful': function (err, result) {
          assert.isNull(err);
          assert.equal(result.success, false);
        },
        'returns the transaction on the result': function (err, result) {
          assert.match(result.transaction.id, /^\w{6,7}$/);
          assert.equal(result.transaction.status, 'processor_declined');
          assert.equal(result.transaction.creditCard.maskedNumber, '510510******5100');
        }
      },

      'with inheriting addons and discounts': {
        topic: function (result) {
          var callback = this.callback;
          specHelper.defaultGateway.subscription.create({
            paymentMethodToken: result.customer.creditCards[0].token,
            planId: specHelper.plans.addonDiscountPlan.id

          }, callback);
        },
        'is successful': function (err, result) {
          assert.isNull(err);
          assert.equal(result.success, true);
        },
        'inherits add ons': function (err, result) {
          var addons = _.sortBy(result.subscription.addOns, function (a) { return a.id; });
          assert.equal(addons.length, 2);

          assert.equal(addons[0].id, 'increase_10');
          assert.equal(addons[0].amount, '10.00');
          assert.equal(addons[0].quantity, 1);
          assert.equal(addons[0].numberOfBillingCycles, null);
          assert.equal(addons[0].neverExpires, true);

          assert.equal(addons[1].id, 'increase_20');
          assert.equal(addons[1].amount, '20.00');
          assert.equal(addons[1].quantity, 1);
          assert.equal(addons[1].numberOfBillingCycles, null);
          assert.equal(addons[1].neverExpires, true);
        },
        'inherits discounts': function (err, result) {
          var discounts = _.sortBy(result.subscription.discounts, function (d) { return d.id; });
          assert.equal(discounts.length, 2);

          assert.equal(discounts[0].id, 'discount_11');
          assert.equal(discounts[0].amount, '11.00');
          assert.equal(discounts[0].quantity, 1);
          assert.equal(discounts[0].numberOfBillingCycles, null);
          assert.equal(discounts[0].neverExpires, true);

          assert.equal(discounts[1].id, 'discount_7');
          assert.equal(discounts[1].amount, '7.00');
          assert.equal(discounts[1].quantity, 1);
          assert.equal(discounts[1].numberOfBillingCycles, null);
          assert.equal(discounts[1].neverExpires, true);
        }
      },

      'with validation errors on updates': {
        topic: function (result) {
          var callback = this.callback;
          specHelper.defaultGateway.subscription.create({
            paymentMethodToken: result.customer.creditCards[0].token,
            planId: specHelper.plans.addonDiscountPlan.id,
            addOns: {
              update: [
                { existingId: specHelper.addOns.increase10, amount: 'invalid' },
                { existingId: specHelper.addOns.increase20, quantity: -10 }
              ]
            }

          }, callback);
        },
        'is not successful': function (err, result) {
          assert.isNull(err);
          assert.equal(result.success, false);
        },
        'has errors accessible by array index': function (err, result) {
          assert.equal(result.errors.for('subscription').for('addOns').for('update').forIndex(0).on('amount')[0].code, '92002');
          assert.equal(result.errors.for('subscription').for('addOns').for('update').forIndex(1).on('quantity')[0].code, '92001');
        }
      }
    },

    'with validation errors': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.subscription.create(
          {
            paymentMethodToken: 'invalid_token',
            planId: 'invalid_plan_id'
          },
          callback
        );
      },
      'is unsuccessful': function (err, response) { assert.equal(response.success, false); },
      'has a unified message': function (err, response) {
        var messages = response.message.split("\n");
        assert.equal(messages.length, 2);
        assert.include(messages, 'Payment method token is invalid.');
        assert.include(messages, 'Plan ID is invalid.');
      },
      'has an error on plan id': function (err, response) {
        assert.equal(response.errors.for('subscription').on('planId')[0].code, '91904');
      },
      'has an error on payment method token': function (err, response) {
        assert.equal(response.errors.for('subscription').on('paymentMethodToken')[0].code, '91903');
      },
    }
  },

  'find': {
    'when subscription can be found': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          function (err, result) {
            specHelper.defaultGateway.subscription.create(
              {
                paymentMethodToken: result.customer.creditCards[0].token,
                planId: specHelper.plans.trialless.id
              },
              function (err, result) {
                specHelper.defaultGateway.subscription.find(result.subscription.id, callback);
              }
            );
          }
        );
      },
      'does not have an error': function (err, subscription) { assert.isNull(err); },
      'returns the subscription': function (err, subscription) {
        assert.equal(subscription.planId, specHelper.plans.trialless.id);
        assert.equal(subscription.price, specHelper.plans.trialless.price);
        assert.equal(subscription.status, 'Active');
      }
    },
    'when the subscription cannot be found': {
      topic: function () {
        specHelper.defaultGateway.subscription.find('nonexistent_subscription', this.callback);
      },
      'has a not found error': function (err, response) {
        assert.equal(err.type, braintree.errorTypes.notFoundError);
      },
    }
  },

  'retryCharge': {
    'with an existing subscription': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          callback
        );
      },
      'with only specifying subscription id': {
        topic: function (result) {
          var callback = this.callback;
          specHelper.defaultGateway.subscription.create({
            paymentMethodToken: result.customer.creditCards[0].token,
            planId: specHelper.plans.trialless.id
          }, function (err, result) {
            specHelper.makePastDue(result.subscription, function (err, result) {
              specHelper.defaultGateway.subscription.retryCharge(result.subscription.id, callback)
            });
          });
        },
        'it successful': function (err, result) {
          assert.isNull(err);
          assert.equal(result.success, true);
        },
        'returns the transaction': function (err, result) {
          assert.equal(result.transaction.amount, specHelper.plans.trialless.price);
          assert.equal(result.transaction.type, 'sale');
          assert.equal(result.transaction.status, 'authorized');
        }
      },

      'with specifying subscription id and amount': {
        topic: function (result) {
          var callback = this.callback;
          specHelper.defaultGateway.subscription.create({
            paymentMethodToken: result.customer.creditCards[0].token,
            planId: specHelper.plans.trialless.id
          }, function (err, result) {
            specHelper.makePastDue(result.subscription, function (err, result) {
              specHelper.defaultGateway.subscription.retryCharge(result.subscription.id, '6.00', callback)
            });
          });
        },
        'it successful': function (err, result) {
          assert.isNull(err);
          assert.equal(result.success, true);
        },
        'returns the transaction': function (err, result) {
          assert.equal(result.transaction.amount, '6.00');
          assert.equal(result.transaction.type, 'sale');
          assert.equal(result.transaction.status, 'authorized');
        }
      }
    }
  },

  'update': {
    'when the subscription can be updated': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          function (err, result) {
            specHelper.defaultGateway.subscription.create(
              {
                paymentMethodToken: result.customer.creditCards[0].token,
                planId: specHelper.plans.trialless.id,
                price: '5.00'
              },
              function (err, result) {
                specHelper.defaultGateway.subscription.update(
                  result.subscription.id,
                  { price: '8.00' },
                  callback
                );
              }
            );
          }
        );
      },
      'is succesful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, true);
      },
      'updates the subscription': function (err, result) {
        assert.equal(result.subscription.price, '8.00');
      }
    },

    'when the subscription cannot be updated': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {
            creditCard: {
              number: '5105105105105100',
              expirationDate: '05/12'
            }
          },
          function (err, result) {
            specHelper.defaultGateway.subscription.create(
              {
                paymentMethodToken: result.customer.creditCards[0].token,
                planId: specHelper.plans.trialless.id,
                price: '5.00'
              },
              function (err, result) {
                specHelper.defaultGateway.subscription.update(
                  result.subscription.id,
                  { price: 'invalid' },
                  callback
                );
              }
            );
          }
        );
      },
      'is not succesful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, false);
      },
      'returns validation errors': function (err, result) {
        assert.equal(result.errors.for('subscription').on('price')[0].message, 'Price is an invalid format.');
        assert.equal(result.errors.for('subscription').on('price')[0].code, '81904');
      }
    },
  }
}).export(module);

