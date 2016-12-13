kd = require 'kd'
FlexSplit = require './index'


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
    options.keepExpandStatus ?= no # Experimental

    view.on FlexSplit.EVENT_RESIZED, (fractions) =>
      @set identifier, fractions
      @store()

    if options.keepExpandStatus
      view.on [
        FlexSplit.EVENT_EXPANDED, FlexSplit.EVENT_COLLAPSED
      ], (fractions) =>

        @eventCount++
        @set identifier, fractions

        if @eventCount is @viewCount - 1
          @eventCount = 0
          @store()

    @viewCount++

    @get identifier, (fractions) =>

      sizes = view.getOption 'sizes'
      fractions ?= sizes

      if options.restore and fractions

        view.setFractions fractions

        if FlexSplit.MAX in fractions
          for i in [0..1] when fractions[i] is FlexSplit.MAX
            view.resizer.views[i].setClass 'expanded'
          view.setFractions sizes, set = no
          @set identifier, sizes
        else
          @set identifier, fractions


  get: (identifier, callback) ->
    if @adapter
    then @adapter.get identifier, callback
    else callback @storage[identifier]


  set: (identifier, fractions, callback = kd.noop) ->
    @storage[identifier] = fractions


  store: (callback = kd.noop) ->
    @adapter?.store @storage, callback
