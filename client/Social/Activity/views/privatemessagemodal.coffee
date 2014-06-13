class PrivateMessageModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.title    or= 'START A PRIVATE CONVERSATION BETWEEN YOU AND:'
    options.cssClass or= 'private-message activity-modal'
    options.content  or= ''
    options.overlay   ?= yes
    options.width     ?= 660
    options.height   or= 'auto'
    options.tabs     or=
      forms            :
        Message        :
          callback     : @bound 'submitMessage'
          buttons      :
            send       :
              style    : 'message-send solid green'
              type     : 'submit'
              iconOnly : yes
            cancel     :
              title    : 'Nevermind'
              style    : 'transparent'
              callback : (event) =>
                @getDelegate()._lastMessage = null
                @destroy()
          fields           :
            recipient      :
              itemClass    : KDView
            body           :
              label        : ''
              name         : 'body'
              type         : 'textarea'
              defaultValue : options._lastMessage
              placeholder  : "What's on your mind? Don't forget to @mention people you want this message to be sent."
              keyup        : @bound 'handleBodyKeyup'
              validate     :
                rules      : required : yes
                messages   : required : 'You forgot to put some message in.'

    super options, data

    @once 'KDModalViewDestroyed', ->
      if /\/Activity\/Message\/New$/.test KD.singletons.router.visitedRoutes.last
        KD.singletons.router.back()

    KD.singletons.router.once 'RouteInfoHandled', -> modal?.destroy()
    @chatHeads?.destroy()
    @chatHeads = new KDView cssClass : 'chat-heads'

    @modalTabs.forms.Message.inputs.recipient.addSubView @chatHeads

    @createUserAutoComplete()


  submitMessage : ->

    {body} = @modalTabs.forms.Message.inputs
    {send} = @modalTabs.forms.Message.buttons
    val    = body.getValue()

    recipients = (nickname for {profile:{nickname}} in @autoComplete.getSelectedItemData())
    recipients = recipients.map (recipient)-> "@#{recipient}"
    recipients = recipients.join ' '

    val = "#{val} // #{recipients}"

    {router, socialapi, notificationController} = KD.singletons

    socialapi.message.sendPrivateMessage body : val, (err, channels) =>

      send.hideLoader()

      return KD.showError err  if err

      [channel]            = channels
      appView              = @getDelegate()
      {sidebar}            = appView
      appView._lastMessage = null

      sidebar.addToChannel channel
      router.handleRoute "/Activity/Message/#{channel.id}"

      @destroy()


  createUserAutoComplete: ->

    form                      = @modalTabs.forms.Message
    {fields, inputs, buttons} = form

    @autoComplete = new KDAutoCompleteController
      form                : form
      name                : 'userController'
      placeholder         : 'Type a username to start your conversation...'
      itemClass           : ActivityAutoCompleteUserItemView
      itemDataPath        : 'profile.nickname'
      outputWrapper       : @chatHeads
      selectedItemClass   : ChatHead
      listWrapperCssClass : 'private-message'
      submitValuesAsText  : yes
      dataSource          : @bound 'fetchAccounts'

    autoCompleteView = @autoComplete.getView()

    @autoComplete.on 'ItemListChanged', =>
      heads = @autoComplete.getSelectedItemData()
      autoCompleteView.setWidth inputs.recipient.getWidth() - heads.length * 35

    autoCompleteView.on 'keyup', @bound 'handleRecipientKeyup'

    inputs.recipient.addSubView autoCompleteView


  fetchAccounts: (args, callback) ->

    {JAccount}   = KD.remote.api
    {inputValue} = args

    val = inputValue.replace /^@/, ''

    return  if inputValue.length < 4

    query = 'profile.nickname': val

    JAccount.one query, (err, account) =>
      if not account or KD.isMine account
      then @autoComplete.showNoDataFound()
      else callback [account]

    #   byEmail = /[^\s@]+@[^\s@]+\.[^\s@]+/.test inputValue
    #   JAccount.byRelevance inputValue, {byEmail}, (err, accounts)->
    #     callback accounts


  handleBodyKeyup: (event) ->

    {body} = @modalTabs.forms.Message.inputs

    @getDelegate()._lastMessage = body.getValue()


  handleRecipientKeyup: (event) ->

    val = @autoComplete.getView().getValue()

    # fixme: handle backspace here
    # to delete a chat-head

    # if event.which is 8 and val is ''
    #   log 'sil bi eleman'
    #   debugger
