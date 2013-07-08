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

    @loadSectionRelatedElements()
    # destroy @pointer
    if @pointer then @pointer.destroy()

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
    return if @page.showHow is no

    @pointer or = new KDCustomHTMLView
      partial : '  '
      cssClass : 'point'

    @pointer.bindTransitionEnd()

    @pagerWrapper.addSubView @pointer
    #!!! we should check here if has tutorial avaible for current topic
    @navigateCursorToMenuItem(@page.data.title)

  navigateCursorToMenuItem:(menuItem)->

    @pointer.once 'transitionend', =>
      # open side bar
      @getDelegate().sidebar.animateLeftNavIn()
      # click menu item
      @selectedMenuItem[0].$().click()
      @clickAnimation()

     #head to next move
      @continueNextMove()

    @selectedMenuItem = @mainView.sidebar.nav.items.filter (x) -> x.name is menuItem
    selectedMenuItemX = @selectedMenuItem[0].$('.main-nav-icon').eq(0).offset().top
    selectedMenuItemY = @selectedMenuItem[0].$('.main-nav-icon').eq(0).offset().left

    @pointer.$().offset
      top: selectedMenuItemX
      left: selectedMenuItemY


  continueNextMove:->
    steps = @page.data.howToSteps

    if @page.data.section is 1 and @page.data.parent is 0
      if steps[0] is 'enterNewStatusUpdate'
        @navigateToStatusUpdateInput()

    if @page.data.section is 4 and @page.data.parent is 0
      if steps[0] is 'clickAce'
        @clickAceIconInAppWindow()

    if @page.data.section is 1 and @page.data.parent is 4
      if steps[0] fis 'createNewFolder'
        @createNewFolderOnFileTree


  clickAceIconInAppWindow:->
    @mainView = @getDelegate()
    #find aceIconPositon
    @mainView.once 'transitionend',=>
      # just wait a little
      @utils.wait 500, =>
        appIcons  = @mainView.mainTabView.activePane.options.view.appIcons
        aceLeft   = appIcons.Ace.$('.kdloader').eq(0).offset().left
        aceTop    = appIcons.Ace.$('.kdloader').eq(0).offset().top

        #catch callback
        @pointer.once 'transitionend', =>
          # just wait a little
          @utils.wait 300, =>
            #call click animation
            @clickAnimation()
            #open page
            indexFile = '/Web/index.html'
            @openFileWithPage indexFile
            # TODO !!! start typing

        #navigate to aceIcon
        @pointer.$().offset
          top     : aceTop
          left    : aceLeft

  navigateToStatusUpdateInput:->
    @pointer.once 'transitionend', =>
      @utils.wait 2400, =>
        @clickAnimation()
        @simulateNewStatusUpdate()
        #log 'navigateToStatusUpdateInput transend'

    @mainView.once 'transitionend', =>
      @utils.wait 500, =>
        smallInput = @mainView.mainTabView.activePane.mainView.widgetController.updateWidget.smallInput.$()

        #log 'navigateToStatusUpdateInput main transend'
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
      ###waitSec = 300
      for i in [0, textToWrite.length] by 1
        # take a little break on each letter to seem like typing
        log 'letterIndex' , i
        waitSec += (i * 100)
        currentText = textToWrite.slice 0, i
        log 'currentText', currentText
        @utils.wait waitSec, =>
          $('.status-update-input').eq(1).val(currentText)
      ###
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
    # navigate there
    @pointer.$().offset
        top     : submitButtonOffset.top
        left    : submitButtonOffset.left

  createNewFolderOnFileTree:->
    # check if user in develop tab if not navigate
    # if not, open fileTree
    # find default vm position
    # navigate fake cursor
    # simulate right click on fileTree
    # open fileTree menu
    # find create folder menu item
    # navigate fake cursor to create folder item
    # simulate left click
    # simulate folder name typing
    # hit enter
    # destroy the cursor





  clickAnimation:->
    log 'hey! im gonna do some fancy click animation right here!!!!'



















  sayHelloMyFriend:->
    log 'hello my friend'

