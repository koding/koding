class IDE.ContentSearchResultView extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = 'content-search-result'

    super options, data

    {result, stats, searchText} = options

    for fileName, lines of result
      @addSubView new KDCustomHTMLView
        partial  : "~/#{fileName}"
        cssClass : 'filename'

      for line in lines
        if line.type is 'separator'
          @addSubView new KDCustomHTMLView
            cssClass : 'separator'
            partial  : '...'
        else
          view = @addSubView new KDCustomHTMLView
            tagName  : 'pre'
            cssClass : 'line'

          if line.occurence
            regExp   = new RegExp searchText, 'g'
            replaced = line.line.replace regExp, """<p class="match" data-file-path="#{fileName}" data-line-number="#{line.lineNumber}">#{Encoder.htmlEncode searchText}</p>"""
            view.updatePartial "<span class='line-number'>#{line.lineNumber}</span>#{replaced}"
          else
            view.updatePartial "<span class='line-number'>#{line.lineNumber}</span><span>#{Encoder.htmlEncode line.line}</span>"

  viewAppended: ->
    super

    $('.match').click ->
      $el        = $ this
      filePath   = $el.data 'file-path'
      lineNumber = $el.data 'line-number'

      file = FSHelper.createFileFromPath filePath
      file.fetchContents (err, contents) ->
        KD.getSingleton('appManager').tell 'IDE', 'openFile', file, contents
