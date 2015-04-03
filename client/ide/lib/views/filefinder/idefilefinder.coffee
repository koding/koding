kd                   = require 'kd'
KDCustomHTMLView     = kd.CustomHTMLView
KDInputView          = kd.InputView
KDListViewController = kd.ListViewController
nick                 = require 'app/util/nick'
FSHelper             = require 'app/util/fs/fshelper'
IDEFileFinderItem    = require './idefilefinderitem'
Encoder              = require 'htmlencode'
keycode              = require 'keycode'
_                    = require 'lodash'


module.exports = class IDEFileFinder extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'file-finder'

    super options, data

    @addSubView @input = input = new KDInputView
      type         : 'text'
      placeholder  : 'Type a file name to search'
      keydown      : _.bind @handleKeyDown, this

    input.on 'keyup', kd.utils.debounce 300, @bound 'handleKeyUp'
    input.on 'keyup', =>
      if   input.getValue() is '' then input.unsetClass 'has-text'
      else input.setClass 'has-text'

    @addSubView new KDCustomHTMLView cssClass: 'icon'
    @addSubView @content = new KDCustomHTMLView

    @appendToDomBody()

    kd.getSingleton('windowController').addLayer this
    @on 'ReceivedClickElsewhere', @bound 'destroy'


  handleKeyDown: (e) ->

    code = e.which or e.keyCode
    key  = keycode code

    switch key
      when 'esc'   then @destroy()
      when 'enter' then @handleEnterKey()
      when 'up'    then @handleNavigation 'up'
      when 'down'  then @handleNavigation 'down'


  search: (text) ->

    return @clearSearch()  if text is ''

    appManager      = kd.getSingleton 'appManager'
    rootPath        = appManager.getFrontApp().workspaceData.rootPath or "/home/#{nick()}/"
    command         = "find '#{rootPath}' -type f -iname '*#{Encoder.XSSEncode text}*' -not -path '*/.*'"
    @isSearchActive = yes
    @lastTerm       = text

    appManager.tell 'IDE', 'getMountedMachine', (err, machine) =>
      machine.getBaseKite().exec({ command })
      .then  (res) => @parseResponse machine, res
      .catch (err) =>
        @showWarning 'An error occurred, please try again.'
        kd.warn err


  parseResponse: (machine, res) =>

    return @showWarning 'An error occurred, please try again.' if res.stderr
    return @showWarning 'No files found'  unless res.stdout

    @machine = machine

    @clearSearch()

    files = res.stdout.split '\n'
    items = []

    items.push path: file  for file in files when file

    listOptions        =
      itemChildClass   : IDEFileFinderItem
      itemChildOptions :
        cssClass       : 'file-item'
      scrollView       : no
      keyNav           : yes
      wrapper          : no

    @listController = new KDListViewController listOptions, { items }
    @listController.getView().on 'ItemWasAdded', (item) =>
      item.once 'viewAppended', =>
        item.child.on 'FileNeedsToBeOpened', @bound 'openFile'

    @content.addSubView @listController.getView()


  handleNavigation: (direction) ->

    lc = @listController
    return  unless lc

    if direction is 'down' then lc.selectNextItem() else lc.selectPrevItem()

    [item] = lc.selectedItems
    item?.getElement().scrollIntoViewIfNeeded()


  handleKeyUp: (event) ->

    listenedKeys  = [13, 27, 38, 40]
    isListenedKey = listenedKeys.indexOf(event.which) > -1
    inputValue    = @input.getValue()
    isSameText    = inputValue is @lastTerm

    return  if isListenedKey or isSameText

    @search inputValue


  handleEnterKey: ->

    value = @input.getValue()

    if not @listController or @lastTerm isnt value
      @search value
    else
      [selected] = @listController.selectedItems
      @openFile selected.getData().path  if selected


  clearSearch: ->

    @content.destroySubViews()
    @listController?.destroy()
    @isSearchActive = no


  openFile: (path) ->

    file = FSHelper.createFileInstance { path, @machine }

    file.fetchContents (err, contents) =>
      return @showWarning 'An error occurred, please try again.'  if err

      @destroy()
      kd.getSingleton('appManager').tell 'IDE', 'openFile', file, contents


  showWarning: (text) ->

    @content.destroySubViews()
    @content.addSubView new KDCustomHTMLView
      cssClass  : 'warning'
      partial   : text


  viewAppended: ->

    super
    @input.setFocus()
