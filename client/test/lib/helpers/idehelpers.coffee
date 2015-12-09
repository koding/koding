helpers           = require './helpers.js'
panelSelector     = '.pane-wrapper .kdsplitview-panel.panel-1'
tabHandleSelector = "#{panelSelector} .application-tab-handle-holder"

activeEditorSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active'
filesTabSelector    = '.ide-files-tab .file-container'

module.exports =


  openNewFile: (browser) ->

    @closeAllTabs browser

    activeEditorSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active .ace_content'
    plusSelector         = tabHandleSelector + ' .visible-tab-handle.plus'

    browser
      .waitForElementVisible  plusSelector, 20000
      .click                  plusSelector
      .waitForElementVisible  '.kdlistview-contextmenu li.new-file', 20000
      .click                  '.kdlistview-contextmenu li.new-file'
      .waitForElementVisible  activeEditorSelector, 20000 # Assertion


  closeAllTabs: (browser) ->

    browser.pause 5000 # wait for snapshot restore

    handleSelector = panelSelector + ' .kdtabhandle.kddraggable'
    modalSelector  = '.autoremovepane-confirm'


    doClose = ->
      browser
        .moveToElement handleSelector, 5, 5
        .click         handleSelector + ' .close-tab'
        .pause         500 # wait for modal
        .element       'css selector', modalSelector, (result) ->
          if result.status is 0
            browser
              .click   "#{modalSelector} .kdbutton.red"
              .pause   500


    close = ->
      browser.elements 'css selector', handleSelector, (result) ->
        length = result.value.length

        if result.value.length isnt 0 then doClose()
        if length - 1 > 0 then close()


    close()


  openContextMenu: (browser) ->

    fileSelector    = "#{tabHandleSelector} .kdtabhandle.active"
    optionsSelector = "#{fileSelector} span.options"

    browser
      .waitForElementVisible  fileSelector, 20000
      .moveToElement          fileSelector, 60, 17
      .moveToElement          optionsSelector, 8, 8
      .waitForElementVisible  optionsSelector, 20000
      .click                  optionsSelector
      .waitForElementVisible  '.kdlistview-contextmenu', 20000 # Assertion


  createAndSaveNewFile: (browser, user, text) ->

    saveSelector        = '.kdlistview-contextmenu li.save'
    saveAsModalSelector = '.save-as-dialog'
    saveAsInputSelector = "#{saveAsModalSelector} input[type=text]"
    newName             = helpers.getFakeText().split(' ')[0] + '.txt'
    titleSelector       = "div[title='/home/#{user.username}/#{newName}']"

    saveButtonSelector  = "#{saveAsModalSelector} .kddialog-buttons span.button-title"

    @openNewFile(browser)

    if text
      @setTextToEditor browser, text

    @openContextMenu(browser)

    browser
      .waitForElementVisible  saveSelector, 20000
      .click                  saveSelector
      .waitForElementVisible  saveAsModalSelector, 20000
      .waitForElementVisible  saveAsInputSelector, 20000
      .clearValue             saveAsInputSelector
      .setValue               saveAsInputSelector, newName
      .click                  saveButtonSelector
      .waitForElementVisible  "#{tabHandleSelector} #{titleSelector}", 20000 # Assertion
      .waitForElementVisible  filesTabSelector, 20000
      .assert.containsText    filesTabSelector, newName # Assertion

    if text
      browser.assert.containsText panelSelector, text

    return newName


  setTextToEditor: (browser, text) ->

    browser.execute "_kd.singletons.appManager.frontApp.activeTabView.activePane.view.setContent('#{text}')"



  saveFile: (browser) ->

    saveSelector      = '.kdlistview-contextmenu li.save'
    saveIconSelector  = "#{tabHandleSelector} .modified"

    @openContextMenu(browser)

    browser
      .waitForElementVisible    saveSelector, 20000
      .click                    saveSelector
      .waitForElementNotPresent saveIconSelector, 20000 # Assertion


  closeFile: (browser, fileName, user) ->

    closeFileSelector = "#{tabHandleSelector} span.close-tab"

    browser
      .moveToElement             tabHandleSelector, 60, 15
      .waitForElementVisible     closeFileSelector, 20000
      .click                     closeFileSelector
      .waitForElementNotPresent  "#{tabHandleSelector} div[title='/home/#{user.username}/#{fileName}']", 20000 # Assertion


  openAnExistingFile: (browser, user, fileName, text) ->

    fileSelector        = "#{filesTabSelector} span[title='/home/#{user.username}/#{fileName}']"
    fileChevronSelector = "#{fileSelector} + .chevron"

    browser
      .waitForElementVisible  filesTabSelector, 20000
      .pause                  3000
      .waitForElementVisible  fileSelector, 20000
      .moveToElement          fileSelector, 70, 12
      .waitForElementVisible  fileChevronSelector, 20000
      .click                  fileChevronSelector
      .waitForElementVisible  'li.open-file', 20000
      .click                  'li.open-file'
      .waitForElementVisible  "#{tabHandleSelector} div[title='/home/#{user.username}/#{fileName}']", 20000 # Assertion
      .assert.containsText    activeEditorSelector, text # Assertion


  openFileFromWebFolder: (browser, user, fileName, fileContent) ->

    fileName    or= 'index.html'
    fileContent or= 'Hello World from HTML by Koding'
    fileSelector  = "span[title='/home/#{user.username}/Web/#{fileName}']"
    fileNameSlug  = fileName.replace '.', ''
    tabSelector   = ".kdtabpaneview.#{fileNameSlug}.active"

    helpers.openFolderContextMenu browser, user, 'Web'

    browser
      .waitForElementVisible   'li.expand', 15000
      .click                   'li.expand'
      .waitForElementVisible   fileSelector, 15000
      .click                   fileSelector
      .click                   fileSelector + ' + .chevron'
      .waitForElementVisible   'li.open-file', 20000
      .click                   'li.open-file'
      .waitForElementVisible   ".pane-wrapper .kdsplitview-panel .#{fileNameSlug}", 20000 # Assertion
      .waitForElementVisible   tabSelector, 20000 # Assertion
      .assert.containsText     tabSelector, fileContent # Assertion


  openFile: (browser, user, fileName) ->

    filePath            = "/home/#{user.username}/Web/#{fileName}"
    fileSelector        = "span[title='#{filePath}']"
    chevronSelector     = "#{fileSelector} + span.chevron"
    contextMenuSelector = '.kdlistview-contextmenu'
    openFileSelector    = "#{contextMenuSelector} li.open-file"
    fileTabSelector     = "div[title='#{filePath}']"

    browser
      .waitForElementVisible  fileSelector, 20000
      .moveToElement          fileSelector, 120, 12
      .waitForElementVisible  chevronSelector, 20000
      .click                  chevronSelector
      .waitForElementVisible  contextMenuSelector, 20000
      .click                  openFileSelector
      .waitForElementVisible  fileTabSelector, 20000


  clickItemInMachineHeaderMenu: (browser, selector) ->

    helpers.clickVMHeaderButton(browser)
    browser.click ".context-list-wrapper #{selector}"


  compressFileFolder: (browser, user, type, fileFolderName, compressType) ->

    webPath     = '/home/' + user.username + '/Web'
    name        = fileFolderName

    if type is 'folder'
      webPath   = '/home/' + user.username
      name      = fileFolderName.name

    fileFolderSelector  = "span[title='" + webPath + '/' + name + "']"
    submenuSelector     = "li.as-#{compressType}"
    extension           = '.zip'

    if compressType is 'targz'
      extension = '.tar.gz'

    newFile = "span[title='" + webPath + '/' + name + extension + "']"

    browser
      .waitForElementPresent     fileFolderSelector, 20000
      .click                     fileFolderSelector
      .click                     fileFolderSelector + ' + .chevron'
      .waitForElementVisible     'li.compress', 20000
      .click                     'li.compress'
      .waitForElementVisible     submenuSelector, 20000
      .click                     submenuSelector
      .pause                     2000
      .waitForElementPresent     newFile, 20000 # Assertion

    helpers.deleteFile(browser, fileFolderSelector)
    helpers.deleteFile(browser, newFile)
