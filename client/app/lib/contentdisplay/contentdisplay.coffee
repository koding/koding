kd = require 'kd'
MainTabPane = require '../maintabpane'


module.exports = class ContentDisplay extends MainTabPane

  constructor:(options={}, data)->

    options.cssClass = kd.utils.curry "content-display-wrapper content-page", options.cssClass

    super
