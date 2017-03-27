kd = require 'kd'
AceView = require 'ace/aceview'
FSHelper = require 'app/util/fs/fshelper'

module.exports = class BuildStackLogsPane extends AceView

  constructor: (options = {}, file) ->

    options.createBottomBar = no
    options.createFindAndReplaceView = no

    super options, file

    @ace.ready => @ace.setReadOnly yes


  appendLogLine: (text) ->

    return  if text is @lastLine

    @ace.ready =>
      @ace.editor.insert "#{if @lastLine then '\n' else ''}#{text}"

    @lastLine = text
