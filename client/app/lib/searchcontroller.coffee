Algolia             = require 'algoliasearch'
Promise             = require 'bluebird'
globals             = require 'globals'
kd                  = require 'kd'
KDNotificationView  = kd.NotificationView
KDObject            = kd.Object
remote              = require('./remote')
backoff             = require 'backoff'
doXhrRequest        = require './util/doXhrRequest'
nick                = require 'app/util/nick'


module.exports = class SearchController extends KDObject


  constructor: (options, data) ->

    super options, data

    @indexes = {}

    @initAlgolia()


  initAlgolia: ->

    { appId } = globals.config.algolia ? {}

    unless appId
      kd.warn 'Algolia search is disabled because of missing configuration'
      return @ready = yes

    @ready = no

    @fetchApiKey (err, apiKey) =>

      return kd.error err  if err

      @fetchGroupId (err, currentGroupId) =>

        return console.error "Could not fetch current group id: #{err}"  if err

        @algolia = new Algolia appId, apiKey
        @algolia.setSecurityTags(createSecurityTag(currentGroupId))
        @ready = yes


  createSecurityTag = (currentGroupId) ->
    userId = globals.userAccount.socialApiId
    return "(#{currentGroupId},account-#{userId})"


  fetchGroupId: (callback) ->

    currentGroupId = globals.currentGroup.socialApiChannelId

    # TODO in case of an error this currentGroup.socialApiChannelId is not set.
    # this is just a workaround, and if possible solve this issue and remove these lines
    return callback null, currentGroupId  if currentGroupId

    remote.api.JGroup.one { slug: globals.currentGroup.slug }, (err, group) ->

      return callback err  if err

      return callback null, group.socialApiChannelId  if group?.socialApiChannelId

      return callback { message: 'socialApiChannelId not found' }


  fetchApiKey: (callback) ->
    bo = backoff.exponential
      initialDelay: 700
      maxDelay    : 15000

    bo.on 'fail', -> callback { message: 'Authentication failed.' }
    bo.failAfter 15

    bo.on 'ready', -> bo.backoff()

    requestFn = ->
      doXhrRequest { endPoint: '/api/social/search-key', type: 'GET' }, (err, res) ->
        if err
          kd.warn "Could not fetch search api key: #{err.message}"
          return

        unless res?.apiKey
          kd.warn 'Empty search api key response'
          return

        bo.reset()

        callback null, res.apiKey

    bo.on 'backoff', requestFn

    bo.backoff()


  search: (indexName, seed, options) ->

    new Promise (resolve, reject) =>

      return reject new Error 'Search not ready yet'  unless @ready
      return reject new Error 'Algolia search is disabled'  unless @algolia
      return reject new Error 'Illegal input'  if seed is ''

      index = @getIndex "#{ indexName }#{ globals.config.algolia.indexSuffix }"
      index.search seed, (success, results) ->

        return reject new Error "Couldn't search algolia"  unless success
        return resolve results.hits ? []

      , options


  searchAccountsMongo: (seed, options = {}) ->

    val       = seed.replace /^@/, ''
    nickname  = nick()

    { showCurrentUser }   = options
    { groupsController }  = kd.singletons

    handleResult = (group, account, nickname, resolve, reject) ->
      # Filter accounts according to the current group.
      # If user which is coming from the result isn't a member of the current group
      # don't show it in auto complete
      group.isMember account, (err, isMember) ->
        return reject err  if err

        if isMember and (showCurrentUser or account.profile.nickname isnt nickname)
          return resolve [account]
        else
          return resolve []

    new Promise (resolve, reject) ->

      unless group = groupsController.getCurrentGroup()
        return reject 'Group is not set'

      query = { 'profile.nickname': val }
      remote.api.JAccount.one(query)
        # first try with full value
        .then (account) ->
          throw new Error 'No account found'  unless account
          return handleResult group, account, nickname, resolve, reject
        # if account was not found try with regexp
        .catch (err) ->
          query = { 'profile.nickname': { $regex: "^#{val}", $options: 'i' } }
          remote.api.JAccount.one(query).then (account) ->
            return handleResult group, account, nickname, resolve, reject


  searchAccounts: (seed, options = {}) ->

    opts  =
      hitsPerPage                  : 10
      showCurrentUser              : no
      restrictSearchableAttributes : [ 'nick' ]

    opts      = kd.utils.extend opts, options
    seed      = seed.replace /[^-\w]/g, ''
    nickname  = nick()

    { showCurrentUser } = opts
    delete opts.showCurrentUser

    if @ready # and not @algolia # FIXME ~ US
      return @searchAccountsMongo seed, { showCurrentUser }

    @search 'accounts', seed, opts
      .then (data) ->
        throw new Error 'No data!' if data.length is 0
        return data
      .filter (account) ->
        return yes  if showCurrentUser
        return account.nick isnt nickname
      .map ({ objectID }) -> remote.cacheableAsync 'JAccount', objectID
      .catch (err) =>
        console.warn 'algolia strategy failed; trying mongo'
        console.warn err

        return @searchAccountsMongo seed, { showCurrentUser }
      .filter Boolean


  searchTopics: (seed) ->

    @search 'topics', seed


  _searchChannel: (seed, channelId, itemResultFunc, options = {}) ->

    options.tagFilters = (options.tagFilters ? []).concat channelId

    @search 'messages', seed, options
      .map ({ objectID: id, _highlightResult: highlightResult }) ->
        new Promise (resolve) ->
          kd.singletons.socialapi.message.byId { id }, (err, message) ->
            if err
              # NOTE: intentionally not rejecting here:
              console.warn 'social api error:', err
            resolve itemResultFunc(message, highlightResult)
      .filter Boolean
      .catch (e) ->
        kd.error "Search error: #{e}"
        return new KDNotificationView
          title: 'Search error!'


  searchChannel: (seed, channelId, options) ->

    itemResultFunc = (message) -> message
    @_searchChannel seed, channelId, itemResultFunc, options


  searchChannelWithHighlighting: (seed, channelId, options = {}) ->

    options.attributesToHighlight or= 'body'
    itemResultFunc = (message, highlightResult) -> { message, highlightResult }
    @_searchChannel seed, channelId, itemResultFunc, options


  getIndex: (indexName) ->

    unless @indexes[indexName]?
      index = @algolia.initIndex indexName
      # this is for clearing the query cache every 10 seconds
      setInterval ->
        index.clearCache()
      , 10000
      # index.setSettings attributesForFaceting: 'channel'
      @indexes[indexName] = index
    @indexes[indexName]
