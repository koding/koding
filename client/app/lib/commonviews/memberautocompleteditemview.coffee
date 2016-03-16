kd = require 'kd'
KDAutoCompletedItem = kd.AutoCompletedItem
JView = require '../jview'
AutoCompleteProfileTextView = require './linkviews/autocompleteprofiletextview'


module.exports = class MemberAutoCompletedItemView extends KDAutoCompletedItem

  JView.mixin @prototype

  viewAppended: ->
    @addSubView @profileText = new AutoCompleteProfileTextView {}, @getData()
