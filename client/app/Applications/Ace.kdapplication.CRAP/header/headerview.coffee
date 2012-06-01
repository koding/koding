class Editor_HeaderView extends KDView
  constructor:(options = {},data)->
    options.cssClass ?= "editor-header"
    super options,data

    @toleranceTimer

    @listenTo
      KDEventTypes  : 'StartTabSplittedViewEnded'
      callback      : (pubInst, event)->
        @unsetClass 'disabled-subs'

    @listenTo
      KDEventTypes  : 'StartTabSplittedViewStarted'
      callback      : (pubInst, event)->
        @setClass 'disabled-subs'