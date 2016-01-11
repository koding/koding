kd = require 'kd'
KDAutoCompleteListItemView = kd.AutoCompleteListItemView
KDAutoCompletedItem = kd.AutoCompletedItem
AutoCompleteProfileTextView = require './linkviews/autocompleteprofiletextview'
JView = require '../jview'


module.exports = class MemberAutoCompleteItemView extends KDAutoCompleteListItemView

  JView.mixin @prototype

  constructor:(options, data)->
    options.cssClass = "clearfix member-suggestion-item"
    super options, data

    userInput = options.userInput or @getDelegate().userInput

    @addSubView @profileLink = \
      new AutoCompleteProfileTextView {userInput, shouldShowNick: yes}, data
