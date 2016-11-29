kd                  = require 'kd'
KDButtonView        = kd.ButtonView
BaseStackEditorView = require './basestackeditorview'

module.exports = class MarkdownEditorView extends BaseStackEditorView

  constructor: (options = {}, data) ->

    options.targetContentType ?= 'markdown'

    super options, data
