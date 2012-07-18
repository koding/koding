require('../spec_helper');

var _ = require('underscore')._,
    braintree = specHelper.braintree;

vows.describe('AddressGateway').addBatch({
  'create': {
    'adding an address to an existing customer': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {},
          function (err, response) {
            specHelper.defaultGateway.address.create({
              customerId: response.customer.id,
              streetAddress: '123 Fake St',
              extendedAddress: 'Suite 403',
              locality: 'Chicago',
              region: 'IL',
              postalCode: '60607',
              countryName: 'United States of America'
            }, callback);
          }
        );
      },
      'is succesful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, true);
      },
      'returns the address': function (err, result) {
        assert.equal(result.address.streetAddress, '123 Fake St');
        assert.equal(result.address.extendedAddress, 'Suite 403');
        assert.equal(result.address.locality, 'Chicago');
        assert.equal(result.address.region, 'IL');
        assert.equal(result.address.postalCode, '60607');
        assert.equal(result.address.countryName, 'United States of America');
      }
    },

    'with invalid params': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {},
          function (err, response) {
            specHelper.defaultGateway.address.create({
              customerId: response.customer.id,
              countryName: 'invalid country'
            }, callback);
          }
        )
      },
      'is not successful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, false);
      },
      'returns an error message': function (err, response) {
        assert.equal(response.message, 'Country name is not an accepted country.');
      },
      'has an error on countryName': function (err, response) {
        assert.equal(response.errors.for('address').on('countryName')[0].code, '91803');
        assert.equal(response.errors.for('address').on('countryName')[0].attribute, 'country_name');
      },
      'returns deepErrors': function (err, response) {
        var errorCodes = _.map(response.errors.deepErrors(), function (error) { return error.code; });
        assert.equal(1, errorCodes.length);
        assert.include(errorCodes, '91803');
      }
    }
  },

  'delete': {
    'deleting an existing address': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {},
          function (err, response) {
            specHelper.defaultGateway.address.create({
              customerId: response.customer.id,
              countryName: 'United States of America'
            }, function (err, response) {
              specHelper.defaultGateway.address.delete(response.address.customerId, response.address.id, function (err) {
                specHelper.defaultGateway.address.find(response.address.customerId, response.address.id, callback);
              });
            });
          }
        );
      },
      'deletes the address': function (err, address) {
        assert.isUndefined(address);
        assert.equal(err.type, braintree.errorTypes.notFoundError);
      }
    }
  },

  'find': {
    'finding an existing address': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {},
          function (err, response) {
            specHelper.defaultGateway.address.create({
              customerId: response.customer.id,
              streetAddress: '123 Fake St',
              extendedAddress: 'Suite 403',
              locality: 'Chicago',
              region: 'IL',
              postalCode: '60607',
              countryName: 'United States of America'
            }, function (err, response) {
              specHelper.defaultGateway.address.find(response.address.customerId, response.address.id, callback);
            });
          }
        );
      },
      'does not have an error': function (err, address) {
        assert.isNull(err);
      },
      'returns the address': function (err, address) {
        assert.equal(address.streetAddress, '123 Fake St');
        assert.equal(address.extendedAddress, 'Suite 403');
        assert.equal(address.locality, 'Chicago');
        assert.equal(address.region, 'IL');
        assert.equal(address.postalCode, '60607');
        assert.equal(address.countryName, 'United States of America');
      }
    },

    'when the address cant be found': {
      topic: function () {
        specHelper.defaultGateway.address.find("not-existent-customer", "id", this.callback);
      },
      'returns a not found error': function (err, address) {
        assert.equal(err.type, braintree.errorTypes.notFoundError);
      },
      'does not return an address': function (err, address) {
        assert.isUndefined(address);
      }
    }
  },

  'update': {
    'update an existing address': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {},
          function (err, response) {
            specHelper.defaultGateway.address.create({
              customerId: response.customer.id,
              streetAddress: '1 Old Street',
              extendedAddress: 'Old Extended',
              locality: 'Old City',
              region: 'Old State',
              postalCode: '60607',
              countryName: 'France'
            }, function (err, response) {
              specHelper.defaultGateway.address.update(
                response.address.customerId,
                response.address.id,
                {
                  streetAddress: '1 New Street',
                  extendedAddress: 'New Extended',
                  locality: 'New City',
                  region: 'New State',
                  postalCode: '60630',
                  countryName: 'United States of America'
                },
                callback
              )
            });
          }
        );
      },
      'is succesful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, true);
      },
      'returns the updated address': function (err, result) {
        assert.equal(result.address.streetAddress, '1 New Street');
        assert.equal(result.address.extendedAddress, 'New Extended');
        assert.equal(result.address.locality, 'New City');
        assert.equal(result.address.region, 'New State');
        assert.equal(result.address.postalCode, '60630');
        assert.equal(result.address.countryName, 'United States of America');
      }
    },

    'with invalid params': {
      topic: function () {
        var callback = this.callback;
        specHelper.defaultGateway.customer.create(
          {},
          function (err, response) {
            specHelper.defaultGateway.address.create({
              customerId: response.customer.id,
              streetAddress: '1 Old Street',
              extendedAddress: 'Old Extended',
              locality: 'Old City',
              region: 'Old State',
              postalCode: '60607',
              countryName: 'France'
            }, function (err, response) {
              specHelper.defaultGateway.address.update(
                response.address.customerId,
                response.address.id,
                { countryName: 'invalid country' },
                callback
              )
            });
          }
        );
      },
      'is not successful': function (err, response) {
        assert.isNull(err);
        assert.equal(response.success, false);
      },
      'returns an error message': function (err, response) {
        assert.equal(response.message, 'Country name is not an accepted country.');
      },
      'has an error on countryName': function (err, response) {
        assert.equal(response.errors.for('address').on('countryName')[0].code, '91803');
        assert.equal(response.errors.for('address').on('countryName')[0].attribute, 'country_name');
      },
      'returns deepErrors': function (err, response) {
        var errorCodes = _.map(response.errors.deepErrors(), function (error) { return error.code; });
        assert.equal(1, errorCodes.length);
        assert.include(errorCodes, '91803');
      }
    }
  },
}).export(module);
