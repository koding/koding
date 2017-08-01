kd = require 'kd'
KDAutoCompleteListItemView = kd.AutoCompleteListItemView
AutoCompleteProfileTextView = require './linkviews/autocompleteprofiletextview'



module.exports = class MemberAutoCompleteItemView extends KDAutoCompleteListItemView



  constructor: (options, data) ->
    options.cssClass = 'clearfix member-suggestion-item'
    super options, data

    userInput = options.userInput or @getDelegate().userInput

    @addSubView @profileLink = \
      new AutoCompleteProfileTextView { userInput, shouldShowNick: yes }, data
