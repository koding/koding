kd                        = require 'kd'
KDCustomHTMLView          = kd.CustomHTMLView
globals                   = require 'globals'
BaseStackTemplateListItem = require 'app/stacks/basestacktemplatelistitem'


module.exports = class AccountCredentialListItem extends BaseStackTemplateListItem

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential-item clearfix', options.cssClass

    super options, data

    delegate            = @getDelegate()
    { providers }       = globals.config
    { owner, provider } = @getData()

    @providerTag = new KDCustomHTMLView
      cssClass : 'tag'
      partial  : provider

    @providerTag.setCss 'background-color', providers[provider].color


  settingsMenu: ->

    { owner, provider } = @getData()
    delegate            = @getDelegate()
    @menu               = {}

    if owner
      @addMenuItem 'Show', => delegate.emit 'ItemAction', { action : 'ShowItem', item : this }

    if not provider is 'aws' or @getData().fields?
      @addMenuItem 'Edit', => delegate.emit 'ItemAction', { action : 'EditItem', item : this }

    @addMenuItem 'Delete', => delegate.emit 'ItemAction', { action : 'RemoveItem', item : this }

    return @menu


  pistachio: ->
    '''
    <div class="credential-info">
      {{> @providerTag}} {div.title{#(title)}}
    </div>
    <div class="buttons">{{> @settings}}</div>
    '''
