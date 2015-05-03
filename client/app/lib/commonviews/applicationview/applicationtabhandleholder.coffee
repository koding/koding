kd = require 'kd'
KDView = kd.View
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class ApplicationTabHandleHolder extends KDView

  constructor: (options = {}, data) ->

    options.cssClass            = kd.utils.curry "application-tab-handle-holder", options.cssClass
    options.bind                = "mouseenter mouseleave"
    options.addPlusHandle      ?= yes
    options.addCloseHandle     ?= yes
    options.addFullscrenHandle ?= yes

    super options, data

    @tabs = new KDCustomHTMLView cssClass: 'kdtabhandle-tabs clearfix'

    @generalHandlesContainer = new KDCustomHTMLView { cssClass: 'general-handles' }

  viewAppended: ->
    @addSubView @tabs
    @addSubView @generalHandlesContainer

    @addPlusHandle()  if @getOptions().addPlusHandle

    @addFullscrenHandle()  if @getOptions().addFullscrenHandle
    @addCloseHandle()  if @getOptions().addCloseHandle


  addPlusHandle: ->
    @plusHandle?.destroy()

    @tabs.addSubView @plusHandle = new KDCustomHTMLView
      cssClass : "kdtabhandle visible-tab-handle plus"
      partial  : "<span class='icon'></span>"
      delegate : this
      click    : => @getDelegate()?.emit "PlusHandleClicked"


  addCloseHandle: ->
    @closeHandle?.destroy()

    @generalHandlesContainer.addSubView @closeHandle = new KDCustomHTMLView
      cssClass : "kdtabhandle visible-tab-handle close-handle"
      partial  : "<span class='icon'></span>"
      delegate : this
      click    : => @getDelegate()?.emit 'CloseHandleClicked'


  addFullscrenHandle: ->
    @fullscreenHandle?.destroy()

    @generalHandlesContainer.addSubView @fullscreenHandle = new KDCustomHTMLView
      cssClass : "kdtabhandle visible-tab-handle fullscreen-handle"
      partial  : "<span class='icon'></span>"
      delegate : this
      click    : => @getDelegate()?.emit 'FullscreenHandleClicked'


  showCloseHandle: -> @closeHandle?.show()


  hideCloseHandle: -> @closeHandle?.hide()


  setFullscreenHandleState: (isFullScreen) ->

    if isFullScreen
    then @fullscreenHandle.setClass 'shrink'
    else @fullscreenHandle.unsetClass 'shrink'


  repositionPlusHandle: (handles) ->
    handlesLength = handles.length
    @plusHandle?.$().insertAfter handles[handlesLength - 1].$() if handlesLength

  addHandle: (handle)->
    @tabs.addSubView handle
