helpers = require '../helpers/helpers.js'

rootPath        = helpers.getUrl()

pages = [
  "#{rootPath}/"
  "#{rootPath}/features"
  "#{rootPath}/features/ide"
  "#{rootPath}/features/terminal"
  "#{rootPath}/features/community"
  "#{rootPath}/pricing/teams"
  "#{rootPath}/pricing/individuals"
  "#{rootPath}/about"
  "#{rootPath}/legal"
  "#{rootPath}/legal/privacy"
  "#{rootPath}/legal/terms"
  "#{rootPath}/legal/copyright"
]

module.exports =

  suiteName: 'hubspot'

  openHubspotPages: (browser) ->

    for page in pages
      browser
        .url(page)
        .maximizeWindow()
        .waitForElementVisible '.footer__logo', 25000

    browser.end()


require('../helpers/hooks.js').init(module.exports)
