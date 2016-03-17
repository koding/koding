helpers = require '../helpers/helpers.js'
assert  = require 'assert'
HUBSPOT = yes

module.exports =


  becomePaidUser: (browser) ->

    freePlanSelector = '.single-plan.free.current'

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', freePlanSelector, (result) ->
        if result.status is 0
          helpers.selectPlan(browser, 'developer')
          helpers.fillPaymentForm(browser, 'developer')
          helpers.submitForm(browser, yes)
          browser.end()
        else
          browser.end()


  upgradeAccount: (browser) ->

    planType = 'professional'
    selectedPlanSelector = '.single-plan.' + planType + '.current'

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', selectedPlanSelector, (result) ->
        if result.status is 0
          browser.end()
        else
          helpers.selectPlan(browser, planType)

          browser
            .waitForElementVisible   '.payment-modal', 20000
            .click                   '.payment-modal button'
            .waitForElementVisible   '.payment-modal', 20000
            .pause                   5000
            .waitForElementVisible   '.payment-modal button', 20000
            .click                   '.payment-modal button'
            .waitForElementVisible   '[testpath=main-sidebar]', 20000
            .url                     helpers.getUrl() + '/Pricing'
            .waitForElementVisible   '.content-page.pricing', 20000
            .waitForElementVisible   '.single-plan.' + planType + '.current', 20000
            .end()


  downgradeAccount: (browser) ->

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000

    helpers.selectPlan(browser, 'developer')

    browser
      .waitForElementVisible   '.payment-modal', 20000
      .click                   '.payment-modal button'
      .waitForElementVisible   '.payment-modal', 20000
      .pause                   5000
      .click                   '.payment-modal button'
      .waitForElementVisible   '[testpath=main-sidebar]', 20000
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.single-plan.' + 'developer' + '.current', 20000
      .end()


  checkPrices: (browser) ->

    helpers.beginTest(browser)

    hobbyistSelector     = '.hobbyist .plan-price cite'
    developerSelector    = '.developer .plan-price cite'
    professionalSelector = '.professional .plan-price cite'
    buttonSelector       = '.interval-toggle button.clean-gray:not(.toggle)'
    pricingSelector      = '.content-page.pricing section.plans'
    selectBox            = '.interval-toggle .kdselectbox'
    selectBoxArrow       = "#{selectBox} span.arrows"
    monthOption          = "#{selectBox} option[value=month]"

    browser
      .url                    helpers.getUrl() + '/Pricing'
      .waitForElementVisible  '.content-page.pricing', 20000
      .pause                  3000 # wait for pricing page load
      .waitForElementVisible  pricingSelector, 20000
      .waitForElementVisible  hobbyistSelector, 20000
      .assert.containsText    hobbyistSelector, '9.95' # Assertion
      .assert.containsText    developerSelector, '19.95' # Assertion
      .assert.containsText    professionalSelector, '39.95' # Assertion

    if HUBSPOT
      browser
        .waitForElementVisible  selectBox, 20000
        .waitForElementVisible  selectBoxArrow, 20000
        .click                  selectBoxArrow
        .waitForElementVisible  monthOption, 20000
        .click                  monthOption
    else
      browser
        .waitForElementVisible  buttonSelector, 20000
        .click                  buttonSelector

    browser
      .assert.containsText    hobbyistSelector, '12.50' # Assertion
      .assert.containsText    developerSelector, '24.50' # Assertion
      .assert.containsText    professionalSelector, '49.50' # Assertion
      .end()
