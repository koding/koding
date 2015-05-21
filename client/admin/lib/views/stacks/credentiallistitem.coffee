kd    = require 'kd'
JView = require 'app/jview'


module.exports = class CredentialListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "credential-item clearfix", options.cssClass
    super options, data

    delegate  = @getDelegate()
    { owner, title, verified } = @getData()

    @deleteButton = new kd.ButtonView
      cssClass : 'solid compact outline red secondary'
      title    : 'DELETE'
      callback : delegate.lazyBound 'deleteItem', this

    @showCredentialButton = new kd.ButtonView
      cssClass : 'solid compact outline secondary'
      title    : 'SHOW'
      callback : delegate.lazyBound 'showItemContent', this

    @verifyButton = new kd.ButtonView
      cssClass : 'solid compact outline'
      title    : 'USE THIS & CONTINUE'
      loader   :
        color  : '#666'
      callback : @bound 'verifyCredential'



  setVerified: (state, reason) ->

    if state
      @getDelegate().emit 'ItemSelected', @getData()
      return

    @messageView.setClass if state \
      then 'green' else 'red'

    @messageView.unsetTooltip()
    @messageView.setTooltip title: reason  if reason


  verifyCredential: ->

    credential = @getData()

    if credential.verified
      @setVerified yes
      return

    @messageView.unsetClass 'red green'
    @messageView.updatePartial 'Verifying credential...'

    @getDelegate()
      .verify this
      .then (response) =>
        @setVerified response?[credential.publicKey]

      .catch (err) =>
        @setVerified no, err.message

      .finally @verifyButton.bound 'enable'


  pistachio: ->
    """
      {{> @messageView}}
    <div class='credential-info clearfix'>
      {div.provider{#(provider)}} {div.title{#(title)}}
    </div>
    <div class='buttons'>
      {{> @showCredentialButton}}{{> @deleteButton}}{{> @verifyButton}}
    </div>
    """
