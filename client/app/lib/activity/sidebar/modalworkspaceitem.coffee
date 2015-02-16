JView = require '../../jview'
kd = require 'kd'
KDListItemView = kd.ListItemView


module.exports = class ModalWorkspaceItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type     = 'sidebar-item'
    options.partial  = ''

    super

    href = "/IDE/#{data.machineLabel}/#{data.slug}"

    @addSubView new KDCustomHTMLView
      tagName   : 'a'
      attributes: { href }
      partial   : data.name
      click     : (e) =>
        KD.utils.stopDOMEvent e
        @emit 'WorkspaceSelected'
        kd.singletons.router.handleRoute href
