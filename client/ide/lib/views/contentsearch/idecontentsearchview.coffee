kd                          = require 'kd'
KDButtonView                = kd.ButtonView
KDCustomHTMLView            = kd.CustomHTMLView
KDInputView                 = kd.InputView
KDHitEnterInputView         = kd.HitEnterInputView
KDMultipleChoice            = kd.MultipleChoice
JView                       = require 'app/jview'
_                           = require 'lodash'
$                           = require 'jquery'
keycode                     = require 'keycode'
Encoder                     = require 'htmlencode'
editorSettings              = require '../../workspace/panes/settings/editorsettings'
IDEContentSearchResultView  = require './idecontentsearchresultview'
showError                   = require 'app/util/showError'
showNotification            = require 'app/util/showNotification'

module.exports = class IDEContentSearchView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'search-view'

    super options, data

    @rootPath = options.rootPath

    @localStorageController = kd.singletons.localStorageController.storage 'IDEContentSearch'

    @createElements()


  handleKeyDown: (e) ->

    key = keycode e.which or e.keyCode

    return @destroy()  if key is 'esc'

    if e.target is @findInput.getElement()
      if key in [ 'up', 'down' ]
        @showPreviousSearchLocations key


  destroy: ->

    uber = JView::destroy.bind this
    @findInput.setValue    ''
    uber()
    @emit 'KDObjectWillBeDestroyed', this


  showPreviousSearchLocations: (direction) ->

    previousTerms = @localStorageController.getValue 'PreviousSearchTerms'
    currentTerm   = @findInput.getValue()

    return unless previousTerms

    if currentTerm is ''
      if direction is 'up'
        @setSearchText previousTerms.last or ''
    else
      currentIndex = previousTerms.indexOf currentTerm

      if currentIndex is -1 and direction is 'up'
        return @setSearchText previousTerms.last or ''

      if currentIndex is 0 and direction is 'up'
        return

      targetIndex = if direction is 'up' then currentIndex - 1 else currentIndex + 1
      nextTerm    = previousTerms[targetIndex]

      if not nextTerm and direction is 'down'
        return @findInput.setValue ''

      @setSearchText nextTerm


  setSearchText: (text) ->

    @findInput.setValue text

    kd.utils.defer =>
      kd.utils.moveCaretToEnd @findInput.getElement()


  search: ->

    searchText = Encoder.XSSEncode @findInput.getValue()

    return @searchButton.hideLoader()  if searchText is ''

    @searchText     = searchText
    @rootPath       = Encoder.XSSEncode @whereInput.getValue()
    @selections     = @choices.getValue()

    isCaseSensitive = @selections.indexOf('case-sensitive') > -1
    isWholeWord     = @selections.indexOf('whole-word') > -1
    isRegExp        = @selections.indexOf('regex') > -1
    exts            = editorSettings.getAllExts()
    include         = "\\*{#{exts.join ','}}"
    exclureDirs     = Object.keys editorSettings.ignoreDirectories
    exclureDirs     = " --exclude-dir=#{exclureDirs.join ' --exclude-dir='}"
    searchText      = @searchText

    unless isRegExp
      splitText     = searchText.split '\\n'
      splitText     = splitText.map @grepEscapeRegExp
      searchText    = splitText.join '\\n'

    searchText      = searchText.replace (new RegExp "\\\'", 'g'), "'\\''"
    searchText      = searchText.replace /-/g, '\\-'

    flags = [
      '-s'                           # Silent mode
      '-r'                           # Recursively search subdirectories listed.
      '-n'                           # Each output line is preceded by its relative line number in the file
      '-A 3'                         # Print num lines of trailing context after each match.
      '-B 3'                         # Print num lines of trailing context before each match.
      '-i'                           # Match case insensitively
      '-w'                           # Only match whole words
      '--color=never'                # Disable color output to get plain text
      '--binary-files=without-match' # Do not search binary files
    ]

    flags.splice flags.indexOf('-i'), 1  if isCaseSensitive
    flags.splice flags.indexOf('-w'), 1  unless isWholeWord

    command = "grep #{flags.join ' '} #{exclureDirs} --include=#{include} '#{searchText}' \"#{@escapeShell @rootPath}\""

    { machine } = @getData()
    machine.getBaseKite().exec({ command })
      .then  (res) => @formatOutput res.stdout, @bound 'createResultsView'
      .catch (err) =>
        @showWarning 'Something went wrong, please try again.'
        kd.warn err

    terms = @localStorageController.getValue('PreviousSearchTerms') or []

    terms.push searchText
    @localStorageController.setValue 'PreviousSearchTerms', terms


  createElements: ->

    @findInput = new KDHitEnterInputView
      type         : 'text'
      cssClass     : 'search-input-with-icon'
      placeholder  : 'Search in all files...'
      validate     :
        rules      :
          required : yes
      keydown      : _.bind @handleKeyDown, this
      callback     : @bound 'search'

    @whereInput = new KDInputView
      type         : 'text'
      cssClass     : 'search-input'
      placeholder  : @rootPath
      defaultValue : @rootPath
      validate     :
        rules      :
          required : yes
      keydown      : _.bind @handleKeyDown, this

    @searchButton = new KDButtonView
      title        : 'Search'
      cssClass     : 'search-button'
      loader       :
        color      : '#FFFFFF'
      callback     : @bound 'search'

    @closeButton = new KDCustomHTMLView
      tagName      : 'span'
      cssClass     : 'close-icon'
      click        : @bound 'destroy'

    @choices = new KDMultipleChoice
      cssClass     : ''
      labels       : ['case-sensitive', 'whole-word', 'regex']
      multiple     : yes
      defaultValue : 'fakeValueToDeselectFirstOne'


  escapeRegExp: (str) -> str.replace /([.*+?\^${}()|\[\]\/\\])/g, '\\$1'

  escapeShell: (str) -> str.replace /([\\"'`$\s\(\)<>])/g, '\\$1'

  grepEscapeRegExp: (str) -> str.replace /[[\]{}()*+?.,\\^$|#\s"']/g, '\\$&'


  formatOutput: (output, callback = kd.noop) ->

    return @showWarning 'Something went wrong, please try again.', yes  if output.stderr

    # Regexes
    mainLineRegex           = /^:?([\s\S]+):(\d+):([\s\S]*)$/
    contextLineRegex        = /^([\s\S]+)\-(\d+)\-([\s\S]*)$/
    lines                   = output.split '\n'
    formatted               = {}
    stats                   =
      numberOfMatches       : 0
      numberOfSearchedFiles : 0

    formatted = lines
      .map (line) -> # Remove erroneous whitespace
        return line.trimLeft()
      .filter (line) -> # Skip lines that aren't one of these
        return mainLineRegex.test(line) or contextLineRegex.test(line)
      .map (line) ->
        # Get the matches
        return line.match(mainLineRegex) or line.match(contextLineRegex)
      .reduce( (accu, matches) ->
        # Extract matches
        [fileName, lineNumber, line] = [matches[1], parseInt(matches[2], 10), matches[3]]

        # new filename found
        unless accu[fileName]
          accu[fileName] = []

        # Add line to list of lines found for this filename
        accu[fileName].push { lineNumber, line, occurence: mainLineRegex.test(matches[0]) }

        # Increment matches
        stats.numberOfMatches += 1

        return accu
    , {})

    stats.numberOfSearchedFiles = Object.keys(formatted).length

    # No results
    if stats.numberOfMatches is 0
      return @showWarning 'No results found, please refine your search.'

    # Send results
    callback formatted, stats

  createResultsView: (result, stats) ->

    { searchText }  = this
    @selections     = @choices.getValue()

    isCaseSensitive = @selections.indexOf('case-sensitive') > -1
    { machine }     = @getData()
    resultsView     = new IDEContentSearchResultView { result, stats, searchText, isCaseSensitive, machine }

    @emit 'ViewNeedsToBeShown', resultsView
    @destroy()

  showWarning: (text, isError) ->

    if isError
      showError text
    else
      showNotification
        content  : text
        type     : 'update'
        duration : 3000

    @searchButton.hideLoader()

  viewAppended: ->

    super

    @findInput.setFocus()

  pistachio: ->
    return '''
      <div class="search-options-button-group">
        {{> @choices}}
      </div>
      <div class="search-inputs">
        <div class="search-input-wrapper">
          {{> @findInput}}
        </div>
        <div class="search-input-wrapper">
          {{> @whereInput}}
        </div>
        <div class="search-buttons">
          {{> @searchButton}}
        </div>
      </div>
      <div class="search-view-close-wrapper">
        {{> @closeButton}}
      </div>
    '''
