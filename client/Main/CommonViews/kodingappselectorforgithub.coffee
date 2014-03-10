class KodingAppSelectorForGitHub extends GitHub.Modal

  constructor:(options = {}, data)->
    options.title = "Select app repository to publish"
    super options, data

  viewAppended:->
    super

    @container.addSubView warning = new KDView
      cssClass : "warning"
      partial  : "This list only includes repositories ends with '.kdapp'"

  repoFilter:(repos)->
    repos.filter (repo)->
      /\.kdapp$/.test repo.full_name
