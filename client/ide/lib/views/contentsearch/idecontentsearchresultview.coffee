kd              = require 'kd'
Encoder         = require 'htmlencode'
FSHelper        = require 'app/util/fs/fshelper'
showError       = require 'app/util/showError'
IDEHelpers      = require '../../idehelpers'


module.exports = class IDEContentSearchResultView extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = 'content-search-result'
    options.paneType = 'searchResult'

    super options, data

    { result, stats, searchText, isCaseSensitive, @machine } = options

    @addSubView @scrollView = new kd.CustomScrollView

    @scrollView.wrapper.addSubView new kd.CustomHTMLView
      partial  : "Showing search results for \"#{searchText}\""
      cssClass : 'results-for'


    for fileName, lines of result
      @scrollView.wrapper.addSubView fileItem = new kd.CustomHTMLView
        partial     : "<span>#{fileName}</span>"
        cssClass    : 'filename'
        dblclick    : ->
          target = @getElement()
          @emit 'OpenFile', target  if target

      fileItem.on 'OpenFile', @bound 'openFile'
      fileItem.setAttribute 'data-file-path', fileName

      previousLine = null

      for line in lines
        if previousLine and line.lineNumber - previousLine.lineNumber > 1
          @scrollView.wrapper.addSubView new kd.CustomHTMLView
            cssClass : 'separator'
            partial  : '...'

        view = fileItem.addSubView new kd.CustomHTMLView
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

    { target } = event

    return  unless target.classList.contains 'match'

    @openFile target


  openFile: (target) ->

    path         = target.getAttribute 'data-file-path'
    file         = FSHelper.createFileInstance { path, @machine }
    lineNumber   = target.getAttribute('data-line-number') or 0
    switchIfOpen = yes

    file.fetchContents (err, contents) =>

      if err
        console.error err
        return IDEHelpers.showPermissionErrorOnOpeningFile(err) or showError err

      fileOptions  = { file, contents, switchIfOpen: yes }

      { appManager } = kd.singletons
      ideApp = appManager.getInstance 'IDE', 'mountedMachineUId', @machine.uid
      ideApp?.openFile fileOptions, (editorPane) ->
        editorPane?.goToLine lineNumber
