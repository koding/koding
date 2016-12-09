kd = require 'kd'
AceView = require 'ace/aceview'
FSHelper = require 'app/util/fs/fshelper'
FlexSplit = require './flexsplit'


module.exports = class BaseView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'flex-view', options.cssClass
    super options, data

  viewAppended: ->

    wrapper = new kd.View
      cssClass: 'wrapper'

    if title = @getOption 'title'
      wrapper.addSubView new kd.CustomHTMLView
        cssClass : 'title'
        partial  : title

    file = FSHelper.createFileInstance { path: 'localfile:/Untitled.txt' }
    aceView = new AceView { delegate: this }, file

    wrapper.addSubView aceView

    wrapper.addSubView new kd.ButtonView
      cssClass: 'expand'
      callback: => @emit FlexSplit.EVENT_EXPAND

    wrapper.addSubView new kd.ButtonView
      cssClass: 'collapse'
      callback: => @emit FlexSplit.EVENT_COLLAPSE

    @addSubView wrapper

