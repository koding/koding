kd = require 'kd'
AceView = require 'ace/aceview'
FSHelper = require 'app/util/fs/fshelper'
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

    file = FSHelper.createFileInstance { path: 'localfile:/Untitled.txt' }

    @aceView = new AceView {
      delegate: this
      createBottomBar: no
    }, file

    @aceView.ace.ready =>
      @aceView.ace.editor.renderer.setScrollMargin 0, 15, 0, 0


    @wrapper.addSubView @aceView

    @wrapper.addSubView new kd.ButtonView
      cssClass: 'expand'
      callback: =>
        @wrapper.setCss 'height', '100vh'
        @emit FlexSplit.EVENT_EXPAND

    @wrapper.addSubView new kd.ButtonView
      cssClass: 'collapse'
      callback: =>
        @emit FlexSplit.EVENT_COLLAPSE

    @addSubView @wrapper


  _windowDidResize: ->
    @aceView?._windowDidResize()
    @once 'transitionend', =>
      @wrapper.setCss 'height', '100%'
      @aceView?._windowDidResize()
