class PrivateMessageForm extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.title    or= 'START A CHAT WITH:'
    options.cssClass or= 'new-message-form'

    options.fields     =
      recipient        :
        label          : 'TO'
        itemClass      : KDView
      purpose          :
        label          : 'PURPOSE'
        placeholder    : 'Optional'
        name           : 'purpose'

    super options, data

    @chatHeads = new KDView cssClass : 'autocomplete-heads'


  createUserAutoComplete: ->

    @autoComplete = new KDAutoCompleteController
      form                : this
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

    # need to wrap everyline
    # and put the input next to it
    # not gonna happen for now - SY

    # @autoComplete.on 'ItemListChanged', =>
    #   w   = @getWidth()
    #   chw = @chatHeads.getWidth()
    #   irw = @inputs.recipient.getWidth()
    #   autoCompleteView.setWidth irw - chw

    autoCompleteView.on 'keydown', @bound 'handleRecipientKeydown'

    @inputs.recipient.addSubView autoCompleteView


  fetchAccounts: ({inputValue}, callback) ->

    {search} = KD.singletons

    blacklist = @getOptions().blacklist ? []

    search.searchAccounts inputValue
      .filter (it) -> it.profile.nickname not in blacklist
      # the data source callback is not error-first style,
      # so just pass the callback to .then():
      .then callback


  handleRecipientKeydown: (event) ->

    return  unless lastItemData = @autoComplete.getSelectedItemData().last

    val    = @autoComplete.getView().getValue()
    input  = @autoComplete.getView()
    [item] = (item for item in @autoComplete.itemWrapper.getSubViews() when item.getData() is lastItemData)

    reset = =>
      input.setPlaceholder @autoComplete.getOptions().placeholder
      item.unsetClass 'selected'

    if event.which is 8 and val is ''

      if item.hasClass 'selected'
        @autoComplete.removeFromSubmitQueue item, lastItemData
        reset()
      else
        fullname = KD.utils.getFullnameFromAccount lastItemData
        input.setPlaceholder "Hit backspace again to remove #{Encoder.htmlDecode fullname}"
        item.setClass 'selected'
    else
      reset()


  viewAppended: ->

    super

    @inputs.recipient.addSubView @chatHeads
    @createUserAutoComplete()
    @addSubView @inputWidget = new PrivateMessageInputWidget form : this
    @autoComplete.getView().setFocus()
