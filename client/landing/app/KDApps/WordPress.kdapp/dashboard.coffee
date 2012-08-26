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
  {output} = split
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
    @listenTo
      KDEventTypes        : "PanelDidResize"
      listenedToInstance  : split
      callback            : => @_windowDidResize()

  _windowDidResize:->

    tabView = @getDelegate()
    @setHeight tabView.parent.getHeight() - tabView.tabHandleContainer.getHeight()

class DashboardPane extends Pane

  constructor:->

    super

    @listController = new KDListViewController
      lastToFirst     : yes
      viewOptions     :
        type          : "wp-blog"
        subItemClass  : InstalledAppListItem

    @listWrapper = @listController.getView()

    @notice = new KDCustomHTMLView
      tagName : "p"
      cssClass: "why-u-no"
      partial : "Why u no create wordpress!!!"

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

        __utils.wait 1500, ->
          split.resizePanel 0, 1

  removeItem:(listItemView)->
    @listController.removeItem listItemView
    appStorage.fetchStorage (storage)=>
      blogs = appStorage.getValue("blogs") or []
      @notice.show() if blogs.length is 0


  putNewItem:({path, timestamp}, resizeSplit = yes)->

    @getDelegate().showPane @
    @listController.addItem {path, timestamp}
    @notice.hide()
    if resizeSplit
      __utils.wait 1500, -> split.resizePanel 0, 1

  viewAppended:->

    super

    appStorage.fetchStorage (storage)=>
      blogs = appStorage.getValue("blogs") or []
      if blogs.length > 0
        blogs.sort (a, b) -> if a.timestamp < b.timestamp then -1 else 1
        blogs.forEach (item)=> @putNewItem item, no
      else
        @notice.show()

  pistachio:->
    """
    {{> @notice}}
    {{> @listWrapper}}
    """

class InstalledAppListItem extends KDListItemView

  constructor:(options, data)->

    options.type = "wp-blog"

    super options, data

    @delete = new KDCustomHTMLView
      tagName : "a"
      cssClass: "delete-link"
      click   : (pubInst, event)=>
        split.resizePanel "50%", 1
        blogs = appStorage.getValue "blogs"
        blogs.splice blogs.indexOf(@getData()), 1
        appStorage.setValue "blogs", blogs, =>
          @getDelegate().emit "DeleteLinkClicked", @

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()
    @utils.wait => @setClass "in"

  pistachio:->
    {path, timestamp} = @getData()
    url = "http://#{nickname}.koding.com/#{path}"
    """
    {{> @delete}}
    <a href='#{url}' target='_blank'>#{url}</a>
    <time datetime='#{new Date(timestamp)}'>#{$.timeago new Date(timestamp)}</time>
    """

class InstallPane extends Pane

  constructor:->

    super

    @form = new KDFormViewWithFields
      callback              : @submit.bind(@)
      buttons               :
        "Install Wordpress" :
          style             : "cupid-green"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
      fields                :
        name                :
          label             : "Name of your blog:"
          name              : "path"
          placeholder       : "type a name for your blog..."
          validate          :
            rules           :
              required      : "yes"
            messages        :
              required      : "a path for your wordpress is required!"
        Path                :
          label             : "Path </#{nickname}/Sites/#{nickname}.koding.com/website/[path]>:"
          name              : "path"
          placeholder       : "type a path for your blog... (just the last 'path' part)"
          validate          :
            rules           :
              required      : "yes"
            messages        :
              required      : "a path for your wordpress is required!"
        Database            :
          label             : "Create a new database:"
          name              : "db"
          title             : ""
          labels            : ["YES","NO"]
          itemClass         : KDOnOffSwitch

  submit:(formData)=>
    split.resizePanel "50%", 1
    installWordpress formData, (path, timestamp)=>
      @emit "WordPressInstalled", path, timestamp
      @form.buttons["Install Wordpress"].hideLoader()

  pistachio:->
    """
    {{> @form}}
    """

class WpApp extends JView

  constructor:->

    super

    @dashboardTabs = new KDTabView
      hideHandleCloseIcons : yes
      cssClass             : "wp-installer-tabs"

  viewAppended:->

    super

    @dashboardTabs.addPane dashboard = new DashboardPane
      cssClass : "dashboard"
      name     : "Your Wordpress instances"

    @dashboardTabs.addPane installPane = new InstallPane
      name     : "Install a new Wordpress"

    @dashboardTabs.showPane dashboard

    installPane.on "WordPressInstalled", (path, timestamp)->
      dashboard.putNewItem {path, timestamp}
      __utils.wait 200, ->
        # timed out because we give some time to server to cleanup the temp files until it filetree refreshes
        tc.refreshFolder tc.nodes["/Users/#{nickname}/Sites/#{nickname}.koding.com/website"], ->
          __utils.wait 200, ->
            tc.selectNode tc.nodes["/Users/#{nickname}/Sites/#{nickname}.koding.com/website/#{path}"]

  pistachio:->

    """
    <header>
      <figure></figure>
      <article>
        <h3>Wordpress Installer</h3>
        <p>This application installs wordpress instances and gives you a dashboard of what is already installed</p>
      </article>
    </header>
    {{> @dashboardTabs}}
    """

class WpSplit extends KDSplitView

  constructor:(options, data)->

    @output = new KDScrollView
      tagName  : "pre"
      cssClass : "terminal-screen"

    @wpApp = new WpApp

    options.views = [ @wpApp, @output ]

    super options, data

  viewAppended:->

    super

    @panels[1].setClass "terminal-tab"

#
# Bootstrap
#

appView.addSubView split = new WpSplit
  type      : "horizontal"
  resizable : no
  sizes     : ["100%",null]






