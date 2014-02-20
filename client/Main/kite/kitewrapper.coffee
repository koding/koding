class KiteWrapper extends KDObject

  constructor: (options = {}, data) ->
    super options, data

    @watchedQueries = {}

    @tree = {}

    @registerWatcher this

  registerWatcher: ->
    path = @getQueryPath()

    node = @tree

    for p in path.slice 0, -1
      node[p] = {}  unless node[p]?

      node = node[p]

      if node.isHandler
        # we have found a broader query.  We can add our listener here; there
        # is no need to add a more specific watcher at this time.
        @watchChanges node
        # in the event that the more general watcher is removed, we'll
        # want to actually add a watcher for this path at that time, so
        # we need to correlate the path to the watcher for now.
        node.correlatePath path

        return this

    node = node[path.last] = new KiteWrapper.StatusHandler {
      path
      query: @getOption 'query'
    }
    node.startWatching()

    @watchChanges node

    return this

  watchChanges: (target) ->
    target.on 'change', @bound 'handleChange'

  ignoreChanges: (target) ->
    target.off 'change', @bound 'handleChange'

  handleChange: ->
    console.log "handle change", arguments

  getQueryKey: ->
    (
      @getQueryKey.reduce (acc, key) ->
        acc.push '/', key
        acc
      , []
    ).join ''

  getQueryPath: (query) ->
    { username: u, environment: e, name: n, \
      version: v, region: r, hostname: h, id: i } = @getOption 'query'

    [u, e, n, v, r, h, i].filter(Boolean).reduce (acc, val) ->
      acc.push val
      acc
    , []

  tell: (method, params, callback) ->
    @kite.tell method, params, callback

  class @StatusHandler extends KDObject

    constructor: (options = {}, data) ->
      super options, data
      @correlatedPaths = []

    startWatching: ->
      kontrol = KD.getSingleton 'kontrol'
      kontrol.watchKites(@getOption 'query')
      .then ({ changes }) =>
        debugger
        changes.on 'deregister', -> debugger

    correlatePath: (path) ->
      @correlatedPaths.push path
