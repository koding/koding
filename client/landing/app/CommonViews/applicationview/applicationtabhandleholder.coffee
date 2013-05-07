class ApplicationTabHandleHolder extends KDView
  constructor: (options = {}, data) ->

    options.cssClass ?= "application-tab-handle-holder"
    options.bind      = "mouseenter mouseleave"

    super options, data

    @on 'PlusHandleClicked', =>
      @getDelegate().addNewTab()

  viewAppended: ->
    @addPlusHandle()

  addPlusHandle: ->
    @addSubView @plusHandle = new KDCustomHTMLView
      cssClass : "kdtabhandle visible-tab-handle plus"
      partial  : "<span class='icon'></span>"
      delegate : @
      click: =>
        @emit "PlusHandleClicked"

  repositionPlusHandle: (handles) ->
    handlesLength = handles.length
    @plusHandle.$().insertAfter handles[handlesLength - 1].$() if handlesLength