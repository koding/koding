helpers = require '../helpers/helpers.js'

rootPath        = helpers.getUrl()

pages = [
  "#{rootPath}/"
  "#{rootPath}/Features"
  "#{rootPath}/Features/IDE"
  "#{rootPath}/Features/Terminal"
  "#{rootPath}/Features/Community"
  "#{rootPath}/Pricing/Teams"
  "#{rootPath}/Pricing/Individuals"
  "#{rootPath}/About"
  "#{rootPath}/Legal"
  "#{rootPath}/Legal/Privacy"
  "#{rootPath}/Legal/Terms"
  "#{rootPath}/Legal/Copyright"
]

module.exports =

  suiteName: 'hubspot'

  openHubspotPages: (browser) ->

    for page in pages
      browser
        .url(page)
        .maximizeWindow()
        .waitForElementPresent '#hs-analytics', 25000

    browser.end()
