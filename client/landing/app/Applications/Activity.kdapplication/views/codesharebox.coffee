###

Multi-purpose View for CodeShares/CodeSnips
It will take either a JCodeShare or JCodeSnip data object, normalize it
and display according to the options it got called with.


Data Model for CodeShares

CodeShare
  CodeShareTitle
  CodeShareItems
    CodeShareItem
      CodeShareItemSource : String
        - actual source, e.g "<p>This is text</p>"
      CodeShareItemType
        syntax : String
          - language name, syntax, e.g. "php"
      CodeShareItemOptions
        (additional run infos)
        (additional libraries)
  CodeShareOptions
    - maybe original creator data, licensing, prefered display mode

TODO

  - config views
  - enable locking of single tabs (for something like tutorials)


###



class CodeShareBox extends KDView

  constructor:(options={}, data)->

    # log "Codeshare called on a",data?.bongo_?.constructorName," object:",data

    options = $.extend
      cssClass    : "codeshare-box"
      tooltip     :
        title     : "Code Share"
        offset    : 3
        selector  : "span.type-icon"
    ,options

    super options,data

    # Options Defaults

    options.viewMode      or= "TabView"  # TabView or SplitView (later)
    options.allowEditing  ?= yes         # yes for Create/Edit/Fork
    options.allowClosing  ?= yes
    options.showButtonBar ?= yes
    options.hideTabs      ?= no          # legacy, for single-view codesnips

    # Instance Defaults

    @allowEditing    = options.allowEditing
    @allowClosing    = options.allowClosing
    @hideTabs        = options.hideTabs
    @defaultEncoding = "utf8"

    ###
    ====================================================================
    Sanitizing data (converting legacy items into current data model)
    ====================================================================
    ###

    if data?.bongo_?.constructorName is "JCodeSnip"
      codeShare = @convertFromJCodeSnip data

    if data?.bongo_?.constructorName is "JCodeShare" and data?.attachments?[0]?
      codeShare = @convertFromLegacyCodeShare data

    @setData codeShare

    ###
    ====================================================================
    Adding the respective Views (TabView,SplitView,anything we add)
    ====================================================================
    ###

    if options.viewMode is "TabView" then @createTabView()
    # if options.showButtonBar         then @createButtonBar()

  @convertToCodeShare:(data)->


  createTabView:->

      codeShare = @getData()

      @setClass "codeshare-tabs"

      # The CodeShareTabHandleContainerView is in charge of adding a Plus button
      # and Syntax selection

      @codeShareViewTabHandleView = new CodeShareTabHandleContainerView
        tabClass : CodeShareTabView
        cssClass : "codeshare-tabhandlecontainer kdtabhandlecontainer"
        delegate : @

      @codeShareView = new CodeShareTabView
        cssClass : "codeshare-tabview"
        tabHandleContainer : @codeShareViewTabHandleView
        delegate : @


      # populate view with items from data

      if codeShare.CodeShareItems
        for CodeShareItem,i in codeShare.CodeShareItems
          newPane         = new CodeShareTabPaneView
            name          : CodeShareItem.CodeShareItemType.syntax
            allowEditing  : @allowEditing
            type          : "codeshare"
            tabHandleView : new CodeShareTabHandleView
              syntax : CodeShareItem.CodeShareItemType.syntax
              disabled : not @allowEditing
          , CodeShareItem
          @codeShareView.addPane newPane
          @codeShareView.showPane @codeShareView.panes[0]


      # event handlers for adding new/existing panes to the view

      @on "addCodeSharePane",(addItem="text")=>
        @addCodeSharePane addItem

      @on "addCodeSharePanes",(addItems=["text"])=>

        paneAddedCount = 0
        paneAddCount = addItems.length

        @codeShareView.on "PaneAdded",(pane)=>
          pane.on "codeShare.aceLoaded",=>
            paneAddedCount++
            if paneAddedCount is paneAddCount
              log "resizeTabs()"
              @codeShareView.resizeTabs()

        for addItem in addItems
            @addCodeSharePane addItem


      @on "addCodeSharePaneSet",(setName="")=>
        if setName is "hcj" then @emit "addCodeSharePanes", ["html","css","javascript"]

  addCodeSharePane:(addItem)=>

    # addItem is something like "php" or "html"
    if 'string' is typeof addItem
      newData = {
        CodeShareItemSource   : @prepareDefaultItemSource addItem
        CodeShareItemTitle    : "new Codeshare"
        CodeShareItemOptions  : {}
        CodeShareItemType     : {
          syntax              : addItem or "text"
          encoding            : @defaultEncoding
        }
      }
      newPane         = new CodeShareTabPaneView
        name          : addItem or "text"
        allowEditing  : @allowEditing
        type          : "codeshare"
        tabHandleView : new CodeShareTabHandleView
          syntax      : addItem
      , newData

    # addItem is an actual CodeShareItem
    else if 'object' is typeof addItem
      newData = addItem

      newPane         = new CodeShareTabPaneView
        name          : addItem?.CodeShareItemTitle or "text"
        allowEditing  : @allowEditing
        type          : "codeshare"
        tabHandleView : new CodeShareTabHandleView
          syntax      : addItem?.CodeShareItemType?.syntax or "text"
      , newData

    @codeShareView.addPane newPane

  # createButtonBar:=>
  #   codeShare = @getData()
  #   @codeShareButtonBar = new KDCustomHTMLView
  #     tagName:"div"
  #     cssClass:"codeshare-button-bar"

  #   unless @allowEditing
  #     @codeShareButtonBar.hide()
  #   else
  #     @codeView?.setClass "has-button-bar"
  #     @codeShareView?.setClass "has-button-bar"

  #   @configButton = new KDButtonView
  #     title     : ""
  #     style     : "dark"
  #     icon      : yes
  #     iconOnly  : yes
  #     iconClass : "config"
  #     callback  : =>
  #       log "Button pressed"

  # @codeShareButtonBar.addSubView @configButton

  prepareDefaultItemSource:(addType)->
    if addType is "php"
      'echo "Hello World"'
    else if addType is "html"
      "<body><h1>Hello World</h1></body>"
    else if  addType is "javascript"
      "console.log('Hello World');"
    else
      "Enter your Code here"


  resetTabs:=>
    # log "resetting tabs", @codeShareView.panes
    deleteTab = =>
      if @codeShareView?.panes?.length>0 then setTimeout =>
        pane = @codeShareView?.panes[0]
        # log "remaining", @codeShareView.panes
        setTimeout =>
          # log "removing", pane
          @codeShareView?.removePane pane
          deleteTab()
        , 50
      , 50

    deleteTab()

    # the following 2 approaches result in .panes that log as [view1,view2,undefined]
    # why is that?

    # while @codeShareView?.panes?
    #   pane = @codeShareView.panes[0]
    #   @codeShareView.removePane pane

    # for pane in @codeShareView?.panes
    #   if pane then @codeShareView.removePane pane

  convertFromLegacyCodeShare:(codeshare)->
      # log "Encountered a legacy codeshare while sanitizing data",codeshare

      codeShare = {
        body    : codeshare?.body or ""
        title   : codeshare?.title or "Untitled"
        CodeShareItems   : []
        CodeShareOptions :
          runAs:"iframe"
        replies: codeshare.replies or {}
        repliesCount: codeshare.repliesCount or 0
      }

      for attachment in codeshare.attachments
        newCodeShareItem = {
          CodeShareItemSource : attachment.content or ""
          CodeShareItemTitle  : attachment.title or "Untitled"
          CodeShareItemType   : {
            encoding          : @defaultEncoding
            legacyType        : attachment.type or "typeless"
          }
          CodeShareItemOptions: {}
        }

        # Generate Options that correspond to the syntax choice
        newOptions = {}

        if attachment.syntax? and attachment.syntax is "html"
          newOptions.additionalHTMLClasses          = codeshare.classesHTML or ""
          newOptions.additionalHEADElements         = codeshare.extrasHTML or ""

          newCodeShareItem.CodeShareItemType.syntax = codeshare.modeHTML or "html"

        else if attachment.syntax? and attachment.syntax is "css"
          newOptions.externalCSSFiles               = codeshare.externalCSS or ""
          newOptions.usesPrefixFree                 = codeshare.prefixCSS or no
          newOptions.usesReset                      = codeshare.resetCSS or "none"

          newCodeShareItem.CodeShareItemType.syntax = codeshare.modeCSS or "css"

        else if attachment.syntax? and attachment.syntax is "javascript"
          newOptions.externalJSFiles                = codeshare.externalJS or ""
          newOptions.usesLibraries                  = [codeshare.libsJS] or []
          newOptions.usesModernizr                   = codeshare.modernizeJS or no

          newCodeShareItem.CodeShareItemType.syntax = codeshare.modeJS or "javascript"

        newCodeShareItem.CodeShareItemOptions = newOptions
        codeShare.CodeShareItems.push newCodeShareItem
      # log "Converted a legacy CodeShare into:", codeShare

      return codeShare

  convertFromJCodeSnip:(codesnip)->
      # log "Encountered a codesnip while sanitizing data",codesnip

      codeShare = {
        body    : codesnip?.body or ""
        title   : codesnip?.title or "Untitled"
        CodeShareItems   : []
        CodeShareOptions :
          runAs:"codesnip"
        replies: codesnip.replies or {}
        repliesCount: codesnip.repliesCount or 0
      }

      for attachment in codesnip.attachments
        codeShare.CodeShareItems.push {
          CodeShareItemSource : attachment.content or ""
          CodeShareItemTitle  : attachment.title or "Untitled"
          CodeShareItemType   : {
            encoding : @defaultEncoding
            legacyType: attachment.type or "typeless"
            syntax : attachment.syntax or "text"
          }
          CodeShareItemOptions: {}
        }

      # log "Converted a CodeSnip into:", codeShare

      return codeShare

  convertFromBogusData:(something)->
    bogusData = {
      body : "This is test data"
      title: "Test Title"
      CodeShareItems : [
        {
          CodeShareItemSource : "<p>Testing</p>"
          CodeShareItemTitle : "test"
          CodeShareItemType   : {
            syntax : "html"
            encoding : "utf8"
          }
          CodeShareItemOptions: {
            additionalHTMLClasses : "test"
          }
        }
        {
          CodeShareItemSource : "p {color:blue}"
          CodeShareItemTitle : "test"
          CodeShareItemType   : {
            syntax : "css"
            encoding : "utf8"
          }
          CodeShareItemOptions: {
            usePrefixFree : no
          }
        }
      ]
      CodeShareOptions:
        runAs : "iframe"
    }


  render:->
    super()

  viewAppended:->

    # return if @getData().constructor is bongo.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    if @allowClosing is yes
      @codeShareView.showHandleCloseIcons()
    else
      @codeShareView.hideHandleCloseIcons()

    if @hideTabs
      @codeShareView.hideHandleContainer()
      @codeShareView.setClass "has-no-tabs"
    else
      @codeShareView.showHandleContainer()



    # temp for beta
    # take this bit to comment view
    # if @getData().repliesCount? and @getData().repliesCount > 0
    #   commentController = @commentBox.commentController
    #   commentController.fetchAllComments 0, (err, comments)->
    #     commentController.removeAllItems()
    #     commentController.instantiateListItems comments

  pistachio:->
    """
    {{> @codeShareViewTabHandleView}}
    {{> @codeShareView}}
    """