
class FetchedActivityAutoCompleteUserItemView extends KDAutoCompleteListItemView

  constructor:(options, data)->
    options.type = 'dropdown-member'
    super options, data

  viewAppended: ->
    userInput = @getOptions().userInput or @getDelegate().userInput

    obj = @getData()

    @addSubView new AvatarStaticView
      size      :
        width   : 25
        height  : 25
    , obj
    @addSubView @profileLink = new AutoCompleteProfileTextView {
      shouldShowNick : yes
      userInput
    }, obj


class FetchingActivityAutoCompleteUserItemView extends KDAutoCompleteFetchingItem

  constructor:(options, data) ->
    options.type = 'dropdown-member'
    super options, data


class ActivityAutoCompleteUserItemView

  constructor:(options, data)->
    isFetchingItem = data instanceof KDAutoCompleteFetchingItem
    isNothingFoundItem = data instanceof KDAutoCompleteNothingFoundItem

    if isFetchingItem
      return (new FetchingActivityAutoCompleteUserItemView(options, data))
    else if isNothingFoundItem
      return (new KDAutoCompleteNothingFoundItem(options, data))
    else
      return (new FetchedActivityAutoCompleteUserItemView(options, data))
