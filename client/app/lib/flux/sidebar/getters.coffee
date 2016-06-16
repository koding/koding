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
      .filter (stack) ->

        if stackFilter = stackFilters.get id = stack.get '_id'
          # check for id is for backwards compatibility. ~Umut
          return stackFilter in ['visible']
        else
          return yes

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
    drafts.filter (draft) ->
      if draftFilter = draftFilters.get id = draft.get '_id'
        # check for id is for backwards compatibility. ~Umut
        return draftFilter in ['visible', id]

      return draft.get('accessLevel') is 'private'
]


module.exports = {
  visibilityFilters
  visibilityFilter

  sidebarStacks
  sidebarDrafts
}
