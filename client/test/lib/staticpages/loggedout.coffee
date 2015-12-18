helpers = require '../helpers/helpers.js'
assert  = require 'assert'
HUBSPOT = no

rootPath        = helpers.getUrl()
legalPageUrl    = rootPath + '/Legal'
pricingPageUrl  = rootPath + '/Pricing'
aboutPageUrl    = rootPath + '/About'
featuresPageUrl = rootPath + '/Features'
activityPageUrl = rootPath + '/Activity/Public/Recent'

hubspotlinkSelector  = '.header .header__logo'
logoSelector         = '[testpath=main-header] a.koding-header-logo'

module.exports =


  suiteName: 'staticpages'


  homePage: (browser) ->

    loginLinkSelector    = 'nav:not(.mobile-menu) [testpath=login-link]'


    browser
      .url(rootPath)
      .maximizeWindow()

      if HUBSPOT
        browser
          .waitForElementVisible  '.hero.block .container', 20000
          .waitForElementVisible  hubspotlinkSelector, 20000

      else
        browser
          .waitForElementVisible logoSelector, 25000
          .waitForElementVisible loginLinkSelector, 25000
          .waitForElementVisible '.login-form.register', 25000

      browser.end()


  legalPage: (browser) ->

    browser.url(legalPageUrl).maximizeWindow()

    if HUBSPOT
      browser
        .waitForElementVisible  '.content #hs_cos_wrapper_legal_hero_headers', 20000
        .waitForElementVisible  hubspotlinkSelector, 20000
    else
      browser
        .waitForElementVisible  '.content-page.legal', 25000
        .waitForElementVisible  logoSelector, 20000

    browser.end()


  pricingPage: (browser) ->

    browser.url(pricingPageUrl).maximizeWindow()

    if HUBSPOT
      browser
        .waitForElementVisible  '.content #hs_cos_wrapper_pricing_menu', 20000
        .waitForElementVisible  hubspotlinkSelector, 20000
    else
      browser
        .waitForElementVisible  '.content-page.pricing', 25000
        .waitForElementVisible  '.content-page.pricing .plans', 25000
        .waitForElementVisible  logoSelector, 20000

    browser.end()


  aboutPage: (browser) ->

    browser.url(aboutPageUrl).maximizeWindow()

    if HUBSPOT
      browser
        .waitForElementVisible  '.content .introduction', 20000
        .waitForElementVisible  hubspotlinkSelector, 20000
    else
      browser
        .waitForElementVisible  '.content-page.about', 25000
        .waitForElementVisible  '.content-page.about .introduction', 25000

    browser.end()


  featuresPage: (browser) ->

    browser.url(featuresPageUrl).maximizeWindow()

    if HUBSPOT
      browser
        .waitForElementVisible  '.content .container', 200000
        .waitForElementVisible  hubspotlinkSelector, 20000
    else
      browser
        .waitForElementVisible  '.content-page.features', 25000
        .waitForElementVisible  '.feature-tabs .tab-handles', 25000
        .waitForElementVisible  '.feature-tabs .tab-contents', 25000

    browser.end()


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
