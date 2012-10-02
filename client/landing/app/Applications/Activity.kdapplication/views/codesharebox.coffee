###

Multi-purpose View for CodeShares/CodeSnips
It will take either a JCodeShare or JCodeSnip data object, normalize it
and display according to the options it got called with.


Data Model for CodeShares

CodeShare
  CodeShareTitle
  CodeShareItems
    CodeShareItem
      CodeShareItemSource
        - actual source, e.g "<p>This is text</p>"
      CodeShareItemType
        - language name, syntax, e.g. "php"
      CodeShareItemOptions
        (additional run infos)
        (additional libraries)
  CodeShareOptions
    ViewType (Tabs, Split)
    EditMode (yes/no)

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
    options.allowEditing  or= yes        # yes for Create/Edit/Fork
    options.allowClosing  or= yes
    options.showButtonBar or= yes

    # Instance Defaults

    @allowEditing    = options.allowEditing
    @allowClosing    = options.allowClosing
    @defaultEncoding = "utf8"

    ###
    ====================================================================
    Sanitizing data (converting legacy items into current data model)
    ====================================================================
    ###

    if data?.bongo_?.constructorName is "JCodeSnip"
      codeShare = @convertFromJCodeSnip data

    if data?.bongo_?.constructorName is "JCodeShare" and data?.attachments?
      codeShare = @convertFromLegacyCodeShare data

    @setData codeShare

    ###
    ====================================================================
    Adding the respective Views (TabView,SplitView,anything we add)
    ====================================================================
    ###

    if options.viewMode is "TabView" then @createTabView()
    if options.showButtonBar         then @createButtonBar()


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


      for CodeShareItem,i in codeShare.CodeShareItems
        newPane         = new CodeShareTabPaneView
          name          : CodeShareItem.CodeShareItemType.syntax # beautify!
          allowEditing  : @allowEditing
          type          : "codeshare"
          tabHandleView : new CodeShareTabHandleView
            syntax : CodeShareItem.CodeShareItemType.syntax
        , CodeShareItem

        @codeShareView.addPane newPane
        @codeShareView.showPane @codeShareView.panes[0]


      @on "addCodeSharePane",(addType)=>

        newData = {
          CodeShareItemSource   : "..."
          CodeShareItemTitle    : "new Codeshare"
          CodeShareItemOptions  : {}
          CodeShareItemType     : {
            syntax              : addType or "text"
            encoding            : @defaultEncoding
          }
        }

        newPane         = new CodeShareTabPaneView
          name          : addType or "text"
          allowEditing  : @allowEditing
          type          : "codeshare"
        , newData

        @codeShareView.addPane newPane

  createButtonBar:->
    codeShare = @getData()
    @codeShareButtonBar = new KDCustomHTMLView
      tagName:"div"
      cssClass:"codeshare-button-bar"

    @configButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "config"
      callback  : =>
        log "Button pressed"

    @codeShareButtonBar.addSubView @configButton





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
    log "We were rendered"

  viewAppended:->

    # return if @getData().constructor is bongo.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    if @allowClosing is yes
      @codeShareView.showHandleCloseIcons()
    else
      @codeShareView.hideHandleCloseIcons()



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
    {{> @codeShareButtonBar}}

    """