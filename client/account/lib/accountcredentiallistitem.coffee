kd             = require 'kd'
KDButtonView   = kd.ButtonView
KDListItemView = kd.ListItemView
JView          = require 'app/jview'


module.exports = class AccountCredentialListItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "credential-item clearfix", options.cssClass

    super options, data

    delegate  = @getDelegate()
    { owner } = @getData()

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


  pistachio:->
    """
    <div class="credential-info">
      {div.tag{#(provider)}} {div.title{#(title)}}
    </div>
    <div class="buttons">
      {{> @showCredentialButton}}{{> @deleteButton}}{{> @editButton}}
    </div>
    """
