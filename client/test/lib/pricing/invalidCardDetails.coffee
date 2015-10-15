helpers = require '../helpers/helpers.js'


module.exports = 

  checkInvalidCardNumber: (browser) ->

    helpers.beginTest(browser)
    helpers.checkInvalidCardDetails(browser, {cardNumber: "1111 1111 1111 1111"}, false)

  checkInvalidCVC: (browser) ->

    helpers.beginTest(browser)
    helpers.checkInvalidCardDetails(browser, {cvc: 12345}, false)

  checkInvalidExpirationMonth: (browser) ->

    helpers.beginTest(browser)
    helpers.checkInvalidCardDetails(browser, {month: 13}, false)

  checkInvalidExpirationYear: (browser) ->

    helpers.beginTest(browser)
    helpers.checkInvalidCardDetails(browser, {year: 1999}, false)

  checkUpgradePlanButtonWithInvalidData: (browser) ->

    helpers.beginTest(browser)
    helpers.checkInvalidCardDetails(browser, {cardNumber: '11111111111', cvc: 12345, month: 13, year: 1999}, false)