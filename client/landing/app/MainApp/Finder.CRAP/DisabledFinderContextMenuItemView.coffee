class DisabledFinderContextMenuItemView extends KDContextMenuTreeItem
  partial:(data)->
    """
    <div class='context-menu-item'>
      <span class='icon'></span>
      <a href='/#/#{data.type}/add' class='add-new-item' title='Add new #{data.type}'>#{data.title}</a>
    </div>
    """
  mouseEnter:(event)->
  mouseLeave:(event)->
