class ApplicationTabHandleHolder extends KDView

  constructor: (options = {}, data) ->

    options.cssClass        = KD.utils.curryCssClass "application-tab-handle-holder", options.cssClass
    options.bind            = "mouseenter mouseleave"
    options.addPlusHandle  ?= yes

    super options, data

    if options.addPlusHandle
      @on 'PlusHandleClicked', => @getDelegate().addNewTab()

  viewAppended: ->
    @addPlusHandle()  if @getOptions().addPlusHandle

  addPlusHandle: ->
    @addSubView @plusHandle = new KDCustomHTMLView
      cssClass : "kdtabhandle visible-tab-handle plus"
      partial  : "<span class='icon'></span>"
      delegate : @
      click: =>
        @emit "PlusHandleClicked"

  repositionPlusHandle: (handles) ->
    handlesLength = handles.length
    @plusHandle?.$().insertAfter handles[handlesLength - 1].$() if handlesLength