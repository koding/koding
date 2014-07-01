class IDE.ContentSearch extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.cssClass = 'content-search'

    super options, data

    @addSubView @input = input = new KDInputView
      type         : 'text'
      placeholder  : 'Type file name to search'
      keyup        :
        'esc'      : @bound 'destroy'
        'enter'    : @bound 'search'

    @appendToDomBody()
    @input.setFocus()

  search: ->
    vmController = KD.getSingleton 'vmController'
    @searchText  = Encoder.XSSEncode @input.getValue()

    vmController.run "ag '#{@searchText}' -C 3 --ackmate --stats", (err, res) =>
      @formatOutput res.stdout, @bound 'createResultsView'

  formatOutput: (output, callback = noop) ->
    lines      = output.split '\n'
    formatted  = {}
    stats      = {}

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

    callback formatted, stats, @searchText

  createResultsView: (result, stats, searchText) ->
    resultsView = new IDE.ContentSearchResultView { result, stats, searchText }
    @emit 'ViewNeedsToBeShown', resultsView
