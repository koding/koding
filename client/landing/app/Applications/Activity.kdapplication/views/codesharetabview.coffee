class CodeShareTabView extends KDTabView
  constructor:(options,data)->
    @visibleHandles = []
    @totalSize      = 0
    @paneViewIndex  = {}
    super options,data

  viewAppended:->

    @on "codeShare.openAllFiles",=>
      for pane in @panes
        data=pane.getData()
        fileName      = "localfile:/#{data.CodeShareItemTitle}"
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
    view.emit "codeShare.resizeEditor" for view in views

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

    handleSize = if containerSize < @totalSize
      containerSize / @visibleHandles.length
    else
      if containerSize / @visibleHandles.length > 130
        130
      else
        containerSize / @visibleHandles.length

    for handle in @visibleHandles
      handle.$().css width : handleSize
      subtractor = if handle.$('span').length is 1 then 25 else 25 + (handle.$('span:not(".close-tab")').length * 25)
      handle.$('> b').css width : (handleSize - subtractor)


###
# The syntax selector in the Tab needs an encapsulating class
###
class CodeShareTabHandleView extends KDView
  constructor:(options,data)->

    super options,data
    @syntaxSelect    = new KDSelectBox
        name          : "syntax"
        disabled      : options.disabled or no
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
    @$("*").hover (event)->
      if not $(event.target).is(".kdtabhandle.plus") and not $(event.target).parent().is(".kdtabhandle.plus")
        $(event.target).closest(".kdtabhandle").click()
    , noop

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
