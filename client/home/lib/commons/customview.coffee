kd = require 'kd'

module.exports = customview = (name, klass, options = {}, data) ->

  options.tagName or= 'div'
  defaultCssClass   = "HomeAppView--custom #{kd.utils.slugify name}"

  options.cssClass  = if options.cssClass
  then kd.utils.curry options.cssClass, defaultCssClass
  else defaultCssClass

  new (klass or kd.CustomHTMLView) options, data
