JView = require '../../jview'
kd = require 'kd'
KDListItemView = kd.ListItemView
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class ModalMachineItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options, data)->

    options.cssClass = 'sidebar-item machine'
    options.partial  = ''

    super options, data

    href = "/IDE/#{data.slug}"

    @addSubView new KDCustomHTMLView
      tagName   : 'a'
      attributes: { href }
      partial   : data.label
      click     : (e) =>
        kd.utils.stopDOMEvent e
        @emit 'MachineSelected'
        kd.singletons.router.handleRoute href
