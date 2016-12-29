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

    @wrapper.addSubView @controls = new kd.CustomHTMLView
      cssClass: 'controls'

    @controls.addSubView new kd.ButtonView
      cssClass: 'expand'
      callback: =>
        @wrapper.setClass 'expanding'
        @emit FlexSplit.EVENT_EXPAND
        @once 'transitionend', =>
          @wrapper.unsetClass 'expanding'
          @emit 'GotFocus'

    @controls.addSubView new kd.ButtonView
      cssClass: 'collapse'
      callback: =>
        @emit FlexSplit.EVENT_COLLAPSE
        @emit 'GotFocus'

    if help = @getOption 'help'

      @controls.addSubView new kd.ButtonView
        cssClass: 'help'
        callback: =>
          @toggleClass 'help-mode'
          @emit 'GotFocus'

      @wrapper.addSubView new kd.View
        cssClass: 'help-content has-markdown'
        partial: help

    @controls.addSubView new kd.LoaderView
      size           : { width: 14 }
      showLoader     : yes
      loaderOptions  :
        color        : '#a4a4a4'

    @addSubView @wrapper
