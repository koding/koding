class PersistingButtonMenu extends KDButtonMenu
  aClick: (instance, event) ->
    if event.target.className is 'chevron-arrow-ghost'
      @destroy()
    else if instance.$().parents('.kdbuttonmenu').length is 0 and not instance.$().hasClass 'kdbuttonmenu'
      super
