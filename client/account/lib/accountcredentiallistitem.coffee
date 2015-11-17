kd                        = require 'kd'
KDButtonView              = kd.ButtonView
KDCustomHTMLView          = kd.CustomHTMLView
globals                   = require 'globals'
BaseStackTemplateListItem = require 'app/stacks/basestacktemplatelistitem'


module.exports = class AccountCredentialListItem extends BaseStackTemplateListItem

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "credential-item clearfix", options.cssClass

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

    @addMenuItem 'Show', delegate.lazyBound 'showItemContent', this  if owner

    # Don't show the edit button for aws credentials in list. Gokmen'll on it.
    @addMenuItem 'Edit', delegate.lazyBound 'editItem', this  unless provider is 'aws'

    @addMenuItem 'Delete', delegate.lazyBound 'deleteItem', this

    return @menu


  pistachio: ->
    """
    <div class="credential-info">
      {{> @providerTag}} {div.title{#(title)}}
    </div>
    <div class="buttons">{{> @settings}}</div>
    """
