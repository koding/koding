require('../spec_helper');
var XmlParser = require('../../lib/braintree/xml_parser').XmlParser;

var CUSTOMER_XML = [
'<?xml version="1.0" encoding="UTF-8"?>',
'<customer>',
'  <id>403123</id>',
'  <merchant-id>integration_merchant_id</merchant-id>',
'  <first-name>Dan</first-name>',
'  <last-name nil="true"></last-name>',
'  <company nil="true"></company>',
'  <email nil="true"></email>',
'  <phone nil="true"></phone>',
'  <fax nil="true"></fax>',
'  <website nil="true"></website>',
'  <created-at type="datetime">2011-05-28T15:13:43Z</created-at>',
'  <updated-at type="datetime">2011-05-28T15:13:43Z</updated-at>',
'  <custom-fields>',
'  </custom-fields>',
'  <credit-cards type="array">',
'    <credit-card>',
'      <bin>510510</bin>',
'      <cardholder-name nil="true"></cardholder-name>',
'      <card-type>MasterCard</card-type>',
'      <created-at type="datetime">2011-05-28T15:13:43Z</created-at>',
'      <customer-id>403123</customer-id>',
'      <default type="boolean">true</default>',
'      <expiration-month>05</expiration-month>',
'      <expiration-year>2012</expiration-year>',
'      <expired type="boolean">false</expired>',
'      <customer-location>US</customer-location>',
'      <last-4>5100</last-4>',
'      <subscriptions type="array"/>',
'      <token>7j5g</token>',
'      <updated-at type="datetime">2011-05-28T15:13:43Z</updated-at>',
'    </credit-card>',
'  </credit-cards>',
'  <addresses type="array"/>',
'</customer>',
].join("\n");

var VALIDATION_ERRORS_XML = [
'<?xml version="1.0" encoding="UTF-8"?>',
'<api-error-response>',
'  <params>',
'    <payment-method-token>invalid_token</payment-method-token>',
'    <plan-id>invalid_plan_id</plan-id>',
'  </params>',
'  <message>Payment method token is invalid.',
'Plan ID is invalid.</message>',
'  <errors>',
'    <subscription>',
'      <add-ons>',
'        <errors type="array"/>',
'      </add-ons>',
'      <discounts>',
'        <errors type="array"/>',
'      </discounts>',
'      <errors type="array">',
'        <error>',
'          <message>Payment method token is invalid.</message>',
'          <code>91903</code>',
'          <attribute type="symbol">payment_method_token</attribute>',
'        </error>',
'        <error>',
'          <message>Plan ID is invalid.</message>',
'          <code>91904</code>',
'          <attribute type="symbol">plan_id</attribute>',
'        </error>',
'      </errors>',
'    </subscription>',
'    <errors type="array"/>',
'  </errors>',
'</api-error-response>',
].join("\n");

vows.describe('XmlParser').addBatch({
  'parse': {
    'parsing customer xml': {
      topic: XmlParser.parse(CUSTOMER_XML),
      'parses customer attributes': function (result) {
        assert.equal(result.customer.id, '403123');
        assert.equal(result.customer.merchantId, 'integration_merchant_id');
        assert.equal(result.customer.firstName, 'Dan');
      },
      'parses nil values': function (result) {
        assert.equal(result.customer.lastName, null);
      },
      'parses boolean values': function (result) {
        assert.equal(result.customer.creditCards[0].default, true);
        assert.equal(result.customer.creditCards[0].expired, false);
      },
      'parses empty arrays': function (result) {
        assert.equal(result.customer.addresses.length, 0);
        assert.isEmptyArray(result.customer.addresses);
      },
      'parses an array of credit cards': function (result) {
        assert.equal(result.customer.creditCards.length, 1);
        var creditCard = result.customer.creditCards[0];
        assert.equal(creditCard.bin, '510510');
        assert.equal(creditCard.cardholderName, null);
        assert.equal(creditCard.cardType, 'MasterCard');
        assert.equal(creditCard.customerId, '403123');
        assert.equal(creditCard.last4, '5100');
        assert.isEmptyArray(creditCard.subscriptions);
      }
    },

    'parsing validation errors on subscriptions': {
      topic: XmlParser.parse(VALIDATION_ERRORS_XML),
      'parses the message': function (result) {
        assert.equal(result.apiErrorResponse.message, "Payment method token is invalid.\nPlan ID is invalid.");
      },
      'parses top level errors': function (result) {
        assert.isEmptyArray(result.apiErrorResponse.errors.errors);
      },
      'parses subscription errors': function (result) {
        var subscriptionErrors = result.apiErrorResponse.errors.subscription.errors;
        assert.isArray(subscriptionErrors);
        assert.equal(subscriptionErrors.length, 2);
        assert.equal(subscriptionErrors[0].message, 'Payment method token is invalid.');
        assert.equal(subscriptionErrors[0].code, '91903');
        assert.equal(subscriptionErrors[0].attribute, 'payment_method_token');
        assert.equal(subscriptionErrors[1].message, 'Plan ID is invalid.');
        assert.equal(subscriptionErrors[1].code, '91904');
        assert.equal(subscriptionErrors[1].attribute, 'plan_id');
      }
    }
  }
}).export(module);

