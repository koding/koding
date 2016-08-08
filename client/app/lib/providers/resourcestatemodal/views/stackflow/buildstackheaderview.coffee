kd = require 'kd'

module.exports = class BuildStackHeaderView extends kd.CustomHTMLView

  constructor: (options, data) ->

    options.tagName ?= 'header'
    options.partial ?= "<h1>Build #{data.title}</h1>"

    super options, data
