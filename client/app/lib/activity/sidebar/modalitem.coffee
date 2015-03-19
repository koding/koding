JView = require '../../jview'
kd = require 'kd'
KDListItemView = kd.ListItemView
KDCustomHTMLView = kd.CustomHTMLView

module.exports = class ModalItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = "sidebar-item #{options.type}"
    options.partial  = ''

    super options, data

    {href, title} = @getOptions()

    @addSubView new KDCustomHTMLView
      tagName    : 'a'
      attributes : { href }
      partial    : title
      click      : (e) =>
        kd.utils.stopDOMEvent e
        @emit 'ModalItemSelected'
        kd.singletons.router.handleRoute href
