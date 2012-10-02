class BookDevelopButton extends KDButtonViewWithMenu

  constructor:->

    options =
      style         : 'editor-advanced-settings-menu'
      icon          : yes
      iconOnly      : yes
      # iconClass     : "cog"
      type          : "contextmenu"
      subItemClass  : AceSettingsView
      click         : (pubInst, event)-> @contextMenu event
      menu          : [AceView::getAdvancedSettingsMenuItems()]

    super options
