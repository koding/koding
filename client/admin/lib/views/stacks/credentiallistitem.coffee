kd    = require 'kd'
JView = require 'app/jview'


module.exports = class CredentialListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential-item clearfix', options.cssClass
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

    @warningView = new kd.CustomHTMLView
      cssClass : 'warning-message hidden'
      partial  : "We couldn't verify these credentials, please check the
                  ones you used or add new credentials to be able to continue
                  to the next step."


  setVerified: (state, reason) ->

    if state
      @warningView.hide()
      @getDelegate().emit 'ItemSelected', @getData()
      return

    @warningView.show()

    console.warn 'Failed to verify:', reason  if reason


  verifyCredential: ->

    {publicKey} = @getData()

    @warningView.hide()

    @getDelegate()
      .verify this
      .timeout 5000
      .then (response) =>
        @setVerified response?[publicKey]

      .catch (err) =>
        @setVerified no, err.message

      .finally @verifyButton.bound 'hideLoader'


  pistachio: ->
    """
    <div class='credential-info clearfix'>
      {div.tag{#(provider)}} {div.title{#(title)}}
    </div>
    <div class='buttons'>
      {{> @showCredentialButton}}{{> @deleteButton}}{{> @verifyButton}}
    </div>
    {{> @warningView}}
    """
