$            = require 'jquery'
kd           = require 'kd'
KDController = kd.Controller
kookies      = require 'kookies'
checkFlag    = require 'app/util/checkFlag'

module.exports = class MarketingController extends KDController

  cookieName = 'koding_marketing_snippets'

  constructor: (options = {}, data) ->

    super options, data

    @snippets        = null
    @shownSnippets   = {}

    $.ajax
      url      : '/-/content-rotator/snippets/config.json'
      dataType : "json"
      success  : @bound 'configLoaded'
      error    : =>
        kd.warn 'MarketingController: Couldn\'t load config. Snippets are not available'


  configLoaded: (response) ->

    unless response.snippets
      return kd.warn 'MarketingController: config has incorrect format'

    @snippets = response.snippets

    cookieValue = kookies.get cookieName
    if cookieValue
      try
        @shownSnippets = JSON.parse cookieValue
      catch e
      	return kd.warn 'MarketingController: error while parsing cookie value', e

    @emit 'ready'


  getNextSnippet: ->

    return  unless @snippets and @isEnabled()

    ranges = null
    sum    = 0
    for name, weight of @snippets when weight > 0
      shownTimes = @shownSnippets[name] ? 0
      continue  if shownTimes >= weight

      ranges       = {}  unless ranges
      realWeight   = weight - shownTimes
      ranges[name] =
        minValue : sum + 1
        maxValue : sum += realWeight
      	 
    unless ranges
      @shownSnippets = {}
      return @getNextSnippet()

    minValue = 1
    maxValue = sum
    randomValue = Math.floor(Math.random() * (maxValue - minValue + 1)) + minValue

    snippet = name for name, range of ranges when range.minValue <= randomValue <= range.maxValue

    @shownSnippets[snippet] = (@shownSnippets[snippet] ? 0) + 1
    kookies.set cookieName, JSON.stringify @shownSnippets

    return @buildSnippetUrl snippet


  show: (snippet) ->

    return kd.log "MarketingController: couldn't show unknown snippet '#{snippet}'"  unless @snippets[snippet]
    @emit 'SnippetNeedsToBeShown', @buildSnippetUrl snippet


  buildSnippetUrl: (snippet) -> "/-/content-rotator/snippets/#{snippet}"


  isEnabled: -> checkFlag 'super-admin'