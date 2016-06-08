EnvironmentFlux = require 'app/flux/environment'

visibilityFilters = ['SidebarItemVisibilityStore']

visibilityFilter = (type, id) -> [
  visibilityFilters,
  (filters) -> filters.getIn [type, id]
]

sidebarStacks = [
  EnvironmentFlux.getters.stacks
  visibilityFilters
  (stacks, filters) ->
    stackFilters = filters.get 'stack'
    stacks.filter (stack) -> not stackFilters.has stack.get 'baseStackId'
]

sidebarDrafts = [
  EnvironmentFlux.getters.draftStackTemplates
  visibilityFilters
  (drafts, filters) ->
    draftFilters = filters.get 'draft'
    drafts.filter (draft) ->
      if draftFilter = draftFilters.get draft.get '_id'
        return draftFilter is 'visible'

      return draft.get('accessLevel') is 'private'
]


module.exports = {
  visibilityFilters
  visibilityFilter

  sidebarStacks
  sidebarDrafts
}
