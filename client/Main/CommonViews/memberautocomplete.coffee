class MemberAutoCompleteItemView extends KDAutoCompleteListItemView
  constructor:(options, data)->
    options.cssClass = "clearfix member-suggestion-item"
    super options, data

    userInput = options.userInput or @getDelegate().userInput

    @addSubView @profileLink = \
      new AutoCompleteProfileTextView {userInput, shouldShowNick: yes}, data

  viewAppended:-> JView::viewAppended.call this

class MemberAutoCompletedItemView extends KDAutoCompletedItem

  viewAppended:->
    @addSubView @profileText = new AutoCompleteProfileTextView {}, @getData()
    JView::viewAppended.call this
