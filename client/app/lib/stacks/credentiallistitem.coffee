kd      = require 'kd'
globals = require 'globals'


Tracker = require 'app/util/tracker'
sendDataDogEvent = require 'app/util/sendDataDogEvent'


module.exports = class CredentialListItem extends kd.ListItemView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential-item clearfix', options.cssClass

    super options, data

    delegate = @getDelegate()
    { identifier, owner, title, verified } = credential = @getData()

    @deleteButton = new kd.ButtonView
      cssClass  : 'solid compact outline red secondary delete'
      title     : 'DELETE'
      callback  : =>
        delegate.emit 'ItemAction', { action : 'RemoveItem', item : this }

    @showCredentialButton = new kd.ButtonView
      cssClass  : 'solid compact outline secondary show'
      title     : 'SHOW'
      callback  : =>
        delegate.emit 'ItemAction', { action : 'ShowItem', item : this }

    @verifyButton = new kd.ButtonView
      cssClass : 'solid compact outline verify'
      title    : 'USE THIS & CONTINUE'
      loader   :
        color  : '#666'
        diameter : 16
      callback : @bound 'verifyCredential'

    @inuseView = new kd.CustomHTMLView
      cssClass : 'custom-tag hidden inuse'
      partial  : 'IN USE'
      tooltip  :
        title  : 'This stack template currently using this credential'

    { stackTemplate }       = @getOptions()
    { selectedCredentials } = delegate.getOptions()

    credentials = stackTemplate?.credentials ? {}
    credentials = (credentials[val].first for val of credentials)
    credentials = credentials.concat (selectedCredentials or [])

    if identifier in credentials
      credential.inuse = yes
      @inuseView.show()

    @warningView = new kd.CustomHTMLView
      cssClass : 'warning-message hidden'

    delegate.on 'ResetInuseStates', @inuseView.bound 'hide'


  setVerified: (state, reason) ->

    if state
      @unsetClass 'failed'
      @warningView.hide()
      @getDelegate().emit 'ItemSelected', this
    else
      @setClass 'failed'
      Tracker.track Tracker.STACKS_AWS_KEYS_FAILED
      sendDataDogEvent 'CredentialFailed', { prefix: 'credential-save' }
      @warningView.updatePartial if reason
        "Failed to verify: #{reason}"
      else
        "We couldn't verify this credential, please check the ones you
         used or add a new credential to be able to continue to the
         next step."

      @warningView.show()


  verifyCredential: ->

    { identifier } = @getData()

    @warningView.hide()

    @getDelegate()
      .verify this
      .timeout globals.COMPUTECONTROLLER_TIMEOUT
      .then (response) =>
        if status = response?[identifier]
          if message = status.message
            message = message.split('\n')[..-2].join ''
          @setVerified status.verified, message
        else
          @setVerified no
      .catch (err) =>
        @setVerified no, err.message

      .finally @verifyButton.bound 'hideLoader'


  viewAppended: kd.View::viewAppended


  pistachio: ->
    """
    <div class='credential-info clearfix'>
      {div.tag{#(provider)}} {div.title{#(title)}} {{> @inuseView}}
    </div>
    <div class='buttons'>
      {{> @showCredentialButton}}{{> @deleteButton}}{{> @verifyButton}}
    </div>
    {{> @warningView}}
    """
