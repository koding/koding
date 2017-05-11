kd = require 'kd'
FlexSplit = require './flexsplit'
Events = require '../events'

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
      @wrapper.addSubView @title = new kd.CustomHTMLView
        cssClass : 'title'
        partial  : title
        click    : @lazyBound 'emit', Events.GotFocus

    @wrapper.addSubView @controls = new kd.CustomHTMLView
      cssClass: 'controls'

    if @getOption 'closable'
      @controls.addSubView new kd.ButtonView
        cssClass: 'close'
        callback: =>
          @emit FlexSplit.EVENT_HIDE

    @controls.addSubView new kd.ButtonView
      cssClass: 'expand'
      callback: @bound 'expand'

    @controls.addSubView new kd.ButtonView
      cssClass: 'collapse'
      callback: @bound 'collapse'

    if help = @getOption 'help'

      @controls.addSubView new kd.ButtonView
        cssClass: 'help'
        callback: =>
          @toggleClass 'help-mode'
          @emit Events.GotFocus

      @wrapper.addSubView new kd.View
        cssClass: 'help-content has-markdown'
        partial: help

    if (preview = @getOption 'preview') and @getPreview?

      @wrapper.addSubView contentWrapper = new kd.View
        cssClass: 'preview-content'

      contentWrapper.addSubView previewView = @getPreview()

      @controls.addSubView new kd.ButtonView
        cssClass: 'preview'
        callback: =>
          @toggleClass 'preview-mode'
          @getPreview previewView  if @hasClass 'preview-mode'

          @emit Events.GotFocus

    if @getOption 'pinnable'

      @controls.addSubView new kd.ButtonView
        cssClass: 'pin'
        callback: =>
          @toggleClass 'pinned'
          @emit Events.GotFocus

    @_createLoaderView()

    @addSubView @wrapper


  startLoading: -> @setClass 'loading'


  stopLoading: -> @unsetClass 'loading'


  resize: (percentage) ->
    @emit FlexSplit.EVENT_RESIZE, percentage


  expand: ->
    @wrapper.setClass 'expanding'
    @emit FlexSplit.EVENT_EXPAND
    @once 'transitionend', =>
      @wrapper.unsetClass 'expanding'
      @emit Events.GotFocus


  collapse: ->
    @emit FlexSplit.EVENT_COLLAPSE
    @emit Events.GotFocus


  isClosed: ->
    @getOption('closable') and @getHeight() is 0


  _createLoaderView: ->

    @controls.addSubView @_loaderView = new kd.LoaderView
      size           : { width: 14 }
      showLoader     : yes
      loaderOptions  :
        color        : '#a4a4a4'
