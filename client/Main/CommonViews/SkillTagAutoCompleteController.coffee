class SkillTagAutoCompleteController extends KDAutoCompleteController
  constructor: (options = {}, data) ->
    options.nothingFoundItemClass or= SuggestNewTagItem
    options.allowNewSuggestions    ?= yes
    super options, data

  putDefaultValues: (stringTags) ->
    KD.remote.api.JTag.fetchSkillTags
      title     :
        $in     : stringTags
    ,
      sort      :
        title   : 1
    , (err, tags) =>
        unless err and not tags
        then @setDefaultValue tags
        else warn "There was a problem fetching default tags!", err, tags

  getCollectionPath: -> 'skillTags'
