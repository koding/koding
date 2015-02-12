class ApplicationTabHandleHolder extends KDView

  constructor: (options = {}, data) ->

    options.cssClass        = KD.utils.curry "application-tab-handle-holder", options.cssClass
    options.bind            = "mouseenter mouseleave"
    options.addPlusHandle  ?= yes

    super options, data

    @tabs = new KDCustomHTMLView cssClass: 'kdtabhandle-tabs clearfix'

  viewAppended: ->
    @addSubView @tabs
    @addPlusHandle()  if @getOptions().addPlusHandle

  addPlusHandle: ->
    @plusHandle?.destroy()

    @tabs.addSubView @plusHandle = new KDCustomHTMLView
      cssClass : "kdtabhandle visible-tab-handle plus"
      partial  : "<span class='icon'></span>"
      delegate : this
      click    : => @getDelegate()?.emit "PlusHandleClicked"


  repositionPlusHandle: (handles) ->
    handlesLength = handles.length
    @plusHandle?.$().insertAfter handles[handlesLength - 1].$() if handlesLength

  addHandle: (handle)->
    @tabs.addSubView handle
