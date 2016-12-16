kd                  = require 'kd'
KDButtonView        = kd.ButtonView
BaseStackEditorView = require './basestackeditorview'
applyMarkdown       = require 'app/util/applyMarkdown'
ContentModal = require 'app/components/contentModal'

module.exports = class MarkdownEditorView extends BaseStackEditorView

  constructor: (options = {}, data) ->

    options.targetContentType ?= 'markdown'

    super options, data
