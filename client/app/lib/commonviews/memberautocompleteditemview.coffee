kd = require 'kd'
KDAutoCompletedItem = kd.AutoCompletedItem

AutoCompleteProfileTextView = require './linkviews/autocompleteprofiletextview'


module.exports = class MemberAutoCompletedItemView extends KDAutoCompletedItem



  viewAppended: ->
    @addSubView @profileText = new AutoCompleteProfileTextView {}, @getData()
