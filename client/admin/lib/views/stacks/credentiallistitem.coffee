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
      cssClass : 'solid compact outline red'
      title    : 'DELETE'
      callback : delegate.lazyBound 'deleteItem', this

    @showCredentialButton = new kd.ButtonView
      cssClass : 'solid compact outline'
      title    : 'SHOW'
      callback : delegate.lazyBound 'showItemContent', this

    @useButton = new kd.ButtonView
      cssClass : 'solid compact outline green'
      title    : 'SELECT'
      callback : =>
        delegate.emit 'ItemSelected', @getData()

    @useButton.hide()  unless verified

    @verifyButton = new kd.ButtonView
      cssClass : 'solid compact outline'
      title    : 'VERIFY'
      callback : @bound 'verifyCredential'

    @verifyButton.hide()  if verified

    @messageView = new kd.CustomHTMLView
      cssClass : 'message'

    @setVerified verified


  setVerified: (state, reason) ->

    if state
      @verifyButton.hide()
      @useButton.show()
    else
      @verifyButton.show()
      @useButton.hide()

    @messageView.updatePartial if state \
      then 'Verified Credential'
      else 'Not verified'

    @messageView.setClass if state \
      then 'green' else 'red'

    @messageView.unsetTooltip()
    @messageView.setTooltip title: reason  if reason


  verifyCredential: ->

    credential = @getData()

    if credential.verified
      @setVerified yes
      return

    @verifyButton.disable()
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
    <div class='credential-info'>
      {div.title{#(title)}} {div.provider{#(provider)}}
      {{> @messageView}}
    </div>

    <div class='buttons'>
      {{> @showCredentialButton}}{{> @deleteButton}}
      {{> @useButton}}{{> @verifyButton}}
    </div>
    """
