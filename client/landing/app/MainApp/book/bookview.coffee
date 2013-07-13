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

    @mainView = @getDelegate()

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
      partial : "Close Tutorial"
      cssClass: "dismiss-button"
      click   : => @emit "OverlayWillBeRemoved"
      tooltip :
        title : "Press: Escape Key"
        gravity:"ne"

    @showMeButton = new KDCustomHTMLView
      tagName   : "a"
      partial   : "Show me how!"
      cssClass  : "cta_button"
      click     : (pubInst, event)=> @showMeButtonClicked()


    @pagerWrapper.addSubView @showMeButton

    @pagerWrapper.addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "Home"
      click     : (pubInst, event)=> @fillPage 0

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

    @once "OverlayAdded", => @$overlay.css zIndex : 999
    @once "OverlayWillBeRemoved", =>
      if @pointer then @destroyPointer()
      @unsetClass "in"
      @utils.wait 1000, =>
        $spanElement = KD.singletons.mainView.sidebar.footerMenu.items[0].$('span')
        $spanElement.addClass('opacity-up')
        @utils.wait 3000, =>
          $spanElement.removeClass('opacity-up')

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
    @fillPage index for index, page of __bookPages when page.routeURL is route

  openFileWithPage:(file)->
    user = KD.nick()
    fileName = "/home/#{user}#{file}"
    KD.getSingleton("appManager").openFile(FSHelper.createFileFromPath(fileName))

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
    if @pointer then @destroyPointer()

    # check if page has tutorial
    if @page.getData().howToSteps.length < 1
      @showMeButton.hide()
    else 
      if @page.getData().menuItem is "Develop" and 
        KD.getSingleton("vmController").defaultVmName is null
          @showMeButton.hide()
      else
        @showMeButton.show()

  showMeButtonClicked:->
    @pointer?.destroy()
    @mainView.addSubView @pointer = new PointerView

    if @page.getData().menuItem
      @navigateCursorToMenuItem(@page.getData().menuItem)
      @setClass 'aside'
    else
      @continueNextMove()

  navigateCursorToMenuItem:(menuItem)->

    @pointer.once 'transitionend', =>
      # open side bar
      @mainView.sidebar.animateLeftNavIn()
      # click menu item
      @selectedMenuItem.$().click()
      @clickAnimation()
      # head to next move
      @utils.wait 600, =>
        @continueNextMove()

    filteredMenu = @mainView.sidebar.nav.items.filter (x) -> x.name is menuItem
    @selectedMenuItem = filteredMenu[0]
    selectedMenuItemOffset = @selectedMenuItem.$().offset()

    @pointer.$().offset selectedMenuItemOffset

  continueNextMove:->
    steps = @page.getData().howToSteps
    {section, parent} = @page.getData()

    if section is 3 and parent is 0
      if steps[0] is 'enterNewStatusUpdate'
        @navigateToStatusUpdateInput()

    if section is 1 and parent is 5
      if steps[0] is 'showFileTreeFolderAndFileMenu'
        @clickFolderOnFileTree('Develop')

    if section is 3 and parent is 5
      if steps[0] is 'showVMMenu'
        @showVMMenu()

    if section is 4 and parent is 5
      if steps[0] is 'openVMTerminal'
        @showVMTerminal()

    if section is 5 and parent is 5
      if steps[0] is 'showRecentFiles'
        @showRecentFilesMenu()

    if section is 6 and parent is 5
      if steps[0] is 'showNewVMMenu'
        @showNewVMMenu()

    if section is 8 and parent is 0
      if steps[0] is 'showConversationsPanel'
        @showConversationsPanel()

    if section is 7 and parent is 5
      if steps[0] is 'changeIndexFile'
        @changeIndexFile()

    if section is 10 and parent is 5
      if steps[0] is 'showAceSettings'
        @showAceSettings()

    if steps.first is 'showAccountPage'
      @destroyPointer()

  navigateToStatusUpdateInput:->
    @pointer.once 'transitionend', =>
      @clickAnimation()
      @utils.wait 1000, =>
        @simulateNewStatusUpdate()


    @utils.wait 500, =>
      smallInput = @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.smallInput.$()
      @pointer.$().offset smallInput.offset()

  simulateNewStatusUpdate:->
    smallInput = @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.smallInput
    largeInput = @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.largeInput
    # focus to dummy input to open large textarea for status update
    smallInput.setFocus()
    # start typing
    textToWrite = 'Hello World!!'
    counter = 0
    repeater = @utils.repeat 121, =>
      largeInput.setValue textToWrite.slice 0, counter++
      if counter is textToWrite.length
        KD.utils.killRepeat repeater
        @pushSubmitButton()

  pushSubmitButton:->
    # catch transition end to finish tutorial
    @pointer.once 'transitionend', =>
      @clickAnimation()
      # wait a little again
      @utils.wait 500, =>
        # trigger push
        @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.submitBtn.$().submit()
        @utils.wait 1000, =>
          @destroyPointer()

    # find offset of submit button
    submitButtonOffset = @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.submitBtn.$().offset()
    # navigate submit button
    @pointer.$().offset submitButtonOffset

  clickFolderOnFileTree:->
    @mainView.sidebar.animateLeftNavOut()
    @pointer.once 'transitionend', =>
      # click animation
      @clickAnimation()
      @utils.wait 1000, =>
        # open fileTree menu
        @defaultVm.$('.chevron').click()
        $('.jcontextmenu').offset(@defaultVm.$('.chevron').offset())
        # destroy pointer
        @destroyPointer()

    user = KD.nick()
    defaultVMName = KD.singletons.vmController.defaultVmName
    userVmName = "[#{defaultVMName}]/home/#{user}"
    @utils.wait 500, =>
      @defaultVm = KD.getSingleton("finderController").treeController.nodes[userVmName]
      @defaultVm.setClass('selected')
      # find file tree's menu position
      vmOffset = @defaultVm.$(".chevron").offset()
      # move cursor to file tree menu
      @pointer.$().offset vmOffset

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
        @destroyPointer()

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
        @destroyPointer()

    @setClass 'moveUp'
    @mainView.once 'transitionend', =>
      # find VM's menu position on footer
      @utils.wait 200, =>
        vmMenuOffset = @mainView.sidebar.resourcesController.itemsOrdered[0].buttonTerm.$().offset()
        # move cursor to VM's menu position
        @pointer.$().offset vmMenuOffset

  showRecentFilesMenu:->
    @pointer.once 'transitionend', =>
      @utils.wait 500, =>
        @destroyPointer()

    # find recent files menu
    element = @mainView.mainTabView.activePane.mainView.$('.start-tab-recent-container')
    offsetTo = element.offset()
    offsetTo.top-=30
    # show recent files menu
    @setClass 'moveUp'
    # move cursor
    @utils.wait 1000, =>
      @pointer.$().offset offsetTo

  showNewVMMenu:->
    @pointer.once 'transitionend', =>
      # click animation
      @clickAnimation()
      # click menu
      @mainView.sidebar.createNewVMButton.$().click()
      @utils.wait 500, =>
        @destroyPointer()

    # move book to up to make button visible
    if not @hasClass 'moveUp' then @setClass 'moveUp'
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
      KD.getSingleton("chatPanel").showPanel()
      @utils.wait 1000, =>
        @startNewConversation()

    # find conversations panel icon position.
    offsetTo = @mainView.chatHandler.$().offset()
    # move cursor to conv. panel button position.
    @pointer.$().offset offsetTo

  startNewConversation:->
    @pointer.once 'transitionend', =>
      # click animation
      @clickAnimation()
      KD.getSingleton("chatPanel").header.newConversationButton.$().click()
      new KDNotificationView
        title     : " Type your friends name"
        duration  : 3000
      @destroyPointer()

    # find + button on panel
    offsetTo = KD.getSingleton("chatPanel").header.newConversationButton.$().offset()
    # navigate cursor
    @pointer.$().offset offsetTo

  changeIndexFile:->
    @pointer.once 'transitionend', =>
      @clickAnimation()
      @defaultVm.setClass('selected')
      @navigateToFolder()

    user = KD.nick()
    defaultVmName = KD.singletons.vmController.defaultVmName
    userVmName = "[#{defaultVmName}]/home/#{user}"
    @utils.wait 500, =>
      @defaultVm = KD.getSingleton("finderController").treeController.nodes[userVmName]
      # find file tree's menu position
      vmOffset = @defaultVm.$(".icon").offset()
      @mainView.sidebar.animateLeftNavOut()
      # move cursor to file tree menu
      @utils.wait 500, =>
        @pointer.$().offset vmOffset

  navigateToFolder:->
    @pointer.once 'transitionend', =>
      # open Web folder
      user = KD.nick()
      @utils.wait 1200, =>
        @clickAnimation()
        KD.getSingleton("finderController").treeController.expandFolder(@webFolderItem)
        @webFolderItem.setClass 'selected'
        @findAndOpenIndexFile()

    # find user Web folder location
    user = KD.nick()
    defaultVMName = KD.singletons.vmController.defaultVmName
    webFolder = "[#{defaultVMName}]/home/#{user}/Web"    
    @webFolderItem = KD.getSingleton("finderController").treeController.nodes[webFolder]
    offsetTo = @webFolderItem.$().offset()
    # navigate to folder
    @pointer.$().offset offsetTo

  findAndOpenIndexFile:->
    @pointer.once 'transitionend', =>
      # open Ace and highlight 'hello world'
      @utils.wait 2200, =>
        @webFolderItem.unsetClass 'selected'
        @indexFileItem.setClass 'selected'
        @utils.wait 600, =>
          @clickAnimation()
          @openFileWithPage('/Web/index.html')
          @utils.wait 800, =>
            @simulateReplacingText()


    @utils.wait 3000, =>
      # find index.html position
      user = KD.nick()
      defaultVMName = KD.singletons.vmController.defaultVmName
      indexFile = "[#{defaultVMName}]/home/#{user}/Web/index.html"
      @indexFileItem = KD.getSingleton("finderController").treeController.nodes[indexFile]
      # move cursor to index.html position
      offsetTo = @indexFileItem.$().offset()
      @pointer.$().offset offsetTo

  simulateReplacingText:->
    @pointer.once 'transitionend', =>
      # change content
      @clickAnimation()
      new KDNotificationView
        title    : "change 'Hello World!' to 'KODING ROCKS!'"
        duration : 3000
      @utils.wait 4000, =>
        @aceView.ace.editor.replace('<h1>KODING ROCKS!</h1>', {needle:'<h1>Hello World!</h1>'})
        @saveAndOpenPreview()

    # highlight
    user = KD.nick()
    aceViewName = "/home/#{user}/Web/index.html"
    @aceView = KD.getSingleton("appManager").frontApp.mainView.aceViews[aceViewName]
    # find 'Hello World!'
    range = @aceView.ace.editor.find('<h1>')
    # get cursor position to ace
    offsetTo = @pointer.$().offset()
    offsetTo.left += 500
    @pointer.$().offset offsetTo

  saveAndOpenPreview:->
    @pointer.once 'transitionend', =>
      # click animation
      @clickAnimation()
      # open menu
      @mainView.appSettingsMenuButton.$().click()
      # find save menu item position
      @utils.wait 2000, =>
        # save ace view
        @mainView.appSettingsMenuButton.data[0].callback()
        @utils.wait 800, =>
          @openPreview()

    # find right up ace save menu position
    offsetTo = @mainView.appSettingsMenuButton.$().offset()
    @pointer.$().offset offsetTo

  openPreview:->
    new KDNotificationView
      title     : "Let's see what changed!"
      duration  : 3000

    @mainView.appSettingsMenuButton.$().click()
    @utils.wait 2200, =>
      @mainView.appSettingsMenuButton.data[8].callback()
      @destroyPointer()

  showAceSettings:->
    @pointer.once 'transitionend', =>
      # click animation
      @clickAnimation()
      # click ace app
      @mainView.mainTabView.activePane.mainView.appIcons.Ace.$().click()
      @utils.wait 800, =>
        @openAceMenu()
      @setClass 'aside'


    # find ace icon on active pane
    offsetTo = @mainView.mainTabView.activePane.mainView.appIcons.Ace.$().offset()
    # navigate to ace icon
    @pointer.$().offset offsetTo

  openAceMenu:->
    @pointer.once 'transitionend', =>
      @mainView.mainTabView.activePane.subViews[0].$('.editor-advanced-settings-menu').click()

    # find ace settings menu icon
    offsetTo = @mainView.mainTabView.activePane.subViews[0].$('.editor-advanced-settings-menu').eq(1).offset()
    # navigate settings icon
    @pointer.$().offset offsetTo
    @utils.wait 3500, =>
      @unsetClass 'aside'
      @destroyPointer()

  destroyPointer:()=>
    @unsetClass('aside')
    @setKeyView()
    @utils.wait 500, ->
      @pointer.destroy()

  clickAnimation:->
    @pointer.setClass 'clickPulse'
    @utils.wait 1000, =>
      @pointer.unsetClass 'clickPulse'