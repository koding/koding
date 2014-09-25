class ActivityAutoCompleteUserItemView extends KDAutoCompleteListItemView

  constructor:(options, data)->

    options.type = 'dropdown-member'

    super options, data


  viewAppended: ->

    userInput = @getOptions().userInput or @getDelegate().userInput

    @addSubView @addSubView new AvatarStaticView
      size      :
        width   : 25
        height  : 25
    , @getData()

    @addSubView @profileLink = new AutoCompleteProfileTextView {
      shouldShowNick : yes
      userInput
    }, @getData()

