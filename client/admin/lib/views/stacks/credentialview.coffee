kd                      = require 'kd'
JView                   = require 'app/jview'
KDView                  = kd.View
KDCustomHTMLView        = kd.CustomHTMLView
KDButtonView            = kd.ButtonView
CredentialEditorView    = require './editor/credentialeditorview'

curryIn                 = require 'app/util/curryIn'
{yamlToJson}            = require './helpers/yamlutils'
remote                  = require('app/remote').getInstance()
showError               = require 'app/util/showError'


module.exports = class CredentialView extends KDView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'step-define-credential'

    super options, data ? {}

    {crestackTemplate, template} = @getData()

    content = stackTemplate?.template?.content

    @infoText = new KDCustomHTMLView
      cssClass : 'info-message'
      partial  : 'This screen is only allowed for admins.'

    @editorView = new CredentialEditorView { delegate: this, content }

    @saveCredential = new KDButtonView
      title     : 'Save'
      cssClass  : 'solid compact green nav next'
      loader    : yes
      callback  : @bound 'handleSave'


  handleSave: ->

    templateContent = @editorView.getValue()
    convertedDoc    = yamlToJson templateContent

    remote.api.JCredential.create {
      provider      : 'custom'
      title         : ''
      meta          :
        credential  : convertedDoc
    }, (err, credential) =>

      @saveCredential.hideLoader()

      unless showError err
        @emit "CredentialAdded", credential


  pistachio: ->
    """
      {{> @infoText}}
      {{> @editorView}}
      {{> @saveCredential}}
    """