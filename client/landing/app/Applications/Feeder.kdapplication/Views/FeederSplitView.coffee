class FeederSplitView extends ContentPageSplitBelowHeader
  constructor:(options={})->
    options.sizes     = [139, null]
    options.minimums  = [10, null]
    options.resizable = no
    options.bind      = "mouseenter"

    super options

    # loook what this is, there is some sabotage going on here 6/2012 Sinan

    @listenTo
      KDEventTypes    : 'FeedMessageDialogClosed'
      callback        : (pubInst, {data}, event)=>
        @setHeight @getHeight() + data
        @notifyResizeListeners()
        # this works, but there has to be a better way.
        @utils.wait 250, =>
          @setHeight @getHeight() + data

