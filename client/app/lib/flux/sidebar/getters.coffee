_ = require 'lodash'
EnvironmentFlux = require 'app/flux/environment'

visibilityFilters = ['SidebarItemVisibilityStore']

visibilityFilter = (type, id) -> [
  visibilityFilters,
  (filters) -> filters.getIn [type, id]
]

sidebarStacks = [
  EnvironmentFlux.getters.stacks
  EnvironmentFlux.getters.teamStackTemplates
  EnvironmentFlux.getters.privateStackTemplates
  visibilityFilters
  (stacks, teamTemplates, privateTemplates, filters) ->
    templates = teamTemplates.concat privateTemplates
    stackFilters = filters.get 'stack'

    stacks
      .filter (stack) -> not stackFilters.has stack.get 'baseStackId'
      .map (stack) ->
        templateTitle = templates.getIn [stack.get('baseStackId'), 'title']
        stack = stack.set 'title', _.unescape templateTitle  if templateTitle

        return stack
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
