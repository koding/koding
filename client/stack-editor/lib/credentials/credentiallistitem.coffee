kd      = require 'kd'
globals = require 'globals'

Tracker = require 'app/util/tracker'
CustomLinkView = require 'app/customlinkview'
sendDataDogEvent = require 'app/util/sendDataDogEvent'

{ actions : HomeActions } = require 'home/flux'

module.exports = class CredentialListItem extends kd.ListItemView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "StackEditor-CredentialItem #{kd.utils.slugify data.provider}", options.cssClass

    super options, data

    delegate = @getDelegate()
    { identifier, owner, title, verified } = credential = @getData()

    @showCredentialButton = new CustomLinkView
      cssClass : 'secondary show'
      title : 'PREVIEW'
      click : =>
        delegate.emit 'ItemAction', { action : 'ShowItem', item : this }


    @deleteButton = new CustomLinkView
      cssClass : 'secondary delete'
      title : 'DELETE'
      click : =>
        delegate.emit 'ItemAction', { action : 'RemoveItem', item : this }

    @verifyButton = new kd.ButtonView
      cssClass : 'solid compact outline verify'
      title    : 'USE THIS & CONTINUE'
      loader   :
        color  : '#666'
        diameter : 24
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

    new kd.NotificationView { title : 'Verifying Credentials...', duration : 2000 }

    @warningView.hide()

    @getDelegate()
      .verify this
      .timeout globals.COMPUTECONTROLLER_TIMEOUT
      .then (response) =>
        if status = response?[identifier]
          if message = status.message
            messageLines = message.split('\n')
            message = messageLines[..-2].join ''  if messageLines.length > 1
          @setVerified status.verified, message
          HomeActions.markAsDone 'enterCredentials'
        else
          @setVerified no
      .catch (err) =>
        @setVerified no, err.message

      .finally @verifyButton.bound 'hideLoader'


  viewAppended: kd.View::viewAppended


  pistachio: ->

    """
    <div class='StackEditor-CredentialItem--flex'>
      <div class='StackEditor-CredentialItem--info'>
        {span.title{ #(title)}} {{> @inuseView}}
      </div>
      <div class='StackEditor-CredentialItem--buttons'>{{> @showCredentialButton}}{{> @deleteButton}}{{> @verifyButton}}</div>
    </div>
    {{> @warningView}}
    """
