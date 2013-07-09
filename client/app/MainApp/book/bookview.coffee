###
  todo
    - develop fake button items and styling
###

class BookView extends JView

  @lastIndex = 0
  cached = []

  cachePage = (index)->
    return if not __bookPages[index] or cached[index]
    page = new BookPage {}, __bookPages[index]
    KDView.appendToDOMBody page
    __utils.wait ->
      cached[index] = yes
      page.destroy()

  constructor: (options = {},data) ->
    options.domId    = "instruction-book"
    options.cssClass = "book"
    super options, data

    @mainView = @getOptions().delegate

    @currentIndex = 0

    @right = new KDView
      cssClass    : "right-page right-overflow"
      click       : -> @setClass "flipped"

    @left = new KDView
      cssClass    : "left-page fl"

    @pagerWrapper = new KDCustomHTMLView
      cssClass : "controls"

    @pageNav = new KDCustomHTMLView
      cssClass : "page-nav"

    @pagerWrapper.addSubView new KDCustomHTMLView
      tagName : "a"
      partial : "X"
      cssClass: "dismiss-button"
      click   : => @emit "OverlayWillBeRemoved"
      tooltip :
        title : "Press: Escape Key"
        gravity:"ne"


    @pagerWrapper.addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "Home"
      click     : (pubInst, event)=> @fillPage 0
      tooltip   :
        title   : "Table of contents"
        gravity : "sw"

    @showMeButton = new KDCustomHTMLView
      tagName   : "a"
      partial   : "Show me how!"
      cssClass  : "cta_button"
      click     : (pubInst, event)=> @showMeButtonClicked()

    @pagerWrapper.addSubView @showMeButton


    @pageNav.addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "◀"
      click     : (pubInst, event)=> @fillPrevPage()
      tooltip   :
        title   : "Press: Left Arrow Key"
        gravity : "sw"

    @pageNav.addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "▶"
      click     : (pubInst, event)=> @fillNextPage()
      tooltip   :
        title   : "Press: Right Arrow Key"
        gravity : "sw"

    @pagerWrapper.addSubView @pageNav

    # @pagerWrapper.addSubView new KDCustomHTMLView
    #   tagName   : "a"
    #   partial   : "Show me how!"
    #   click     : (pubInst, event)=> @showMeButtonClicked()


    #@putOverlay
    #  cssClass    : ""
    #  isRemovable : no
    #  animated    : yes

    @once "OverlayAdded", => @$overlay.css zIndex : 999
    @once "OverlayWillBeRemoved", => @unsetClass "in"
    @once "OverlayRemoved", @destroy.bind @

    @setKeyView()
    cachePage(0)

  pistachio:->

    """
    {{> @pagerWrapper}}
    {{> @left}}
    {{> @right}}
    """

  click:(event)->

    @setKeyView()
    # if event.pageX < 400 then @fillPrevPage() else @fillNextPage()

  keyDown:(event)->

    switch event.which
      when 37 then do @fillPrevPage
      when 39 then do @fillNextPage
      when 27
        @unsetClass "in"
        @utils.wait 600, => @destroy()

  getPage:(index = 0)->

    @currentIndex = index

    page = new BookPage
      delegate : @
    , __bookPages[index]

    return page

  changePageFromRoute:(route)->
    for index, page of __bookPages
      if page.routeURL == route
        @fillPage index

  openFileWithPage:(file)->
    user = KD.whoami().profile
    fileName = "/home/#{user.nickname}#{file}"
    KD.singletons.appManager.openFile(FSHelper.createFileFromPath(fileName))

  fillPrevPage:->
    return if @currentIndex - 1 < 0
    @fillPage @currentIndex - 1

  fillNextPage:->
    return if __bookPages.length is @currentIndex + 1
    @fillPage parseInt(@currentIndex,10) + 1

  fillPage:(index)->
    cachePage index+1
    index ?= BookView.lastIndex
    BookView.lastIndex = index
    @page = @getPage index

    if @$().hasClass "in"
      @right.setClass "out"
      @utils.wait 300, =>
        @right.destroySubViews()
        @right.addSubView @page
        @right.unsetClass "out"
    else
      @right.destroySubViews()
      @right.addSubView @page
      @right.unsetClass "out"
      @utils.wait 400, =>
        @setClass "in"

    # destroy @pointer
    if @pointer then @pointer.destroy()

    # check if page has tutorial
    if @page.data.howToSteps.length < 1
      @showMeButton.hide()
    else
      @showMeButton.show()


  loadSectionRelatedElements:->
    if @page.data.section is 6 and @page.data.parent is 0
      KD.singletons.chatPanel.showPanel()

    if @page.data.section is 8 and @page.data.parent is 4
      @utils.wait 1500, =>
        @setClass "more-terminal"
    else
      @unsetClass "more-terminal"

    if @page.data.section is 1 and @page.data.parent is 4
      @openFileWithPage '/Web/index.html'


  showMeButtonClicked:->

    @pointer or = new KDCustomHTMLView
      partial : ''
      cssClass : 'point'

    @pointer.bindTransitionEnd()

    @pagerWrapper.addSubView @pointer
    #!!! we should check here if has tutorial available for current topic
    if @page.data.menuItem
      @navigateCursorToMenuItem(@page.data.menuItem)
    else
      @continueNextMove()

  navigateCursorToMenuItem:(menuItem)->

    @pointer.once 'transitionend', =>
      # open side bar
      @mainView.sidebar.animateLeftNavIn()
      # click menu item
      @selectedMenuItem[0].$().click()
      @clickAnimation()
      # head to next move
      @utils.wait 600, =>
        @continueNextMove()

    @selectedMenuItem = @mainView.sidebar.nav.items.filter (x) -> x.name is menuItem
    selectedMenuItemOffset = @selectedMenuItem[0].$().offset()

    @pointer.$().offset selectedMenuItemOffset

  continueNextMove:->
    steps = @page.data.howToSteps

    if @page.data.section is 3 and @page.data.parent is 0
      if steps[0] is 'enterNewStatusUpdate'
        @navigateToStatusUpdateInput()

    if @page.data.section is 1 and @page.data.parent is 5
      if steps[0] is 'showFileTreeFolderAndFileMenu'
        @clickFolderOnFileTree('Develop')

    if @page.data.section is 3 and @page.data.parent is 5
      if steps[0] is 'showVMMenu'
        @showVMMenu()

    if @page.data.section is 4 and @page.data.parent is 5
      if steps[0] is 'openVMTerminal'
        @showVMTerminal()

    if @page.data.section is 5 and @page.data.parent is 5
      if steps[0] is 'showRecentFiles'
        @showRecentFilesMenu()

    if @page.data.section is 6 and @page.data.parent is 5
      if steps[0] is 'showNewVMMenu'
        @showNewVMMenu()

    if @page.data.section is 8 and @page.data.parent is 0
      if steps[0] is 'showConversationsPanel'
        @showConversationsPanel()

    if @page.data.section is 7 and @page.data.parent is 5
      if steps[0] is 'changeIndexFile'
        @changeIndexFile()

  navigateToStatusUpdateInput:->
    @pointer.once 'transitionend', =>
      @utils.wait 1000, =>
        @clickAnimation()
        @simulateNewStatusUpdate()

    @mainView.once 'transitionend', =>
      @utils.wait 500, =>

        smallInput = @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.smallInput.$()
        @pointer.$().offset
          top   : smallInput.offset().top
          left  : smallInput.offset().left + (smallInput.width() / 2)

  simulateNewStatusUpdate:->
    smallInput = @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.smallInput.$()
    largeInput = @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.largeInput.$()
    # focus to dummy input to open large textarea for status update
    smallInput.focus()
    # start typing
    @utils.wait 1000, =>
      textToWrite = 'Hello World!!'
      largeInput.val(textToWrite)
      @pushSubmitButton()

  pushSubmitButton:->
    # catch transition end to finish tutorial
    @pointer.once 'transitionend', =>
      # wait a little again
      @utils.wait 500, =>
        @clickAnimation()
        # trigger push
        @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.submitBtn.$().submit()
        @utils.wait 500, =>
          @pointer.destroy()

    # find offset of submit button
    submitButtonOffset = @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.submitBtn.$().offset()
    # navigate submit button
    @pointer.$().offset submitButtonOffset

  clickFolderOnFileTree:->
    @mainView.sidebar.animateLeftNavOut()
    @pointer.once 'transitionend', =>
      @utils.wait 1000, =>
        # click animation
        @clickAnimation()
        # open fileTree menu
        @defaultVm.$('.chevron').click()
        $('.jcontextmenu').offset(@defaultVm.$('.chevron').offset())
        # destroy pointer
        @pointer.destroy()

    user = KD.whoami().profile
    userVmName = "[koding~#{user.nickname}~0]/home/#{user.nickname}"
    @utils.wait 500, =>
      @defaultVm = KD.singletons.finderController.treeController.nodes[userVmName]
      @defaultVm.setClass('selected')
      # find file tree's menu position
      vmOffset = @defaultVm.$(".chevron").offset()
      # move cursor to file tree menu
      @pointer.$().offset
        top     : vmOffset.top
        left    : vmOffset.left

  showVMMenu:->
    @mainView.sidebar.animateLeftNavOut()
    @pointer.once 'transitionend', =>
      # make click action
      @clickAnimation()
      # open VM menu
      @mainView.sidebar.resourcesController.itemsOrdered[0].chevron.$().click()
      # wait 3 sec.
      @utils.wait 2000, =>
        # remove pointer
        #@pointer.destroy()

    # TODO !!! should remove that class on pageNext
    @setClass 'moveUp'
    @mainView.once 'transitionend', =>
      # find VM's menu position on footer
      @utils.wait 1000, =>
        vmMenuOffset = @mainView.sidebar.resourcesController.itemsOrdered[0].chevron.$().offset()
        # move cursor to VM's menu position
        @pointer.$().offset vmMenuOffset

  showVMTerminal:->
    @mainView.sidebar.animateLeftNavOut()
    @pointer.once 'transitionend', =>
      # make click action
      @clickAnimation()
      # open VM menu
      # wait 3 sec.
      @utils.wait 2000, =>
        @mainView.sidebar.resourcesController.itemsOrdered[0].buttonTerm.$().click()
        # remove pointer
        #@pointer.destroy()

    # TODO !!! should remove that class on pageNext
    @setClass 'moveUp'
    @mainView.once 'transitionend', =>
      # find VM's menu position on footer
      @utils.wait 200, =>
        vmMenuOffset = @mainView.sidebar.resourcesController.itemsOrdered[0].buttonTerm.$().offset()
        # move cursor to VM's menu position
        @pointer.$().offset vmMenuOffset

  showRecentFilesMenu:->
    @pointer.once 'transitionend', =>
      @utils.wait 6000, =>
        @unsetClass 'moveUp'

    # show recent files menu
    @setClass 'moveUp'

    # find recent files menu
    offsetTo = @mainView.mainTabView.activePane.mainView.recentFilesWrapper.$().offset()
    log offsetTo
    # move cursor
    @utils.wait 700, =>
      @pointer.$().offset offsetTo

    log offsetTo

  showNewVMMenu:->
    @pointer.once 'transitionend', =>
    # click animation
      @clickAnimation()
    # click menu
      @mainView.sidebar.createNewVMButton.$().click()

    # move book to up to make button visible
    @setClass 'moveUp'
    # if sidebar is closed opens it.
    @mainView.sidebar.animateLeftNavOut()

    @utils.wait 800 , =>
      # find new VM mwnu button
      offsetTo = @mainView.sidebar.createNewVMButton.$().offset()
      # navigate cursor to there
      @pointer.$().offset offsetTo

  showConversationsPanel:->
    @pointer.once 'transitionend', =>
      # click animation
      @clickAnimation()
      # show conv. panel
      KD.singletons.chatPanel.showPanel()
      @utils.wait 1000, =>
        @startNewConversation()

    # find conversations panel icon position.
    offsetTo = @mainView.chatHandler.$().offset()
    # move cursor to conv. panel button position.
    @pointer.$().offset offsetTo

  startNewConversation:->
    # find + button on panel
    offsetTo = KD.singletons.chatPanel.header.newConversationButton.$().offset()
    # navigate cursor
    @pointer.$().offset offsetTo

    @pointer.once 'transitionend', =>
      # click animation
      @clickAnimation()
      KD.singletons.chatPanel.header.newConversationButton.$().click()

  changeIndexFile:->
    # find Web Folder on left
    #KD.singletons.vmController.start()
    #expandNavigationPanel
    # move cursor to Web folder
    # dbl-click animation
    # find index.html file offset
    # move cursor to index.html
    # dbl-click animation
    # find 'Hello World'
    # continue to next step
    # find ace menu
    # move cursor to ace menu
    # find save menu item
    # move cursor to save menu item
    # click animation





  clickAnimation:->
    log 'hey! im gonna do some fancy click animation right here!!!!'
