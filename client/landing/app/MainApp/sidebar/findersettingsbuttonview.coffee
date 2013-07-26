class FinderSettingsButtonView extends KDButtonView

  constructor:(options={}, data)->
    options.title or= "General Settings"
    options.icon  or= yes
    options.iconOnly or= yes

    super options, data

    @appStorage = KD.getSingleton('appStorageController').storage 'Finder', '1.0'
    @appStorage.fetchStorage()

  click:->
    @switch?.destroy()
    @switch = new HideDotFilesSwitch {}, {appStorage:@appStorage}
    @switch.on "dotFileStateChanged", (state) => @emit "dotFileStateChanged", state
    @switch.toggle.setValue @appStorage.getValue "hideDotFiles"
    offset = @$().offset()
    contextMenu = new JContextMenu
      menuWidth   : 200
      x           : offset.left + 40
      y           : offset.top  - 19
      arrow       :
        placement : "left"
        margin    : 10
      lazyLoad    : yes
    ,
      customView1 : @switch


class HideDotFilesSwitch extends JView

  constructor:(options={}, data)->
    super options, data

    @appStorage = data.appStorage

    @toggle = new KDOnOffSwitch
      size     : "tiny"
      callback : @bound "hideFiles"

  hideFiles:(state)->
    @appStorage.fetchStorage (storage)=>
      return  unless storage
      @appStorage.setValue "hideDotFiles", state
      @emit "dotFileStateChanged", state

  pistachio:->
    """<span>Hide Dot Files</span> {{> @toggle}}"""