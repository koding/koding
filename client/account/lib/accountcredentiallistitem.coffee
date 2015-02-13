kd = require 'kd'
KDButtonView = kd.ButtonView
KDListItemView = kd.ListItemView
JView = require 'app/jview'


module.exports = class AccountCredentialListItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data)->
    options.cssClass = kd.utils.curry "credential-item clearfix", options.cssClass
    super options, data

    delegate  = @getDelegate()
    { owner } = @getData()

    @deleteButton = new KDButtonView
      iconOnly : yes
      cssClass : "delete"
      callback : => delegate.deleteItem this

    @shareButton = new KDButtonView
      iconOnly : yes
      cssClass : "share"
      disabled : !owner
      callback : => delegate.shareItem this

    @showCredentialButton = new KDButtonView
      iconOnly : yes
      cssClass : "show"
      disabled : !owner
      callback : => delegate.showItemContent this

    @participantsButton = new KDButtonView
      iconOnly : yes
      cssClass : "participants"
      disabled : !owner
      callback : => delegate.showItemParticipants this

  pistachio:->
    """
    <div class='credential-info'>
      {h4{#(title)}} {p{#(provider)}}
    </div>
    <div class='buttons'>
      {{> @showCredentialButton}}{{> @deleteButton}}
      {{> @shareButton}}{{> @participantsButton}}
    </div>
    """

