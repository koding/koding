class BookView extends JView

  @lastIndex = 0
  cached = []

  cachePage = (index)->
    return if not __bookPages[index] or cached[index]
    page = new BookPage {}, __bookPages[index]
    page.appendToDomBody()
    utils.wait ->
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
      testPath: "book-close"
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
      click     : (pubInst, event)=>
        BookView.navigateNewPages = no
        @fillPage 0
        @checkBoundaries()

    @pageNav.addSubView @prevButton = new KDCustomHTMLView
      tagName   : "a"
      partial   : "<i class='prev'></i>"
      cssClass  : "disabled"
      click     : (pubInst, event)=> @fillPrevPage()
      tooltip   :
        title   : "Press: Left Arrow Key"
        gravity : "sw"

    @pageNav.addSubView @nextButton = new KDCustomHTMLView
      tagName   : "a"
      partial   : "<i class='next'></i>"
      cssClass  : "disabled"
      click     : (pubInst, event)=> @fillNextPage()
      tooltip   :
        title   : "Press: Right Arrow Key"
        gravity : "sw"

    @pagerWrapper.addSubView @pageNav

    @on "PageFill", =>
      @checkBoundaries()
      if BookView.navigateNewPages
      then @setClass   "new-feature"
      else @unsetClass "new-feature"

    @once "OverlayAdded", => @$overlay.css zIndex : 999

    @once "OverlayWillBeRemoved", =>
      if BookView.navigateNewPages
        BookView.navigateNewPages = no
        BookView.lastIndex = 0

      @getStorage().setValue "lastReadVersion", @getVersion()

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
    KD.mixpanel "Read Book, success"

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
    @fillPage index for own index, page of __bookPages when page.routeURL is route

  openFileWithPage:(file)->
    user = KD.nick()
    fileName = "/home/#{user}#{file}"
    KD.getSingleton("appManager").openFile(FSHelper.createFileInstance path: fileName)

  toggleButton: (button, isDisabled)->
    @["#{button}Button"][if isDisabled then "setClass" else "unsetClass"] "disabled"

  checkBoundaries: (pages=__bookPages)->
    if BookView.navigateNewPages
      @getNewPages (newPages)=>
        @toggleButton "prev", @newPagePointer is 0
        @toggleButton "next", @newPagePointer is newPages.length - 1
    else
      @toggleButton "prev", @currentIndex is 0
      @toggleButton "next", @currentIndex is pages.length - 1

  fillPrevPage:->
    if BookView.navigateNewPages
      @getNewPages =>
        prev = @prevUnreadPage()
        @fillPage prev if prev?
      return

    return if @currentIndex - 1 < 0
    @fillPage @currentIndex - 1

  fillNextPage:->
    if BookView.navigateNewPages
      @getNewPages =>
        next = @nextUnreadPage()
        @fillPage next if next?
      return

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

    @emit "PageFill", index

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
    helloWorldMessages = [
      "I'm really digging this!"
      "This is cool"
      "Yay! I made my first post"
      "Hello, I've just arrived!"
      "Hi all - this looks interesting..."
      "Just got started Koding, I'm excited!"
      "This is pretty nifty."
      "I like it here :)"
      "Looking forward to try Koding"
      "Just joined the Koding community"
      "Checking out Koding."
      "Koding non-stop :)"
      "So, whats up?"
      "Alright. Let's try this"
      "I'm here! What's next? ;)"
      "Really digging Koding :)"
    ]
    textToWrite = helloWorldMessages[(KD.utils.getRandomNumber 15, 0)]
    counter = 0
    repeater = @utils.repeat 121, =>
      largeInput.setValue textToWrite.slice 0, counter++
      if counter is textToWrite.length+1
        KD.utils.killRepeat repeater
        @pushSubmitButton()

  pushSubmitButton:->
    # catch transition end to finish tutorial
    @pointer.once 'transitionend', =>
      @clickAnimation()
      # wait a little again
      @utils.wait 500, =>
        # trigger push
        # @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.submitBtn.$().submit()
        new KDNotificationView
          title     : "Cool, it's ready! You can click submit or cancel."
          duration  : 3000

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
        chevron = @defaultVm.$ '.chevron'
        # open fileTree menu
        chevron.click()
        contextMenu = $ '.jcontextmenu'
        contextMenu.addClass "hidden"

        @utils.wait 500, =>
          contextMenu.offset chevron.offset()
          contextMenu.removeClass "hidden"

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

  showVMMenu: (callback) ->
    startTabView = KD.getSingleton("appManager").get("StartTab").getView()

    presentation = =>
      defaultVMName = KD.getSingleton("vmController").defaultVmName
      {machinesContainer} = startTabView.serverContainer
      for own id, dia of machinesContainer.dias
        if dia.getData().title is defaultVMName
          chevron = dia.$ ".chevron"

          @pointer.once "transitionend", =>
            @clickAnimation()
            chevron.click()

            contextMenu = $ '.jcontextmenu'
            contextMenu.addClass "hidden"

            @utils.wait 500, =>
              contextMenu.offset chevron.offset()
              contextMenu.removeClass "hidden"
              chevron.addClass "hidden"

              if callback then callback()
              else @destroyPointer()

          chevron.removeClass "hidden"
          chevron.show()
          @pointer.$().offset chevron.offset()
          break

    toggle = startTabView.serverContainerToggle

    if toggle.getState().title is "Hide environments"
      presentation()
    else
      @mainView.sidebar.animateLeftNavOut()

      @pointer.once 'transitionend', =>
        if toggle.getState().title is "Show environments"
          @clickAnimation()
          toggle.$().click()
          @utils.wait 2000, =>
            presentation()
        else
          presentation()

      @mainView.once 'transitionend', =>
        @utils.wait 1000, =>
          @pointer.$().offset toggle.$().offset()

  showVMTerminal:->
    @showVMMenu =>
      openTerminal = $($(".jcontextmenu li")[3])

      @pointer.once "transitionend", =>
        @utils.wait 1000, =>
          @clickAnimation()
          @utils.wait 500, =>
            openTerminal.click()
            @destroyPointer()

      @pointer.$().offset openTerminal.offset()

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
    @mainView.sidebar.animateLeftNavOut()

    callback = =>
      button = KD.getSingleton("appManager").get("StartTab").getView().serverContainer.machinesContainer.newItemPlus.$()

      @pointer.once "transitionend", =>
        button.click()
        @clickAnimation()
        @utils.wait 1000, =>
          @destroyPointer()

      @pointer.$().offset button.offset()

    toggle = KD.getSingleton("appManager").get("StartTab").getView().serverContainerToggle
    @pointer.once 'transitionend', =>
      if toggle.getState().title is "Show environments"
        @clickAnimation()
        toggle.$().click()
        @utils.wait 2000, =>
          callback()
      else
        callback()

    @mainView.once 'transitionend', =>
      @utils.wait 200, =>
        @pointer.$().offset toggle.$().offset()

  showConversationsPanel:->
    @pointer.once 'transitionend', =>
      # click animation
      @clickAnimation()
      # show conv. panel
      KD.getSingleton("chatPanel").showPanel()
      @utils.wait 1000, =>
        @startNewConversation()

    # find conversations panel icon position.
    @setClass "moveUp"
    {sidebar} = @mainView
    sidebar.animateLeftNavIn()
    @utils.wait 200, =>
      offsetTo = sidebar.footerMenu.$(".chat").offset()
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
      # check if web folder exists

      nodes = KD.singletons.finderController.treeController.data
      fsFile = nodes.filter (x) -> x.name is "Web"
      if not fsFile then return

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
    button = @mainView.appSettingsMenuButton
    # find right up ace save menu position
    @pointer.$().offset button.$().offset()
    @pointer.once 'transitionend', =>
      # click animation
      @clickAnimation()
      # open menu
      button.$().click()
      # find save menu item position
      @pointer.$().offset $(button.contextMenu.$("li")[0]).offset()
      @utils.wait 2000, =>
        # save ace view
        button.data.items[0].callback()
        @utils.wait 2000, =>
          @openPreview()

  openPreview:->
    new KDNotificationView
      title     : "Let's see what changed!"
      duration  : 3000

    button = @mainView.appSettingsMenuButton
    @pointer.$().offset button.$().offset()
    @utils.wait 2200, =>
      button.$().click()
      @utils.wait 800, =>
        @pointer.$().offset $(button.contextMenu.$("li")[7]).offset()
        @utils.wait 2200, =>
          button.data.items[9].callback()
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
      @clickAnimation()
      @mainView.appSettingsMenuButton.$().click()

      @utils.wait 200, =>
        {advancedSettings} = @mainView.appSettingsMenuButton.contextMenu.treeController.nodes

        offsetTo = advancedSettings?.$().offset()
        # navigate settings icon
        @pointer.once 'transitionend', =>
          @utils.wait 1000, =>
            advancedSettings.setClass "selected"
            advancedSettings.$().click()
            @clickAnimation()
            @utils.wait 1000, =>
              @unsetClass 'aside'
              @destroyPointer()

        @pointer.$().offset offsetTo

    # find ace settings menu icon
    offsetTo = @mainView.appSettingsMenuButton.$().offset()
    # navigate settings icon
    @pointer.$().offset offsetTo

  destroyPointer:()->
    @unsetClass('aside')
    @setKeyView()
    @utils.wait 500, =>
      @pointer.destroy()

  clickAnimation:->
    @pointer.setClass 'clickPulse'
    @utils.wait 1000, =>
      @pointer.unsetClass 'clickPulse'

  indexPages: ->
    for page, index in __bookPages
      page.index = index
      page.version or= 0

  getStorage: ->
    @storage or= new AppStorage "KodingBook", 1.0

  getVersion: ->
    @indexPages()
    Math.max (_.pluck __bookPages, 'version')...

  getNewerPages: (version)->
    __bookPages.filter (page)=>
      # page is unread if page version is bigger than last read one.
      KD.utils.versionCompare page.version, ">", version

  nextUnreadPage: ->
    return if @newPagePointer + 1 is @unreadPages.length
    @newPagePointer++
    @unreadPages[@newPagePointer].index

  prevUnreadPage: ->
    return if @newPagePointer is 0
    --@newPagePointer
    @unreadPages[@newPagePointer].index

  getNewPages: (callback)->
    return callback @unreadPages if @unreadPages

    @getStorage().fetchValue "lastReadVersion", (lastReadVersion=0)=>
      if @getVersion() > lastReadVersion
        unreadPages = @getNewerPages lastReadVersion

        if unreadPages.length is 0
          return callback []

        @newPagePointer ?= 0
        @unreadPages = unreadPages
        callback unreadPages
      else
        callback []
