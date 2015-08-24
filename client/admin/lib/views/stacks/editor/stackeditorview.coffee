kd                          = require 'kd'
BaseDefineStackEditorView   = require './basedefinestackeditorview'


module.exports = class StackEditorView extends BaseDefineStackEditorView


  constructor: (options = {}, data) ->

    options.defaultTemplate ?= require '../defaulttemplates/defaultstacktemplate'
    options.fileName        ?= 'stack'

    super options, data

