kd = require 'kd'
KDAutoCompleteListItemView = kd.AutoCompleteListItemView
AvatarStaticView = require 'app/commonviews/avatarviews/avatarstaticview'
AutoCompleteProfileTextView = require 'app/commonviews/linkviews/autocompleteprofiletextview'


module.exports = class ActivityAutoCompleteUserItemView extends KDAutoCompleteListItemView

  constructor:(options, data)->

    options.type = 'dropdown-member'

    super options, data


  viewAppended: ->

    userInput = @getOptions().userInput or @getDelegate().userInput

    @addSubView new AvatarStaticView
      size      :
        width   : 25
        height  : 25
    , @getData()

    @addSubView @profileLink = new AutoCompleteProfileTextView {
      shouldShowNick : yes
      userInput
    }, @getData()
