kd                          = require 'kd'
BaseDefineStackEditorView   = require './basedefinestackeditorview'


module.exports = class CredentialEditorView extends BaseDefineStackEditorView


  constructor: (options = {}, data) ->

    options.defaultTemplate ?= require '../defaulttemplates/defaultcredentialtemplate'
    options.fileName        ?= 'credential'

    super options, data

