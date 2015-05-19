kd    = require 'kd'
JView = require 'app/jview'


module.exports = class CredentialListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "credential-item clearfix", options.cssClass
    super options, data

    delegate  = @getDelegate()
    { owner, title } = @getData()

    @deleteButton = new kd.ButtonView
      # iconOnly : yes
      cssClass : "delete"
      title    : "delete"
      callback : delegate.lazyBound 'deleteItem', this

    @showCredentialButton = new kd.ButtonView
      # iconOnly : yes
      cssClass : "show"
      title    : "show"
      disabled : !owner
      callback : delegate.lazyBound 'showItemContent', this

    @bootstrapButton = new kd.ButtonView
      # iconOnly : yes
      cssClass : "bootstrap"
      title    : "bootstrap"
      callback : delegate.lazyBound 'bootstrap', this

    @verifyButton = new kd.ButtonView
      # iconOnly : yes
      cssClass : "verify"
      title    : "verify"
      callback : delegate.lazyBound 'verify', this


  pistachio: ->
    """
    <div class='credential-info'>
      {h4{#(title)}} {p{#(provider)}}
    </div>
    <div class='buttons'>
      {{> @showCredentialButton}}{{> @deleteButton}}
      {{> @bootstrapButton}}{{> @verifyButton}}
    </div>
    """
