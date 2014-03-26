class ConversationStarterButton extends KDButtonView

  constructor:(options, data)->

    options = $.extend
      cssClass  : 'clean-gray conversation-starter'
      icon      : yes
      iconClass : 'plus-black'
    , options

    super options, data

  click:->
    return  unless KD.isLoggedIn()

    conversationStarter = new ConversationStarter
    contextMenu   = new KDContextMenu
      menuWidth   : 200
      delegate    : @
      x           : @getX() - 206
      y           : @getY() - 6
      arrow       :
        placement : "right"
        margin    : 6
      lazyLoad    : yes
    , customView  : conversationStarter

    conversationStarter.on 'ConversationStarted', contextMenu.bound 'destroy'
    conversationStarter.focus()

class ConversationStarter extends JView

  constructor:->
    super
      cssClass : "conversation-starter-popup"

    @recipientsWrapper = new KDView
      cssClass : "completed-items hidden"

    @recipient = new KDAutoCompleteController
      name                : "recipient"
      itemClass           : MemberAutoCompleteItemView
      selectedItemClass   : MemberAutoCompletedItemView
      outputWrapper       : @recipientsWrapper
      itemDataPath        : "profile.nickname"
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : ({inputValue}, callback)=>
        blacklist = (data.getId() for data in @recipient.getSelectedItemData())
        KD.remote.api.JAccount.byRelevance \
          inputValue, {blacklist}, (err, accounts)=>
            callback accounts

    @startConversationButton = new KDButtonView
      title    : 'Create'
      cssClass : 'cupid-green create-conversation'
      callback : @bound 'createConversation'
    @startConversationButton.hide()

    @recipient.on 'ItemListChanged', (newCount)=>
      if newCount > 0
        @recipientsWrapper.show()
        @startConversationButton.show()
      else
        @startConversationButton.hide()

    @input = @recipient.getView()
    @input.setPlaceHolder "Start by typing user names..."

  viewAppended:->
    super
    @addSubView @input
    @addSubView @recipientsWrapper
    @addSubView @startConversationButton

  focus:->
    @input.setFocus()

  createConversation:->
    invitees = []
    for account in @recipient.selectedItemData
      {nickname} = account.profile
      invitees.push nickname

    KD.getSingleton("chatController").create invitees, =>
      @emit 'ConversationStarted'
