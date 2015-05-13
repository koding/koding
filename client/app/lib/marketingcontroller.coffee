$            = require 'jquery'
kd           = require 'kd'
KDController = kd.Controller
kookies      = require 'kookies'
checkFlag    = require 'app/util/checkFlag'

###*
 * A controller for managing marketing snippets. It loads snippets config
 * and has methods to get snippet randomly and by given name.
 * By default snippets are available for super admin
###
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


  ###*
   * Method is called when config data is received from the server.
   * It saves snippets data from config and tries to get already shown
   * snippets from the cookie
   *
   * @param {object} response - config data
  ###
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


  ###*
   * Method returns url of randomly selected snippet. It works only if snippets config
   * was loaded successfully and current user is super admin.
   * Snippet selection is based on snippet weights specified in config. If weight is 0, snippet can't
   * be selected. Snippet with greater weight will be selected more often than the one with smaller
   * weight.
   * Number of times snippet was selected is saved to cookie. So if user reloads the page,
   * historical data will be taken into account when calculating snippet weights
   *
   * @return {string} - url of selected snippet
  ###
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


  ###*
   * Method emits event to tell that snippet needs to be shown with specified url.
   * It doesn't have a check that current user is admin and usually it's called
   * from console to debug snippets on UI
   *
   * @param {string} snippet - name of snippet
   * @emits SnippetNeedsToBeShown
  ###
  show: (snippet) ->

    return kd.log "MarketingController: couldn't show unknown snippet '#{snippet}'"  unless @snippets[snippet]
    @emit 'SnippetNeedsToBeShown', @buildSnippetUrl snippet


  ###*
   * Method builds snippet url using url template and snippet name
   *
   * @param {string} snippet - name of snippet
   * @return {string} - snippet url
  ###
  buildSnippetUrl: (snippet) -> "/-/content-rotator/snippets/#{snippet}"


  ###*
   * Method checks if marketing functionality is available for current user
   *
   * @return {bool}
  ###
  isEnabled: -> checkFlag 'super-admin'