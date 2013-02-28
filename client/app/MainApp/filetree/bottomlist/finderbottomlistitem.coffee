class FinderBottomControlsListItem extends KDListItemView

  constructor:(options = {},data)->

    options.tagName or= "li"

    super options, data

    @title = new KDCustomHTMLView
      tagName : 'span'
      cssClass : 'title'
      partial : data.title
      tooltip :
        unless data.appPath or data.action
          title : "<p class='login-tip'>Coming Soon</p>"
          placement : "right"
          direction : 'center'

  click:(event)->
    {appPath} = @getData()
    event.preventDefault()
    if appPath?
      KD.getSingleton("appManager").open appPath if appPath?
    else if @getData().action is "showShortcuts"
      @showShortcuts()
    else if @getData().action is "manageRemotes"
      @getSingleton('mainController').emit 'ManageRemotesRequested'
    else
      new KDNotificationView
        title : "Coming Soon!"
        duration : 1000

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
      <a href="#">
        <span class='icon #{@getData().icon}'></span>
        {{>@title}}
      </a>
    """

  showShortcuts:->
    filetreeItems = [
      { keySet : "up,down",        title : "Navigate files" }
      { keySet : "shift+up,down",  title : "Multiple selection" }
      { keySet : "left,right",     title : "Open/Close folders" }
      { keySet : "enter",          title : "Open file" }
      { keySet : "delete",         title : "Delete file" }
      { keySet : "option+down",    title : "Context menu" }
    ]
    editorItems = [
      { keySet : "cmd+s",          title : "Save File" }
      { keySet : "cmd+shift+s",    title : "Save as..." }
      { keySet : "cmd+f",          title : "Find" }
      { keySet : "cmd+g",          title : "Find next" }
      { keySet : "cmd+shift+g",    title : "Find previous" }
      # { keySet : "cmd+b",          title : "Compile code" }
      # { keySet : "cmd+e",          title : "Run code" }
      # { keySet : "esc",            title : "Autocomplete" }
      # { keySet : "shift+esc",      title : "Backwards autocomplete" }
      # { keySet : "option+shift+q", title : "Close Editor" }
      # { keySet : "option+shift+d", title : "Split Editor Vertically" }
      # { keySet : "option+shift+c", title : "Split Editor Horizontally" }
    ]

    @_keyHelperModal.destroy() if @_keyHelperModal
    @_keyHelperModal = new KeyboardHelperModalView
      height    : "auto"
      position  :
        top     : 56
        right   : 5

    editorKeyHelperController = new KDListViewController
      view    : new KeyboardHelperView
        title : "Editor Shortcuts"
    , items : editorItems

    filetreeKeyHelperController = new KDListViewController
      view    : new KeyboardHelperView
        title : "Filetree Shortcuts"
    , items : filetreeItems

    @_keyHelperModal.addSubView filetreeKeyHelperController.getView()
    @_keyHelperModal.addSubView editorKeyHelperController.getView()
