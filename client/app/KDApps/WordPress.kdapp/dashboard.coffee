# 
# App Globals
#

kc         = KD.getSingleton "kiteController"
fc         = KD.getSingleton "finderController"
tc         = fc.treeController
{nickname} = KD.whoami().profile
appStorage = new AppStorage "wp-installer", "1.0"

# 
# App Functions
# 

parseOutput = (res, err = no)->
  res = "<br><cite style='color:red'>[ERROR] #{res}</cite><br>" if err
  output.setPartial res
  output.utils.wait 100, ->
    output.scrollTo
      top      : output.getScrollHeight()
      duration : 100

installWordpress = (formData, callback)->
  {path}     = formData
  timestamp  = Date.now()
  
  commands   = [
    "mkdir -vp '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/app.#{timestamp}'"
    "curl --location 'http://sinan.koding.com/planet.zip' >'/Users/#{nickname}/Sites/#{nickname}.koding.com/website/app.#{timestamp}.zip'"
    # "curl --location 'http://wordpress.org/latest.zip' >'/Users/#{nickname}/Sites/#{nickname}.koding.com/website/app.#{timestamp}.zip'"
    "unzip '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/app.#{timestamp}.zip' -d '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/app.#{timestamp}'"
    "chmod 774 -R '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/app.#{timestamp}'"
    "rm '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/app.#{timestamp}.zip'"
    "mv '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/app.#{timestamp}/Users/sinan/Sites/sinan.koding.com/website/planet' '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/#{path}';"
    # "mv '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/app.#{timestamp}/wordpress' '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/#{path}';"
    "rm -r '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/app.#{timestamp}'"
  ]

  parseOutput commands[0]
  kc.run withArgs  : command : commands[0] , (err, res)->
    if err then parseOutput err, yes
    else
      parseOutput res
      parseOutput "<br>$> " + commands[1] + "<br>"
      kc.run withArgs  : command : commands[1] , (err, res)->
        if err then parseOutput err, yes
        else
          parseOutput res
          parseOutput "<br>$> " + commands[2] + "<br>"
          kc.run withArgs  : command : commands[2] , (err, res)->
            if err then parseOutput err, yes
            else
              parseOutput res
              parseOutput "<br>$> " + commands[3] + "<br>"
              kc.run withArgs  : command : commands[3] , (err, res)->
                if err then parseOutput err, yes
                else
                  parseOutput res
                  parseOutput "<br>$> " + commands[4] + "<br>"
                  kc.run withArgs  : command : commands[4] , (err, res)->
                    if err then parseOutput err, yes
                    else
                      parseOutput res
                      parseOutput "<br>$> " + commands[5] + "<br>"
                      kc.run withArgs  : command : commands[5] , (err, res)->
                        if err then parseOutput err, yes
                        else
                          parseOutput res
                          parseOutput "<br>#############"
                          parseOutput "<br>Wordpress successfully installed to: /Users/#{nickname}/Sites/#{nickname}.koding.com/website/#{path}"
                          parseOutput "<br>#############<br>"
                          callback? path, timestamp
                          appStorage.fetchStorage ->
                            blogs = appStorage.getValue("blogs") or []
                            blogs.push {path, timestamp}
                            appStorage.setValue "blogs", blogs, noop
                          parseOutput "<br>$> " + commands[6] + "<br>"
                          kc.run withArgs  : command : commands[6] , (err, res)->
                            if err then parseOutput err, yes
                            else
                              parseOutput res
                              parseOutput "<br>temp files cleared!"

# 
# App Classes
# 

class Pane extends KDTabPaneView

  constructor:->

    super

    @listenWindowResize()

  viewAppended:->
    
    @setTemplate @pistachio()
    @template.update()
    @_windowDidResize()

  _windowDidResize:->

    tabView = @getDelegate()
    @setHeight tabView.parent.getHeight() - tabView.tabHandleContainer.getHeight()

class DashboardPane extends Pane

  constructor:->

    super

    @listController = new KDListViewController
      lastToFirst     : yes
      viewOptions     :
        subItemClass  : InstalledAppListItem
    
    @listWrapper = @listController.getView()
    
    @notice = new KDCustomHTMLView
      tagName : "p"
      partial : "Why you no create wordpress!!"

    @notice.hide()

    @listController.getListView().on "DeleteLinkClicked", (listItemView)=>
      
      @removeItem listItemView
      {path} = listItemView.getData()
      command = "rm -r '/Users/#{nickname}/Sites/#{nickname}.koding.com/website/#{path}'"
      parseOutput "<br><br>Deleting /Users/#{nickname}/Sites/#{nickname}.koding.com/website/#{path}<br><br>"
      parseOutput command
      kc.run withArgs  : {command} , (err, res)=>
        if err
          parseOutput err, yes
          new KDNotificationView title : "There was an error, you may need to remove it manually!"
        else
          parseOutput "<br><br>#############"
          parseOutput "<br>#{path} successfully deleted."
          parseOutput "<br>#############<br><br>"
          tc.refreshFolder tc.nodes["/Users/#{nickname}/Sites/#{nickname}.koding.com/website"]

  removeItem:(listItemView)->
    @listController.removeItem listItemView
    appStorage.fetchStorage (storage)=>
      blogs = appStorage.getValue("blogs") or []
      @notice.show() if blogs.length is 0


  putNewItem:({path, timestamp})->

    @getDelegate().showPane @
    @listController.addItem {path, timestamp}
    @notice.hide()


  viewAppended:->
    
    super
    
    appStorage.fetchStorage (storage)=>
      blogs = appStorage.getValue("blogs") or []
      if blogs.length > 0
        blogs.sort (a, b) -> if a.timestamp < b.timestamp then -1 else 1
        blogs.forEach @putNewItem.bind(@)
      else
        @notice.show()

  pistachio:->
    """
    {{> @notice}}
    {{> @listWrapper}}
    """

class InstalledAppListItem extends KDListItemView

  constructor:->

    super

    @delete = new KDCustomHTMLView
      tagName : "a"
      partial : "Delete"
      click   : (pubInst, event)=>
        blogs = appStorage.getValue "blogs"
        blogs.splice blogs.indexOf(@getData()), 1
        appStorage.setValue "blogs", blogs, =>
          @getDelegate().emit "DeleteLinkClicked", @

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    {path, timestamp} = @getData()
    url = "http://#{nickname}.koding.com/#{path}"
    """
    <a href='#{url}' target='_blank'>#{url}</a>
    <time>#{$.timeago new Date(timestamp)}</time>
    {{> @delete}}
    """

class InstallPane extends Pane

  constructor:->

    super

    @form = new KDFormViewWithFields
      callback              : @submit.bind(@)
      buttons               :
        "Install Wordpress" :
          style             : "modal-clean-gray"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
      fields                :
        Path                :
          label             : "Path"
          name              : 'path'
  
  submit:(formData)=> 
    installWordpress formData, (path, timestamp)=> 
      @emit "WordPressInstalled", path, timestamp
      @form.buttons["Install Wordpress"].hideLoader()

  pistachio:->
    """
    {{> @form}}
    """

# 
# Bootstrap
#

dashboardTabs = new KDTabView
  hideHandleCloseIcons : yes

output = new KDScrollView
  tagName  : "pre"
  cssClass : "terminal-screen"

appView.addSubView split = new KDSplitView
  type  : "horizontal"
  views : [dashboardTabs, output]

split.panels[1].setClass "terminal-tab"

dashboardTabs.addPane dashboard = new DashboardPane
  cssClass : "dashboard"
  name     : "Your Wordpress instances"

dashboardTabs.addPane installPane = new InstallPane
  name     : "Install a new Wordpress"

dashboardTabs.showPane dashboard

installPane.on "WordPressInstalled", (path, timestamp)->
  dashboard.putNewItem {path, timestamp}
  @utils.wait 200, ->
    # timed out because we give some time to server to cleanup the temp files until it filetree refreshes
    tc.refreshFolder tc.nodes["/Users/#{nickname}/Sites/#{nickname}.koding.com/website"]





