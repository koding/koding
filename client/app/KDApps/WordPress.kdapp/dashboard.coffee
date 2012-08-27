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
  {path, domain, timestamp} = formData
  commands = [
    "mkdir -vp '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"
    "curl --location 'http://sinan.koding.com/planet.zip' >'/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip'"
    # "curl --location 'http://wordpress.org/latest.zip' >'/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip'"
    "unzip '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip' -d '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"
    "chmod 774 -R '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"
    "rm '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip'"
    "mv '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}/Users/sinan/Sites/sinan.koding.com/website/planet' '/Users/#{nickname}/Sites/#{domain}/website/#{path}';"
    # "mv '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}/wordpress' '/Users/#{nickname}/Sites/#{domain}/website/#{path}';"
    "rm -r '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"
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
                          parseOutput "<br>Wordpress successfully installed to: /Users/#{nickname}/Sites/#{domain}/website/#{path}"
                          parseOutput "<br>#############<br>"
                          callback? formData
                          appStorage.fetchStorage ->
                            blogs = appStorage.getValue("blogs") or []
                            blogs.push formData
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
      {path, domain, name} = listItemView.getData()
      command = "rm -r '/Users/#{nickname}/Sites/#{domain}/website/#{path}'"
      parseOutput "<br><br>Deleting /Users/#{nickname}/Sites/#{domain}/website/#{path}<br><br>"
      parseOutput command
      kc.run withArgs  : {command} , (err, res)=>
        if err
          parseOutput err, yes
          new KDNotificationView title : "There was an error, you may need to remove it manually!"
        else
          parseOutput "<br><br>#############"
          parseOutput "<br>#{name} successfully deleted."
          parseOutput "<br>#############<br><br>"
          tc.refreshFolder tc.nodes["/Users/#{nickname}/Sites/#{domain}/website"]

        __utils.wait 1500, ->
          split.resizePanel 0, 1

  removeItem:(listItemView)->
    @listController.removeItem listItemView
    appStorage.fetchStorage (storage)=>
      blogs = appStorage.getValue("blogs") or []
      @notice.show() if blogs.length is 0


  putNewItem:(formData, resizeSplit = yes)->

    @getDelegate().showPane @
    @listController.addItem formData
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
    {path, timestamp, domain, name} = @getData()
    url = "http://#{domain}/#{path}"
    """
    {{> @delete}}
    {{> #(name)}}
    <a href='#{url}' target='_blank'>#{url}</a>
    <a href='#{url}/wp-admin' target='_blank'>admin</a>
    <time datetime='#{new Date(timestamp)}'>#{$.timeago new Date(timestamp)}</time>
    """

class InstallPane extends Pane

  constructor:->

    super

    @form = new KDFormViewWithFields
      callback              : @submit.bind(@)
      buttons               :
        install             :
          title             : "Install Wordpress"
          style             : "cupid-green"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
      fields                :
        name                :
          label             : "Name of your blog:"
          name              : "name"
          placeholder       : "type a name for your blog..."
          defaultValue      : "My Wordpress"
          validate          :
            rules           :
              required      : "yes"
            messages        :
              required      : "a path for your wordpress is required!"
          keyup             : => @completeInputs()
          blur              : =>
            @completeInputs()
            path   = __utils.slugify name.getValue()
            kc.run
              toDo        : "fetchSafeFileName"
              withArgs    :
                filePath  : path
            , (err, res)-> 
              log err, res, ">>>> fetch safe name"
              if path isnt res
                log err, res
        domain              :
          label             : "Domain :"
          name              : "domain"
          itemClass         : KDSelectBox
          defaultValue      : "#{nickname}.koding.com"
          nextElement       :
            pathExtension   :
              label         : "/my-wordpress/"
              type          : "hidden"
        path                :
          label             : "Path :"
          name              : "path"
          placeholder       : "type a path for your blog... (just the last 'path' part)"
          defaultValue      : "my-wordpress"
          keyup             : => @completeInputs yes
          blur              : => @completeInputs yes
          validate          :
            rules           :
              required      : yes
              regExp        : /^[a-z\d]+([-][a-z\d]+)*$/i
            messages        :
              required      : "a path for your wordpress is required!"
              regExp        : "please enter a valid path!"
        # Database            :
        #   label             : "Create a new database:"
        #   name              : "db"
        #   title             : ""
        #   labels            : ["YES","NO"]
        #   itemClass         : KDOnOffSwitch
        timestamp           :
          name              : "timestamp"
          type              : "hidden"
          defaultValue      : Date.now()

    @form.on "FormValidationFailed", => @form.buttons["Install Wordpress"].hideLoader()

    domainsPath = "/Users/#{nickname}/Sites"

    kc.run
      withArgs  :
        command : "ls #{domainsPath} -lpva"
    , (err, response)=>
      if err then warn err
      else
        files = FSHelper.parseLsOutput [domainsPath], response
        newSelectOptions = []

        files.forEach (domain)->
          newSelectOptions.push {title : domain.name, value : domain.name}

        log newSelectOptions
        {domain} = @form.inputs
        domain.setSelectOptions newSelectOptions

  completeInputs:(fromPath = no)->
    {path, name, pathExtension} = @form.inputs
    if fromPath
      slug = __utils.slugify path.getValue()
    else
      slug = __utils.slugify name.getValue()
      path.setValue slug
    
    pathExtension.inputLabel.updateTitle "/#{slug}/"

  submit:(formData)=>
    split.resizePanel "50%", 1
    {path, domain, name} = formData
    formData.fullPath = "#{domain}/website/#{path}"
    installWordpress formData, (path, timestamp)=>
      @emit "WordPressInstalled", formData
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
      hideHandleContainer  : yes
      cssClass             : "wp-installer-tabs"

    @installButton = new KDButtonView
      title    : "Install a new Wordpress"
      callback : =>
        @dashboardTabs.showPaneByIndex 1

    @listButton = new KDButtonView
      title    : "Dashboard"
      callback : =>
        @dashboardTabs.showPaneByIndex 0


  viewAppended:->

    super

    @dashboardTabs.addPane dashboard = new DashboardPane
      cssClass : "dashboard"
      name     : "Your Wordpress instances"

    @dashboardTabs.addPane installPane = new InstallPane
      name     : "Install a new Wordpress"

    @dashboardTabs.showPane dashboard

    installPane.on "WordPressInstalled", (formData)->
      {domain, path} = formData
      dashboard.putNewItem formData
      __utils.wait 200, ->
        # timed out because we give some time to server to cleanup the temp files until it filetree refreshes
        tc.refreshFolder tc.nodes["/Users/#{nickname}/Sites/#{domain}/website"], ->
          __utils.wait 200, ->
            tc.selectNode tc.nodes["/Users/#{nickname}/Sites/#{domain}/website/#{path}"]

  pistachio:->

    """
    <header>
      <figure></figure>
      <article>
        <h3>Wordpress Installer</h3>
        <p>This application installs wordpress instances and gives you a dashboard of what is already installed</p>
      </article>
      <section>
      {{> @listButton}}
      {{> @installButton}}
      </section>
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






