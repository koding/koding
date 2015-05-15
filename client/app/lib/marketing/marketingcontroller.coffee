$                    = require 'jquery'
kd                   = require 'kd'
KDController         = kd.Controller
kookies              = require 'kookies'
checkFlag            = require 'app/util/checkFlag'

MarketingSnippetType = require './marketingsnippettype'


###*
 * A controller for managing marketing snippets.
 * Snippets are available for super admin only
 *
 * @class
###
module.exports = class MarketingController extends KDController

  cookieName = 'koding_marketing_snippets'

  constructor: (options = {}, data) ->

    super options, data

    @snippets      = null
    @shownSnippets = {}

    @loadConfig()


  ###*
    Method loads snippets config from the server.
    It works if current user is super admin
  ###
  loadConfig: ->

    return  unless @isEnabled()

    $.ajax
      url      : @buildUrl 'config.json'
      dataType : "json"
      success  : @bound 'configLoaded'
      error    : ->
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

    if cookieValue = kookies.get cookieName
      try
        @shownSnippets = JSON.parse cookieValue
      catch e
      	return kd.warn 'MarketingController: error while parsing cookie value', e

    @emit 'ready'


  ###*
   * Method selects random snippet, loads its data and passes it in callback. It works only if snippets config
   * was loaded successfully and current user is super admin.
   * Snippet selection is based on snippet weights specified in config. If weight is 0, snippet can't
   * be selected. Snippet with greater weight will be selected more often than the one with smaller
   * weight.
   * Number of times snippet was selected is saved to cookie. So if user reloads the page,
   * historical data will be taken into account when calculating snippet weights
   *
   * @param {function} callback - a function which is called when selected snippet data is ready to use
  ###
  getRandomSnippet: (callback) ->

    return  unless @snippets? and @isEnabled()

    ranges = null
    sum    = 0
    for name, info of @snippets when info.weight > 0
      { weight } = info
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

    snippetName = name for name, range of ranges when range.minValue <= randomValue <= range.maxValue

    @shownSnippets[snippetName] = (@shownSnippets[snippetName] ? 0) + 1
    kookies.set cookieName, JSON.stringify @shownSnippets

    @getSnippet snippetName, callback

  ###*
   * Method selects snippet by name, loads its data from the server if needed and passes snippet data to callback
   * Building snippet data depends on snippet type
   *
   * @param {string} name - name of snippet
   * @param {function} callback - a function which is called when snippet data is ready to use
  ###
  getSnippet: (name, callback) ->

    return  unless @snippets?[name]

    { type, file } = @snippets[name]

    url     = @buildUrl "snippets/#{name}/#{file ? ''}"
    snippet = { name, type, url }

    switch type
      when MarketingSnippetType.html
        callback snippet
      when MarketingSnippetType.markdown
        $.ajax {
          url
          success : (content) ->
            snippet.content = content
            callback snippet
          error   : ->
            kd.warn "MarketingController: Couldn\'t load snippet #{name}"
        }


  ###*
   * Method loads snippet data and when it's ready emits event to tell that snippet needs to be shown
   *
   * @param {string} name - name of snippet
   * @emits SnippetNeedsToBeShown
  ###
  show: (name) ->

    return kd.log "MarketingController: snippets are not available"  unless @snippets? and @isEnabled()
    return kd.log "MarketingController: couldn't show unknown snippet '#{name}'"  unless @snippets[name]

    @getSnippet name, (snippet) => @emit 'SnippetNeedsToBeShown', snippet


  ###*
   * Method builds url to get any snippet resource by specified path
   *
   * @param {string} path - path to requested resource
  ###
  buildUrl: (path) -> "/-/content-rotator/#{path}"


  ###*
   * Method checks if marketing functionality is available for current user
   *
   * @return {bool}
  ###
  isEnabled: -> checkFlag 'super-admin'