kd = require 'kd'

module.exports = sectionize = (name, klass, options = {}, data) ->

  options.tagName or= 'section'
  defaultCssClass   = "HomeAppView--section #{kd.utils.slugify name}"

  options.cssClass  = if options.cssClass
  then kd.utils.curry options.cssClass, defaultCssClass
  else defaultCssClass

  new (klass or kd.CustomHTMLView) options, data
