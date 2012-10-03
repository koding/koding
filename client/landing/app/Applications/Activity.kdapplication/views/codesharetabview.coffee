class CodeShareTabView extends KDTabView
  viewAppended:->

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

    # TODO: find out why some hovers will not register
    @$("*").hover (event)->
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
      partial  : "<span class='icon'></span><b class='hidden'>Click here to start</b>"
      delegate : @
      click    : =>
          contextMenu = new JContextMenu
            event    : event
            delegate : @plusHandle
          ,
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
