class PrivateMessageRecipientModal extends KDModalViewWithForms


  constructor: (options = {}, data) ->

    options.title    or= ''
    options.cssClass or= 'private-message activity-modal add-participant'
    options.content  or= ''
    options.overlay   ?= yes
    options.width     ?= 330
    options.height   or= 'auto'
    options.arrowTop or= no
    # options.draggable  = handle : '.kdmodal' # breaks autocomplete focus
    options.tabs     or=
      forms             :
        Message         :
          callback      : @bound 'addParticipants'
          buttons       :
            send        :
              title     : 'Add to Conversation'
              style     : 'add-to-convo solid green'
              type      : 'submit'
              icon      : yes
          fields        :
            recipient   :
              itemClass : KDView
            results     :
              itemClass : KDView

    super options, data

    @chatHeads = new KDView cssClass : 'chat-heads'
    @modalTabs.forms.Message.inputs.results.addSubView @chatHeads
    @createUserAutoComplete()


  setFocus : -> @autoComplete.getView().setFocus()


  addParticipants: ->

    recipients = (nickname for {profile:{nickname}} in @autoComplete.getSelectedItemData())

    return KD.showError message : 'Please add a recipient.'  unless recipients.length


    KD.singletons.socialapi.channel.addParticipants (err, result) ->

      return KD.showError err  if err

      @destroy()


  createUserAutoComplete: ->

    form                      = @modalTabs.forms.Message
    {fields, inputs, buttons} = form

    @autoComplete = new KDAutoCompleteController
      form                : form
      name                : 'userController'
      placeholder         : 'Type a username...'
      itemClass           : ActivityAutoCompleteUserItemView
      itemDataPath        : 'profile.nickname'
      outputWrapper       : @chatHeads
      selectedItemClass   : ChatHead
      listWrapperCssClass : 'private-message'
      submitValuesAsText  : yes
      dataSource          : @bound 'fetchAccounts'

    autoCompleteView = @autoComplete.getView()

    autoCompleteView.on 'keydown', @bound 'handleRecipientKeydown'

    inputs.recipient.addSubView autoCompleteView


  fetchAccounts: PrivateMessageModal::fetchAccounts

  handleRecipientKeydown: PrivateMessageModal::handleRecipientKeydown