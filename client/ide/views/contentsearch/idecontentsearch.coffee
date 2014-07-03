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
            # regExpToggle    :
            #   label         : 'Use filename regexp'
            #   itemClass     : KodingSwitch
            #   defaultValue  : no
            #   cssClass      : 'tiny switch'
            #   nextElement   :
            #     regExpValue :
            #       itemClass : KDInputView
            #       type      : 'text'
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
    # isRegExp        = @regExpToggle.getValue()

    query = "ag '#{@searchText}' '#{@rootPath}'"
    flags = [
      '-C 3'       # Print 3 lines before and after matches
      '--ackmate'  # Print results in AckMate-parseable format
      '--stats'    # Print stats (files scanned, time taken, etc.)
      '--silent'   # Suppress all log messages, including errors.
      '-i'         # Match case insensitively
      '-w'         # Only match whole words
    ]

    flags.splice flags.indexOf('-i'), 1  if isCaseSensitive
    flags.splice flags.indexOf('-w'), 1  unless isWholeWord

    query = "#{query} #{flags.join ' '}"

    vmController.run query, (err, res) =>
      return @showWarning 'Something went wrong, please try again.', yes  if err or res.stderr

      @formatOutput res.stdout, @bound 'createResultsView'

  formatOutput: (output, callback = noop) ->
    lines      = output.split '\n'
    formatted  = {}
    stats      = {}

    if lines[0] is '0 matches'
      return @showWarning 'No results found, refine your search.'

    for line in lines
      parts    = line.split ':'
      fileName = parts[1]  if parts[0] is '' and parts[1] and not parts[2] # filename line, like :Web/index.html

      unless formatted[fileName] # new filename found
        formatted[fileName] = [] # create an empty object for filename and continue to loop
        continue

      if parts.first.indexOf(';') > -1 # occurence found at this line
        [lineNumber] = parts[0].split ';'

        parts.splice 0, 1    # remove line information
        line = parts.join '' # join the parts to have actual line again
        formatted[fileName].push { lineNumber, line, occurence: yes }
      else
        if parts[0] is '--' # handle separators
          formatted[fileName].push type: 'separator'

        if (parts[0] is '') and not parts[1] # avoid empty lines
          continue

        if parts[0] and not parts[1] and parts[1] isnt '' # stats line
          if parts[0].indexOf('matches') > -1
            stats.numberOfMatches = parts[0]
          else if parts[0].indexOf('files searched') > -1
            stats.numberOfSearchedFiles = parts[0]
        else
          [lineNumber] = parts
          parts.splice 0, 1 # remove line information
          line = parts.join() # join the parts to have actual line again
          formatted[fileName].push { lineNumber, line }

    callback formatted, stats

  createResultsView: (result, stats) ->
    {searchText}    = this
    isCaseSensitive = @caseToggle.getValue()
    resultsView = new IDE.ContentSearchResultView { result, stats, searchText, isCaseSensitive }
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
