class FeederSplitView extends ContentPageSplitBelowHeader
  constructor:(options={})->
    options.sizes     = [139, null]
    options.minimums  = [10, null]
    options.resizable = no
    options.bind      = "mouseenter"

    super options
    
    @listenTo
      KDEventTypes    : 'FeedMessageDialogClosed'
      callback        : (pubInst, {data}, event)=>
        @setHeight @getHeight() + data
        @getSingleton("windowController").notifyWindowResizeListeners { type: 'resize' }
        # this works, but there has to be a better way.
        setTimeout =>
          @setHeight @getHeight() + data
        , 250

