class CodeShareTabView extends KDTabView
  constructor:(options,data)->
    @visibleHandles = []
    @totalSize      = 0
    @paneViewIndex  = {}
    super options,data

  viewAppended:->

    @on "codeShare.openAllFiles",=>
      for pane,i in @panes
        data=pane.getData()
        fileName      = "localfile:/#{data.CodeShareItemTitle}_#{i}"
        file          = FSHelper.createFileFromPath fileName
        file.contents = Encoder.htmlDecode(data.CodeShareItemSource)
        file.syntax   = data.CodeShareItemType.syntax
        appManager.openFileWithApplication file, 'Ace'

    super

    @resizeTabHandles()

  resizeTabs:=>
    views = @panes

    maxHeight=40
    for view in views
      thisHeight = view.$(".codeshare-code-wrapper").height()
      if thisHeight>maxHeight
        maxHeight = thisHeight
    @$(".codeshare-code-wrapper").css height:maxHeight
    #view.emit "codeShare.resizeEditor" for view in views

  rearrangeVisibleHandlesArray:->
    @visibleHandles = []
    for handle in @handles
      unless handle.getOptions().hidden
        @visibleHandles.push handle

  resizeTabHandles:(event={})->

    return if event.type is "PaneAdded" and event.pane.hiddenHandle
    return if @handlesHidden

    containerSize   = @tabHandleContainer.getWidth()
    {plusHandle}    = @tabHandleContainer

    if event.type in ['PaneAdded','PaneRemoved']
      @totalSize    = 0
      @rearrangeVisibleHandlesArray()
      for handle in @visibleHandles
        @totalSize += handle.$().outerWidth(no)

    if plusHandle?
      plusHandleWidth = plusHandle.$().outerWidth(no)
      containerSize -= plusHandleWidth

    handleCount = @visibleHandles.length

    handleSize = if containerSize < @totalSize
      Math.floor(containerSize / handleCount)
    else
      if containerSize / handleCount > 130
        130
      else
        Math.floor(containerSize / handleCount)

    remainingPixelsShouldBeAdded = containerSize / handleCount < 130
    remainingPixels = containerSize - handleSize * handleCount

    # log "Numbers are ",@totalSize, containerSize, handleCount
    # , handleSize, remainingPixels, remainingPixelsShouldBeAdded

    for handle,i in @visibleHandles
      if i is handleCount-1 and remainingPixelsShouldBeAdded
        handle.$().css width : handleSize + remainingPixels
      else
        handle.$().css width : handleSize

      # handling the tabhandle content dimensions relative to the current
      # css values
      handlePadding = handle.$().css "padding-right"
      handleViewMarginRight = handle.$("div.kdview").css "margin-right"
      handleTitlePaddingLeft = handle.$("span.title").css "padding-left"

      if @getDelegate().options.allowClosing
        subtractor = parseInt(handlePadding, 10) + parseInt(handleViewMarginRight, 10) + 2
        subtractor -= remainingPixels if i is handleCount-1 and remainingPixelsShouldBeAdded
      else
        subtractor = parseInt(handleTitlePaddingLeft, 10)

      handle.$('> div.kdview').css width : (handleSize - subtractor)
      handle.$('> div.kdview span.title').css width : (handleSize - subtractor - 22)
      # handle.$('> div.kdview select').css width : (handleSize - subtractor)


    if remainingPixelsShouldBeAdded and handleCount > 0
      @setClass "has-expanded-tabs"
    else
      @unsetClass "has-expanded-tabs"

###
# The syntax selector in the Tab needs an encapsulating class
###
class CodeShareTabHandleView extends KDView
  constructor:(options,data)->

    super options,data
    @syntaxSelect    = new KDSelectBox
        name          : "syntax"
        cssClass      : "hide-arrows" if options.disabled
        selectOptions : __aceSettings.getSyntaxOptions()
        defaultValue  : options.syntax or "text"
        callback      : (value) =>
          @applyNewSyntax value





  applyNewSyntax:(value)=>
    @parent.emit "codeShare.changeSyntax", value

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

    @parent.setClass "syntax-" + @syntaxSelect.options.defaultValue

    @$(".kdselectbox").attr title:__aceSettings.syntaxAssociations[@syntaxSelect.getValue()][0]

    @$("div").hover (event)->
      if not $(event.target).is(".kdtabhandle.plus") and not $(event.target).parent().is(".kdtabhandle.plus")
        $(event.target).closest(".kdtabhandle:not(.active)").click()
    , noop

    # if disabled, this should intercept the click event. however, overriding
    # the kdview listener is not working

    # @syntaxSelect.listenTo
    #     KDEventTypes        : 'click'
    #     listenedToInstance  : @
    #     callback            : (publishingInstance, event)=>
    #       log "Do something unless this is not an edit tab"

  pistachio:->
    """
    {{> @syntaxSelect}}
    """



class CodeShareTabHandleContainerView extends KDView
  viewAppended:->
    mainView = @getDelegate()

    # Add Plus only when an Editor exists
    if mainView.allowEditing
      @addPlusHandle()
      mainView.codeShareView.on "PaneDidShow", (event)=> @_repositionPlusHandle event
      mainView.codeShareView.on "PaneRemoved", => @_repositionPlusHandle()
      @listenWindowResize()
      @_repositionPlusHandle()

    # TODO: find out why some hovers will not register
    # @$("*").hover (event)->
    #   if not $(event.target).is(".kdtabhandle.plus") and not $(event.target).parent().is(".kdtabhandle.plus")
    #     log $(event.target).parent()
    #     $(event.target).closest(".kdtabhandle").click()
    # , noop

  click:(event)->
    @_plusHandleClicked() if $(event.target).closest('.kdtabhandle').is('.plus')

  _windowDidResize:->
    mainView = @getDelegate()
    @setWidth mainView.codeShareView.getWidth() - 100

  addPlusHandle:()->
    mainView = @getDelegate()

    @addSubView @plusHandle = new KDCustomHTMLView
      cssClass : 'kdtabhandle add-editor-menu visible-tab-handle plus last'
      partial  : "<span class='icon'></span><b class='hidden'>New Code Tab</b>"
      delegate : @
      click    : =>
          contextMenu = new JContextMenu
            event    : event
            delegate : @plusHandle
          ,

            'HTML, CSS and JavaScript'              :
              callback             : (source, event)=>
                mainView.emit "addCodeSharePaneSet", "hcj"
                contextMenu.destroy()
              separator            : yes

            'PHP file'              :
              callback             : (source, event)=>
                mainView.emit "addCodeSharePane", "php"
                contextMenu.destroy()
              separator            : yes

            'Python file'              :
              callback             : (source, event)=>
                mainView.emit "addCodeSharePane", "python"
                contextMenu.destroy()
              separator            : yes

            'Ruby file'              :
              callback             : (source, event)=>
                mainView.emit "addCodeSharePane", "ruby"
                contextMenu.destroy()
              separator            : yes


            'Markup':
              children:
                'HTML':
                  callback             : (source, event)=>
                    mainView.emit "addCodeSharePane", "html"
                    contextMenu.destroy()
                'HAML':
                  callback             : (source, event)=>
                    mainView.emit "addCodeSharePane", "haml"
                    contextMenu.destroy()
                'XML':
                  callback             : (source, event)=>
                    mainView.emit "addCodeSharePane", "xml"
                    contextMenu.destroy()
                'XPATH':
                  callback             : (source, event)=>
                    mainView.emit "addCodeSharePane", "xpath"
                    contextMenu.destroy()

            'Cascading Stylesheets':
              children:
                'CSS':
                  callback             : (source, event)=>
                    mainView.emit "addCodeSharePane", "css"
                    contextMenu.destroy()
                'LESS':
                  callback             : (source, event)=>
                    mainView.emit "addCodeSharePane", "less"
                    contextMenu.destroy()

            'JS-based':
              children:
                'JavaScript':
                  callback             : (source, event)=>
                    mainView.emit "addCodeSharePane", "javascript"
                    contextMenu.destroy()
                'CoffeeScript':
                  callback             : (source, event)=>
                    mainView.emit "addCodeSharePane", "coffee"
                    contextMenu.destroy()
                'IcedCoffee':
                  callback             : (source, event)=>
                    mainView.emit "addCodeSharePane", "icedcoffee"
                    contextMenu.destroy()

            'Contribute A Language' :
              callback             : (source, event)=> appManager.notify()


  removePlusHandle:()->
    @plusHandle.destroy()

  _plusHandleClicked: () ->
    @plusHandle.delegate.emit 'AddEditorClick', @plusHandle

  _repositionPlusHandle:(event)->

    appTabCount = 0
    visibleTabs = []

    for pane in @getDelegate().codeShareView.panes
      if pane.options.type is "codeshare"
        visibleTabs.push pane
        pane.tabHandle.unsetClass "first"
        appTabCount++

    if appTabCount is 0
      @plusHandle.setClass "first last"
      @plusHandle.$('b').removeClass "hidden"

    else
      visibleTabs[0].tabHandle.setClass "first"
      @removePlusHandle()
      @addPlusHandle()
      @plusHandle.unsetClass "first"
      @plusHandle.setClass "last"
