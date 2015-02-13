kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDScrollView = kd.ScrollView
FSHelper = require 'app/util/fs/fshelper'
Encoder = require 'htmlencode'


module.exports = class IDEContentSearchResultView extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = 'content-search-result'
    options.paneType = 'searchResult'

    super options, data

    {result, stats, searchText, isCaseSensitive, @machine} = options

    for fileName, lines of result
      @addSubView new KDCustomHTMLView
        partial  : "#{fileName}"
        cssClass : 'filename'

      previousLine = null

      for line in lines
        if previousLine and line.lineNumber - previousLine.lineNumber > 1
          @addSubView new KDCustomHTMLView
            cssClass : 'separator'
            partial  : '...'

        view = @addSubView new KDCustomHTMLView
          tagName  : 'pre'
          cssClass : 'line'

        if line.occurence
          flags    = if isCaseSensitive then 'g' else 'gi'
          regExp   = new RegExp searchText, flags
          encoded  = Encoder.htmlEncode line.line
          replaced = encoded.replace regExp, (match) -> """<p class="match" data-file-path="#{fileName}" data-line-number="#{line.lineNumber}">#{match}</p>"""
        else
          replaced = "<span>#{Encoder.htmlEncode line.line}</span>"

        view.updatePartial "<span class='line-number'>#{line.lineNumber}</span>#{replaced}"
        previousLine = line

  click: (event) ->
    {target} = event
    return unless  target.classList.contains 'match'

    path       = target.getAttribute 'data-file-path'
    lineNumber = target.getAttribute 'data-line-number'
    file       = FSHelper.createFileInstance { path, @machine }

    file.fetchContents (err, contents) ->
      kd.getSingleton('appManager').tell 'IDE', 'openFile', file, contents, (editorPane) ->
        editorPane.goToLine lineNumber
