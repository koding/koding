class JContextMenuTreeView extends JTreeView

  constructor:(options = {}, data = {})->

    options.type     or= "contextmenu"
    options.animated or= no
    options.cssClass or= "default"
    super options, data
    @unsetClass "jtreeview"
