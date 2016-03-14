helpers = require '../helpers/helpers.js'


module.exports =

  checkInvalidCardNumber: (browser) ->

    helpers.beginTest(browser)
    helpers.checkInvalidCardDetails(browser, { cardNumber: '1111 1111 1111 1111' }, no)


  checkInvalidCVC: (browser) ->

    helpers.beginTest(browser)
    helpers.checkInvalidCardDetails(browser, { cvc: 12345 }, no)


  checkInvalidExpirationMonth: (browser) ->

    helpers.beginTest(browser)
    helpers.checkInvalidCardDetails(browser, { month: 13 }, no)


  checkInvalidExpirationYear: (browser) ->

    helpers.beginTest(browser)
    helpers.checkInvalidCardDetails(browser, { year: 1999 }, no)


  checkUpgradePlanButtonWithInvalidData: (browser) ->

    helpers.beginTest(browser)
    helpers.checkInvalidCardDetails(browser, { cardNumber: '11111111111', cvc: 12345, month: 13, year: 1999 }, no)
