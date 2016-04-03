kd = require 'kd'

module.exports = sectionize = (title) ->

  new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'
    partial  : title
