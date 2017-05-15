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

DEBOUNCE_WAIT      = 300
HAS_TEXT_CLASSNAME = 'has-text'
KEYDOWN_KEYS       = [ 'enter', 'esc', 'up', 'down' ]

isKeyDownKey = _.memoize (key) -> _.indexOf KEYDOWN_KEYS, key


module.exports =

class IDEFileFinder extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'file-finder'

    super options, data

    @addSubView @input = input = new KDInputView
      type         : 'text'
      placeholder  : 'Type a filename to search…'
      keydown      : @bound 'handleKeyDown'
      keyup        : @bound 'handleKeyUp'

    @addSubView @content = new KDCustomHTMLView
      cssClass     : 'file-finder-content'

    @appendToDomBody()

    kd.getSingleton('windowController').addLayer this
    @on 'ReceivedClickElsewhere', @bound 'destroy'


  search: _.debounce (text) ->

    text = _.trim text

    return @clearSearch()  if text is ''

    appManager      = kd.getSingleton 'appManager'
    rootPath        = "/home/#{nick()}/"
    command         = "find '#{rootPath}' -type f -iname '*#{Encoder.XSSEncode text}*' -not -path '*/.*'"
    @isSearchActive = yes
    @lastTerm       = text

    appManager.tell 'IDE', 'getMountedMachine', (err, machine) =>
      machine.getBaseKite().exec({ command })
      .then  (res) => @parseResponse machine, res
      .catch (err) =>
        @showWarning 'An error occurred, please try again.'
        kd.warn err

  , DEBOUNCE_WAIT


  parseResponse: (machine, res) =>

    return @showWarning 'An error occurred, please try again.' if res.stderr
    return @showWarning 'No files found'  unless res.stdout

    @machine = machine

    @clearSearch()

    files = res.stdout.split '\n'
    items = []

    items.push { path: file }  for file in files when file

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


  handleKeyUp: (e) ->

    code = e.which or e.keyCode
    key  = keycode code
    term = @input.getValue()

    if   term is '' then @input.unsetClass HAS_TEXT_CLASSNAME
    else @input.setClass HAS_TEXT_CLASSNAME

    @search term  if term isnt @lastTerm or not isKeyDownKey key

    return


  handleKeyDown: (e) ->

    code = e.which or e.keyCode
    key  = keycode code

    switch key
      when 'enter' then @handleEnterKey()
      when 'esc'   then @destroy()
      when 'up'
        e.preventDefault()
        @handleNavigation 'up'
      when 'down'
        e.preventDefault()
        @handleNavigation 'down'

    return


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

      kd.getSingleton('appManager').tell 'IDE', 'openFile', { file, contents }


  showWarning: (text) ->

    @content.destroySubViews()
    @content.addSubView new KDCustomHTMLView
      cssClass  : 'warning'
      partial   : text


  viewAppended: ->

    super
    @input.setFocus()
