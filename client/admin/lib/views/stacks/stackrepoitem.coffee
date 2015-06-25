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

    @selectView.addSubView branchOrTagInput = new kd.SelectBox
      placeholder   : 'Branch or Tag'
      selectOptions : [
        { title: 'Branch', value: 'branch' }
        { title: 'Tag',    value: 'tag' }
      ]

    @selectView.addSubView nameInput = new kd.InputView
      placeholder : 'Branch/Tag Name'
      required    : yes

    @selectView.addSubView locationInput = new kd.InputView
      placeholder : '/file/location.json'
      required    : yes

    @selectView.addSubView addButton = new kd.ButtonView
      title       : 'ADD'
      cssClass    : 'solid green medium'
      type        : 'submit'
      callback    : ->

        name      = nameInput.getValue()
        type      = branchOrTagInput.getValue()
        location  = locationInput.getValue()

        delegate.emit 'RepoSelected', {
          name, type, location, repoData
        }

    @addSubView @selectView


  click: (event) ->

    return  unless event.target.classList.contains 'repo-item'

    @toggleClass 'active'
    @toggleSelectView()


  pistachio: ->

    { html_url } = @getData()

    """
    {a[href="#{html_url}" target="_blank"]{ #(full_name) }}
    {span.add-link{}}
    """
