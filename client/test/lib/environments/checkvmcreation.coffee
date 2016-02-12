environmentHelpers = require '../helpers/environmenthelpers.js'
helpers = require '../helpers/helpers.js'
assert  = require 'assert'

module.exports =


  createNewVmForHobbyistPlan: (browser) ->

    hobbyistPlanSelector = '.single-plan.hobbyist.current'
    url                  = helpers.getUrl()

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', hobbyistPlanSelector, (result) ->
        if result.status is -1
          helpers.selectPlan(browser, 'hobbyist')
          helpers.fillPaymentForm(browser, 'hobbyist')
          helpers.submitForm(browser, yes, yes)
          environmentHelpers.createNewVmForHobbyistPlan(browser)
          browser.end()
        else
          browser.url url
          environmentHelpers.createNewVmForHobbyistPlan(browser)
          browser.end()


  checkAlwaysOnVmForHobbyistPlan: (browser) ->

    hobbyistPlanSelector = '.single-plan.hobbyist.current'
    sidebarSelector      = '.kdview.sidebar-machine-box .vm'
    alwaysOnSelector     = '.kdinput.koding-on-off.statustoggle.small'
    url                  = helpers.getUrl()

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', hobbyistPlanSelector, (result) ->
        if result.status is -1
          helpers.selectPlan(browser, 'hobbyist')
          helpers.fillPaymentForm(browser, 'hobbyist')
          helpers.submitForm(browser, yes, yes)
        else
          browser.url url

    browser
      .moveToElement          sidebarSelector, 10, 10
      .waitForElementVisible  "#{sidebarSelector} span", 20000
      .click                  "#{sidebarSelector} span"
      .waitForElementVisible  "#{alwaysOnSelector}.off", 20000
      .click                  "#{alwaysOnSelector}.off"
      .waitForElementVisible  "#{alwaysOnSelector}.on", 20000
      .end()


  checkMaximum3VmsForDeveloperPlan: (browser) ->

    developerPlanSelector   = '.single-plan.developer.current'
    freePlan                = '.single-plan.free.current'
    vmSelector              = '.activity-sidebar .machines-wrapper .vms.my-machines .koding-vm-'
    vmSelector1             = "#{vmSelector}1"
    vmSelector2             = "#{vmSelector}2"
    usageVmSelector         = '.kdview.storage-container .kdview:nth-of-type(3)'
    existingPaymentSelector = '.payment-modal.kddraggable .existing-cc-msg'
    paymentButton           = '.kdview.payment-form-wrapper .submit-btn'
    url                     = helpers.getUrl()

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', freePlan, (result) ->
        if result.status is 0
          helpers.selectPlan(browser)
          helpers.fillPaymentForm(browser)
          helpers.submitForm(browser, yes, yes)
        else
          browser.element 'css selector', developerPlanSelector, (result) ->
            if result.status is -1
              helpers.selectPlan(browser)
              browser
               .waitForElementVisible  existingPaymentSelector, 20000
               .assert.containsText    existingPaymentSelector, 'We will use the payment method saved on your account for this purchase.'
               .waitForElementVisible  paymentButton, 20000
               .click                  paymentButton
              browser.expect.element('.kddraggable .kdmodal-inner .kdmodal-title').text.to.contain('Upgrade successful.').before(30000);
              browser.click            paymentButton

    browser.url url
    environmentHelpers.addNewVM(browser, vmSelector1)
    environmentHelpers.addNewVM(browser, vmSelector2)
    environmentHelpers.addNewVM(browser, usageVmSelector, yes)
    browser.end()
