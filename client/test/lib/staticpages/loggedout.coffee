helpers = require '../helpers/helpers.js'
assert  = require 'assert'

rootPath        = helpers.getUrl()
legalPageUrl    = rootPath + '/Legal'
pricingPageUrl  = rootPath + '/Pricing'
aboutPageUrl    = rootPath + '/About'
featuresPageUrl = rootPath + '/Features'
activityPageUrl = rootPath + '/Activity/Public/Recent'

module.exports =


  suiteName: 'staticpages'


  homePage: (browser) ->

    logoSelector      = '[testpath=main-header] a.koding-header-logo'
    loginLinkSelector = 'nav:not(.mobile-menu) [testpath=login-link]'

    browser
      .url(rootPath)
      .maximizeWindow()
      .waitForElementVisible logoSelector, 25000
      .waitForElementVisible loginLinkSelector, 25000
      .waitForElementVisible '.login-form.register', 25000
      .end()


  legalPage: (browser) ->

    browser.url(legalPageUrl).maximizeWindow()

    browser
      .waitForElementVisible  '.content-page.legal', 25000
      .end()


  pricingPage: (browser) ->

    browser.url(pricingPageUrl).maximizeWindow()

    browser
      .waitForElementVisible  '.content-page.pricing', 25000
      .waitForElementVisible  '.content-page.pricing .plans', 25000
      .end()


  aboutPage: (browser) ->

    browser.url(aboutPageUrl).maximizeWindow()

    browser
      .waitForElementVisible  '.content-page.about', 25000
      .waitForElementVisible  '.content-page.about .introduction', 25000
      .end()


  featuresPage: (browser) ->

    browser.url(featuresPageUrl).maximizeWindow()

    browser
      .waitForElementVisible  '.content-page.features', 25000
      .waitForElementVisible  '.feature-tabs .tab-handles', 25000
      .waitForElementVisible  '.feature-tabs .tab-contents', 25000
      .end()


  activityPage: (browser) ->

    browser.url(activityPageUrl).maximizeWindow()

    browser
      .waitForElementVisible  '#main-sidebar', 25000
      .waitForElementVisible  '#main-sidebar .kdcustomscrollview', 25000
      .waitForElementVisible  '.activity-sidebar', 25000
      .waitForElementVisible  '#main-sidebar .sidebar-join',25000
      .waitForElementVisible  '#main-sidebar .sidebar-bottom-links',25000
      .end()


require('../helpers/hooks.js').init(module.exports)
