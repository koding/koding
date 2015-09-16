kd                = require 'kd'
KDButtonView      = kd.ButtonView
KDListItemView    = kd.ListItemView
KDCustomHTMLView  = kd.CustomHTMLView
JView             = require 'app/jview'
globals           = require 'globals'


module.exports = class AccountCredentialListItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "credential-item clearfix", options.cssClass

    super options, data

    { providers }       = globals.config
    delegate            = @getDelegate()
    { owner, provider } = @getData()

    @deleteButton = new KDButtonView
      cssClass : "solid compact outline red secondary"
      title    : "DELETE"
      callback : delegate.lazyBound 'deleteItem', this

    @showCredentialButton = new KDButtonView
      cssClass : "solid compact outline secondary"
      title    : "SHOW"
      disabled : !owner
      callback : delegate.lazyBound 'showItemContent', this

    @editButton = new KDButtonView
      cssClass : "solid compact outline"
      title    : "EDIT"
      callback : delegate.lazyBound 'editItem', this

    # Don't show the edit button for aws credentials in list. Gokmen'll on it.
    @editButton.hide()  if provider is 'aws'

    @providerTag = new KDCustomHTMLView
      cssClass : 'tag'
      partial  : @getData().provider

    @providerTag.setCss 'background-color', providers[provider].color


  pistachio: ->
    """
    <div class="credential-info">
      {{> @providerTag}} {div.title{#(title)}}
    </div>
    <div class="buttons">
      {{> @showCredentialButton}}{{> @deleteButton}}{{> @editButton}}
    </div>
    """
