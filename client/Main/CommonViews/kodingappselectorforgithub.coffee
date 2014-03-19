class KodingAppSelectorForGitHub extends GitHub.Modal

  constructor:(options = {}, data)->
    options.title or= "Select app repository to publish"
    super options, data

  viewAppended:->
    super

    message = if @getOption 'customFilter' \
      then """To be able to select a repository, the name of the
              repository should match with the application name."""
      else "This list only includes repositories ends with '.kdapp'"

    @container.addSubView warning = new KDView
      cssClass : "warning"
      partial  : message

  repoFilter:(repos)->
    {customFilter} = @getOptions()
    _filter = customFilter ? /\.kdapp$/
    for repo in repos
      repo._disabled = !(_filter.test repo.full_name)
    repos