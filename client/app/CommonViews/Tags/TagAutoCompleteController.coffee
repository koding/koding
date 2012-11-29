class TagAutoCompleteController extends KDAutoCompleteController
  constructor:(options, data)->
    options.nothingFoundItemClass or= SuggestNewTagItem
    options.allowNewSuggestions or= yes
    super

class TagAutoCompleteItemView extends KDAutoCompleteListItemView
  constructor:(options, data)->
    options.cssClass = "clearfix"
    super

  pistachio:->"<span class='ttag'>{{#(title)}}</span>"

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  partial:()-> ''

class TagAutoCompletedItemView extends KDAutoCompletedItem
  constructor:(options, data)->
    options.cssClass = "clearfix"
    super
    @tag = new TagLinkView { clickable:no },data

  pistachio:->
    "{{> @tag}}"

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  partial:()-> ''

class SuggestNewTagItem extends KDAutoCompleteListItemView

  constructor:(options, data)->
    options.cssClass = "suggest clearfix"
    super options, data

  partial:->
    "Suggest <span class='ttag'>#{@getOptions().userInput}</span> as a new topic?"
