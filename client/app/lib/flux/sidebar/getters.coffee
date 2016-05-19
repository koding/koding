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
    stacks.filter (stack) ->
      not stackFilters.has stack.get 'baseStackId'
      not stack.getIn(['config', 'oldOwner'])
]

sidebarDrafts = [
  EnvironmentFlux.getters.draftStackTemplates
  visibilityFilters
  (drafts, filters) ->
    draftFilters = filters.get 'draft'
    drafts.filter (draft) -> not draftFilters.has draft.get '_id'
]


module.exports = {
  visibilityFilters
  visibilityFilter

  sidebarStacks
  sidebarDrafts
}
