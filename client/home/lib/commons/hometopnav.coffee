kd             = require 'kd'
CustomLinkView = require 'app/customlinkview'

module.exports = class HomeTopNav extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    super options, data

    { items } = @getOptions()

    for item in items
      @addSubView new CustomLinkView
        title : item
        href  : "#{kd.singletons.router.getCurrentPath()}/#{item}"




