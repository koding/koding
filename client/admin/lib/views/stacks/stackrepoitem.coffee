kd    = require 'kd'
JView = require 'app/jview'


module.exports = class StackRepoItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'repo-item', options.cssClass

    super options, data

    @addButton = new kd.ButtonView
      title    : 'ADD'
      cssClass : 'solid green mini action-button'
      callback : =>
        @getDelegate().emit "RepoSelected", @getData()


  toggleSelectView: ->
    return @selectView.toggleClass 'hidden'  if @selectView

    @selectView  = new kd.CustomHTMLView
      partial    : 'Hello World'

    @addSubView @selectView


  click: ->
    @toggleClass 'active'
    @toggleSelectView()


  pistachio: ->

    { html_url } = @getData()

    """
    {a[href="#{html_url}" target="_blank"]{ #(full_name) }}
    {span.add-link{}}
    """
