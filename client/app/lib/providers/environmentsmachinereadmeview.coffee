kd            = require 'kd'
applyMarkdown = require 'app/util/applyMarkdown'

module.exports = class EnvironmentsMachineReadmeView extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'content-readme hidden', options.cssClass

    super options, data

    @render()


  render: ->

    readme = @getData()?.description ? ''
    return @hide()  unless readme

    @show()
    @wrapper.destroySubViews()

    readmeContent = new kd.CustomHTMLView
      partial  : applyMarkdown readme
      cssClass : 'has-markdown'

    @wrapper.addSubView readmeContent
    @getDomElement().find('a').attr('target', '_blank')
    @getDelegate().setClass 'has-readme'
