JView = require '../../jview'
kd = require 'kd'
KDListItemView = kd.ListItemView
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class ModalWorkspaceItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'sidebar-item workspace'
    options.partial  = ''

    super

    href = "/IDE/#{data.machineLabel}/#{data.slug}"

    @addSubView new KDCustomHTMLView
      tagName   : 'a'
      attributes: { href }
      partial   : data.name
      click     : (e) =>
        kd.utils.stopDOMEvent e
        @emit 'WorkspaceSelected'
        kd.singletons.router.handleRoute href
