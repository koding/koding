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
    isCaseSensitive = true
    isWholeWord     = true
    # isRegExp        = @regExpToggle.getValue()

    include = "\\*{#{SEARCH.PATTERN_EXT}}";

    @searchText = @searchText.replace new RegExp "\\\'", "g", "'\\''"
    @searchText = @searchText.replace /-/g, "\\-"

    flags = [
      '-s'
      '-r'
      '--color=never'
      '--binary-files=without-match'
      '-n'
      '-i'         # Match case insensitively
      '-w'         # Only match whole words
    ]

    flags.splice flags.indexOf('-i'), 1  if isCaseSensitive
    flags.splice flags.indexOf('-w'), 1  unless isWholeWord

    cmd = "grep #{flags.join ' '} #{SEARCH.PATTERN_EDIR} --include=#{include} '#{@searchText}' \"#{SEARCH.escapeShell @rootPath}\""

    vmController.run query, (err, res) =>
      if (err or res.stderr) and not res.stdout
        return @showWarning 'Something went wrong, please try again.', yes

      @formatOutput res.stdout, @bound 'createResultsView'

  formatOutput: (output, callback = noop) ->
    lines      = output.split '\n'
    formatted  = {}
    stats      = {
      numberOfMatches: 0,
      numberOfSearchedFiles: 0
    }

    for line in lines
      parts = line.split ":"
      if parts.length < 3
       continue

      # Parse path
      fileName = parts.shift()
      fileName = fileName.trim()

      # Parse line number
      lineNumber = parseInt parts.shift()

      # Parse line
      line = parts.join ''

      unless formatted[fileName] # new filename found
        formatted[fileName] = [] # create an empty object for filename and continue to loop

      formatted[fileName].push { lineNumber, line, occurence: yes}
      stats.numberOfMatches += 1

    stats.numberOfSearchedFiles = Object.keys(formatted).length

    # No results
    if stats.numberOfMatches == 0
      return @showWarning 'No results found, refine your search.'

    # Send results
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
