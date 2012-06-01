require('../spec_helper');
var Util = require('../../lib/braintree/util').Util;

vows.describe('Util').addBatch({
  'convertObjectKeysToUnderscores': {
    'object with camel case keys': {
      topic: Util.convertObjectKeysToUnderscores({
        topLevel: {
          nestedOne: {
            nestedTwo: 'aValue'
          }
        }
      }),
      'is converted to underscores': function (result) {
        assert.equal(result.top_level.nested_one.nested_two, 'aValue');
      }
    },

    'objects containing date values': {
      topic: Util.convertObjectKeysToUnderscores({
        someDate: new Date()
      }),
      'does not affect the date': function (result) {
        assert.instanceOf(result.some_date, Date);
      }
    },

    'object with an array with objects with camel case keys': {
      topic: Util.convertObjectKeysToUnderscores({
        topLevel: {
          things: [
            { camelOne: 'value1', camelTwo: 'value2' },
            { camelOne: 'value3', camelTwo: 'value4' }
          ]
        }
      }),
      'converts array items to underscores': function (result) {
        assert.isArray(result.top_level.things);
        assert.equal(result.top_level.things[0].camel_one, 'value1');
        assert.equal(result.top_level.things[0].camel_two, 'value2');
        assert.equal(result.top_level.things[1].camel_one, 'value3');
        assert.equal(result.top_level.things[1].camel_two, 'value4');
      }
    }
  },

  'toCamelCase': {
    'string with underscores': {
      topic: Util.toCamelCase('one_two_three'),
      'is converted to camel case': function (result) {
        assert.equal(result, 'oneTwoThree');
      }
    },

    'string with hyphens': {
      topic: Util.toCamelCase('one-two-three'),
      'is converted to camel case': function (result) {
        assert.equal(result, 'oneTwoThree');
      }
    },
    'string with hyphen followed by a number': {
      topic: Util.toCamelCase('last-4'),
      'removes the hyphen': function (result) {
        assert.equal(result, 'last4');
      }
    }
  },

  'toUnderscore': {
    'string that is camel case': {
      topic: Util.toUnderscore('oneTwoThree'),
      'is converted to underscores': function (result) {
        assert.equal(result, 'one_two_three');
      }
    },
  }
}).export(module);

