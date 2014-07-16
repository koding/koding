class IDE.ContentSearch extends KDModalViewWithForms

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
              callback      : @bound "destroy"
          fields            :
            findInput       :
              type          : 'text'
              label         : 'Find'
              placeholder   : 'Find'
            whereInput      :
              type          : 'text'
              label         : 'Where'
              placeholder   : "/home/#{KD.nick()}" #/Documents"
              defaultValue  : "/home/#{KD.nick()}" #/Documents"
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
             regExpToggle    :
               label         : 'Use regexp'
               itemClass     : KodingSwitch
               defaultValue  : no
               cssClass      : 'tiny switch'
            warningView     :
              itemClass     : KDView
              cssClass      : 'hidden notification'

    super options, data

  search: ->
    @warningView.hide()

    vmController    = KD.getSingleton 'vmController'
    @searchText     = Encoder.XSSEncode @findInput.getValue()
    @rootPath       = Encoder.XSSEncode @whereInput.getValue()
    isCaseSensitive = @caseToggle.getValue()
    isWholeWord     = @wholeWordToggle.getValue()
    isRegExp        = @regExpToggle.getValue()

    exts            = IDE.settings.editor.getAllExts()
    include         = "\\*{#{exts.join ','}}"
    exclureDirs     = Object.keys IDE.settings.editor.ignoreDirectories
    exclureDirs     = " --exclude-dir=#{exclureDirs.join ' --exclude-dir='}"
    searchText      = @searchText

    unless isRegExp
      splitText  = searchText.split "\\n"
      splitText  = splitText.map grepEscapeRegExp
      searchText = splitText.join "\\n"

    searchText   = searchText.replace (new RegExp "\\\'", "g"), "'\\''"
    searchText   = searchText.replace /-/g, "\\-"

    flags        = [
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

    query = "grep #{flags.join ' '} #{exclureDirs} --include=#{include} '#{searchText}' \"#{@escapeShell @rootPath}\""

    vmController.run query, (err, res) =>
      if (err or res.stderr) and not res.stdout
        return @showWarning 'Something went wrong, please try again.', yes

      @formatOutput res.stdout, @bound 'createResultsView'

  escapeRegExp: (str) ->
    str.replace(/([.*+?\^${}()|\[\]\/\\])/g, "\\$1");

  escapeShell: (str) ->
    str.replace /([\\"'`$\s\(\)<>])/g, "\\$1"

  grepEscapeRegExp: (str) ->
    str.replace(/[[\]{}()*+?.,\\^$|#\s"']/g, "\\$&");

  formatOutput: (output, callback = noop) ->
    # Regexes
    mainLineRegex           = /^:?([\s\S]+):(\d+):([\s\S]*)$/
    contextLineRegex        = /^([\s\S]+)\-(\d+)\-([\s\S]*)$/
    lines                   = output.split '\n'
    formatted               = {}
    stats                   =
      numberOfMatches       : 0
      numberOfSearchedFiles : 0

    formatted = lines
    .map (line) ->
      # Remove erronous whitespace
      return line.trimLeft()
    .filter (line) ->
      # Skip lines that aren't one of these
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
    resultsView     = new IDE.ContentSearchResultView { result, stats, searchText, isCaseSensitive }

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
