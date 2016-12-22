kd = require 'kd'
FlexSplit = require './flexsplit'


module.exports = class BaseView extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'flex-view', options.cssClass
    super options, data

    @bindTransitionEnd()


  viewAppended: ->

    @wrapper = new kd.View
      cssClass: 'wrapper'

    if title = @getOption 'title'
      @setClass 'with-title'
      @wrapper.addSubView new kd.CustomHTMLView
        cssClass : 'title'
        partial  : title
        click    : @lazyBound 'emit', 'GotFocus'

    @wrapper.addSubView new kd.ButtonView
      cssClass: 'expand'
      callback: =>
        @wrapper.setClass 'expanding'
        @emit FlexSplit.EVENT_EXPAND
        @once 'transitionend', =>
          @wrapper.unsetClass 'expanding'
          @emit 'GotFocus'

    @wrapper.addSubView new kd.ButtonView
      cssClass: 'collapse'
      callback: =>
        @emit FlexSplit.EVENT_COLLAPSE
        @emit 'GotFocus'

    @addSubView @wrapper

