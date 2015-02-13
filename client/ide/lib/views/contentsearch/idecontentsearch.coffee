kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDModalViewWithForms = kd.ModalViewWithForms
KDView = kd.View
nick = require 'app/util/nick'
KodingSwitch = require 'app/commonviews/kodingswitch'
IDEContentSearchResultView = require './idecontentsearchresultview'
Encoder = require 'htmlencode'
editorSettings = require '../../workspace/panes/settings/editorsettings'


module.exports = class IDEContentSearch extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.cssClass        = 'content-search-modal'
    options.tabs            =
      forms                 :
        Search              :
          buttons           :
            searchButton    :
              title         : 'Search'
              style         : 'search solid green'
              domId         : 'search-button'
              type          : 'submit'
              loader        :
                color       : '#FFFFFF'
              callback      : @bound 'search'
            cancel          :
              title         : 'Close'
              style         : 'cancel'
              domId         : 'cancel-button'
              callback      : @bound 'destroy'
          fields            :
            findInput       :
              type          : 'text'
              label         : 'Find'
              placeholder   : 'Find'
              keyup         :
                esc         : @bound 'destroy'
            whereInput      :
              type          : 'text'
              label         : 'Where'
              placeholder   : "/home/#{nick()}"
              defaultValue  : "/home/#{nick()}"
              keyup         :
                esc         : @bound 'destroy'
            caseToggle      :
              label         : 'Case Sensitive'
              itemClass     : KodingSwitch
              defaultValue  : yes
              cssClass      : 'tiny switch'
            wholeWordToggle :
              label         : 'Whole Word'
              itemClass     : KodingSwitch
              defaultValue  : no
              cssClass      : 'tiny switch'
             regExpToggle   :
               label        : 'Use regexp'
               itemClass    : KodingSwitch
               defaultValue : no
               cssClass     : 'tiny switch'
            warningView     :
              itemClass     : KDView
              cssClass      : 'hidden notification'

    super options, data

  search: ->
    @warningView.hide()

    @searchText     = Encoder.XSSEncode @findInput.getValue()
    @rootPath       = Encoder.XSSEncode @whereInput.getValue()
    isCaseSensitive = @caseToggle.getValue()
    isWholeWord     = @wholeWordToggle.getValue()
    isRegExp        = @regExpToggle.getValue()

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

    flags           = [
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

    appManager = kd.getSingleton 'appManager'
    appManager.tell 'IDE', 'getMountedMachine', (err, machine) =>
      machine.getBaseKite().exec({ command })
      .then  (res) => @formatOutput machine, res.stdout, @bound 'createResultsView'
      .catch (err) =>
        @showWarning 'Something went wrong, please try again.'
        kd.warn err

  escapeRegExp: (str) ->
    str.replace /([.*+?\^${}()|\[\]\/\\])/g, '\\$1'

  escapeShell: (str) ->
    str.replace /([\\"'`$\s\(\)<>])/g, '\\$1'

  grepEscapeRegExp: (str) ->
    str.replace /[[\]{}()*+?.,\\^$|#\s"']/g, '\\$&'

  formatOutput: (machine, output, callback = kd.noop) ->
    return @showWarning 'Something went wrong, please try again.', yes  if output.stderr

    @machine = machine

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
      return @showWarning 'No results found, refine your search.'

    # Send results
    callback formatted, stats

  createResultsView: (result, stats) ->
    {searchText}    = this
    isCaseSensitive = @caseToggle.getValue()
    resultsView     = new IDEContentSearchResultView { result, stats, searchText, isCaseSensitive, @machine }

    @emit 'ViewNeedsToBeShown', resultsView
    @destroy()

  showWarning: (text, isError) ->
    view = @warningView

    view.unsetClass 'error'
    view.setClass   'error'  if isError
    view.updatePartial text
    view.show()
    @searchButton.hideLoader()

  viewAppended: ->
    super

    @addSubView new KDCustomHTMLView cssClass: 'icon'

    searchForm      = @modalTabs.forms.Search
    {@warningView}  = searchForm.fields
    {@searchButton} = searchForm.buttons
    {@findInput,  @whereInput} = searchForm.inputs
    {@caseToggle, @regExpToggle, @wholeWordToggle} = searchForm.inputs

    @findInput.setFocus()
