kd             = require 'kd'
KDButtonView   = kd.ButtonView
KDListItemView = kd.ListItemView
JView          = require 'app/jview'


module.exports = class AccountCredentialListItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data)->
    options.cssClass = kd.utils.curry "credential-item clearfix", options.cssClass
    super options, data

    delegate  = @getDelegate()
    { owner } = @getData()

    @deleteButton = new KDButtonView
      # iconOnly : yes
      cssClass : "delete"
      title    : "delete"
      callback : delegate.lazyBound 'deleteItem', this

    @shareButton = new KDButtonView
      # iconOnly : yes
      cssClass : "share"
      title    : "share"
      disabled : !owner
      callback : delegate.lazyBound 'shareItem', this

    @showCredentialButton = new KDButtonView
      # iconOnly : yes
      cssClass : "show"
      title    : "show"
      disabled : !owner
      callback : delegate.lazyBound 'showItemContent', this

    @participantsButton = new KDButtonView
      # iconOnly : yes
      cssClass : "participants"
      title    : "participants"
      disabled : !owner
      callback : delegate.lazyBound 'showItemParticipants', this

    @isBootstrappedButton = new KDButtonView
      # iconOnly : yes
      cssClass : "bootstrapped"
      title    : "is Bootstrapped?"
      callback : delegate.lazyBound 'checkIsBootstrapped', this

    @bootstrapButton = new KDButtonView
      # iconOnly : yes
      cssClass : "bootstrap"
      title    : "bootstrap"
      callback : delegate.lazyBound 'bootstrap', this

    @verifyButton = new KDButtonView
      # iconOnly : yes
      cssClass : "verify"
      title    : "verify"
      callback : delegate.lazyBound 'verify', this


  pistachio:->
    """
    <div class='credential-info'>
      {h4{#(title)}} {p{#(provider)}}
    </div>
    <div class='buttons'>
      {{> @showCredentialButton}}{{> @deleteButton}}
      {{> @shareButton}}{{> @participantsButton}}
      {{> @isBootstrappedButton}}{{> @bootstrapButton}}
      {{> @verifyButton}}
    </div>
    """
