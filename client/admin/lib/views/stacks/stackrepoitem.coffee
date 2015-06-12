kd    = require 'kd'
JView = require 'app/jview'


module.exports = class StackRepoItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'repo-item', options.cssClass

    super options, data


  toggleSelectView: ->
    return @selectView.toggleClass 'hidden'  if @selectView

    repoData = @getData()
    delegate = @getDelegate()

    @selectView  = new kd.CustomHTMLView
      cssClass   : 'select-view'

    @selectView.addSubView branchOrTag = new kd.SelectBox
      placeholder   : 'Branch or Tag'
      selectOptions : [
        { title: 'Branch', value: 'branch' }
        { title: 'Tag',    value: 'tag' }
      ]

    @selectView.addSubView name = new kd.InputView
      placeholder : 'Branch/Tag Name'
      required    : yes

    @selectView.addSubView location = new kd.InputView
      placeholder : '/file/location.json'
      required    : yes

    @selectView.addSubView addButton = new kd.ButtonView
      title       : 'ADD'
      cssClass    : 'solid green medium'
      type        : 'submit'
      callback    : ->

        name      = name.getValue()
        type      = branchOrTag.getValue()
        location  = location.getValue()

        delegate.emit 'RepoSelected', { name, type, location, repoData }

    @addSubView @selectView


  click: (event) ->

    return  if (event.target.className.indexOf 'repo-item') <= 0

    @toggleClass 'active'
    @toggleSelectView()


  pistachio: ->

    { html_url } = @getData()

    """
    {a[href="#{html_url}" target="_blank"]{ #(full_name) }}
    {span.add-link{}}
    """
