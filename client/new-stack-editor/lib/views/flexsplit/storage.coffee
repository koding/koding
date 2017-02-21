kd = require 'kd'
Flex = require './constants'


module.exports = class FlexSplitStorage extends kd.Object


  constructor: (options = {}, data) ->

    super options, data

    @storage    = {}
    @viewCount  = 0
    @eventCount = 0

    if adapterClass = @getOption 'adapter'
      @adapter = new adapterClass


  addView: (view, identifier, options = {}) ->

    options.restore          ?= yes
    options.keepExpandStatus ?= yes # Experimental

    view.on [ Flex.EVENT_RESIZED, Flex.EVENT_HIDDEN ], (fractions) =>
      @set identifier, fractions
      @store()

    if options.keepExpandStatus
      view.on [
        Flex.EVENT_EXPANDED
        Flex.EVENT_COLLAPSED
      ], (fractions) =>

        @eventCount++
        @set identifier, fractions

        if @eventCount is @viewCount - 1
          @eventCount = 0
          @store()

    @viewCount++

    kd.utils.wait 500, =>

      @get identifier, (fractions) =>

        sizes = view.getOption 'sizes'
        fractions ?= sizes

        if options.restore and fractions
          view.setFractions fractions, { initialFractions: sizes }
          @set identifier, fractions


  get: (identifier, callback) ->
    if @adapter
    then @adapter.get identifier, callback
    else callback @storage[identifier]


  set: (identifier, fractions, callback = kd.noop) ->
    @storage[identifier] = fractions
    callback null, @storage


  store: (callback = kd.noop) ->
    if @adapter?.store?
    then @adapter.store @storage, callback
    else callback null
