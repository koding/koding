class ActivityAutoCompleteUserItemView extends KDAutoCompleteListItemView

  constructor:(options, data)->

    options.type = 'dropdown-member'

    super options, data



  viewAppended: ->

    userInput = @getOptions().userInput or @getDelegate().userInput

    @addSubView @profileLink = new AutoCompleteProfileTextView {
      shouldShowNick : yes
      userInput
    }, @getData()

