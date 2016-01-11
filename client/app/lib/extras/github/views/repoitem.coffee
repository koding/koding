kd = require 'kd'
KDButtonView = kd.ButtonView
KDListItemView = kd.ListItemView
JView = require '../../../jview'


module.exports = class RepoItem extends KDListItemView

  JView.mixin @prototype

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

  pistachio:->

    {name, description, html_url} = @getData()

    """
    <h1>
      <a href="#{html_url}" target="_blank">#{name}</a>
    </h1>
    {p{#(description)}}
    {{> @actionButton}}
    """
