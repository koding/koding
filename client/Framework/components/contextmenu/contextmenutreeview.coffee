class JContextMenuTreeView extends JTreeView
  
  constructor:(options = {}, data = {})->

    options.type       = "contextmenu"
    options.animated   = no
    options.cssClass or= "default"
    super options, data
    @unsetClass "jtreeview"
