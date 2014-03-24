class GitHub.RepoItem extends KDListItemView

  constructor:(options = {}, data)->
    options.type = 'repo'
    options.buttonTitle or= 'clone'
    super options, data

    @actionButton = new KDButtonView
      title    : @getOption 'buttonTitle'
      cssClass : 'solid green mini action-button'
      callback : =>
        @getDelegate().emit "RepoSelected", @getData()
      disabled : data._disabled

    @setClass 'disabled'  if data._disabled

  viewAppended: JView::viewAppended

  pistachio:->

    {name, description, html_url} = @getData()

    """
    <h1>
      <a href="#{html_url}" target="_blank">#{name}</a>
    </h1>
    {p{#(description)}}
    {{> @actionButton}}
    """
