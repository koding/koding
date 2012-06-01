class MountContextMenuListItemView extends KDListItemView
  partial:(data)->
    $ "<div class='kdlistitemview default clearfix'>
        <span class='title'>#{data.title}</span>
      </div>"
