class SkillTagAutoCompleteController extends KDAutoCompleteController
  constructor: (options = {}, data) ->
    options.nothingFoundItemClass or= SuggestNewTagItem
    options.allowNewSuggestions    ?= yes
    super options, data

  putDefaultValues: (stringTags) ->
    return console.error "not implemented feature"

  getCollectionPath: -> 'skillTags'
