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

  commands =
    a : "mkdir -vp '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"
    b : "curl --location 'http://wordpress.org/latest.zip' >'/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip'"
    # b : "curl --location 'http://sinan.koding.com/planet.zip' >'/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip'"
    c : "unzip '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip' -d '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"
    d : "chmod 774 -R '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"
    e : "rm '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip'"

    # f : "mv '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}/Users/sinan/Sites/sinan.koding.com/website/planet' '/Users/#{nickname}/Sites/#{domain}/website/#{path}'"
    f : "mv '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}/wordpress' '/Users/#{nickname}/Sites/#{domain}/website/#{path}'"

    g : "rm -r '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"

  if path is ""
    commands.f = "cp -R /Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}/wordpress/* /Users/#{nickname}/Sites/#{domain}/website"
    # commands.f = "cp -R '/Users/#{nickname}/Sites/#{domain}/website/app.#{timestamp}/Users/sinan/Sites/sinan.koding.com/website/planet/*' '/Users/#{nickname}/Sites/#{domain}/website'"


  parseOutput commands.a
  kc.run withArgs  : command : commands.a , (err, res)->
    if err then parseOutput err, yes
    else
      parseOutput res
      parseOutput "<br>$> " + commands.b + "<br>"
      kc.run withArgs  : command : commands.b , (err, res)->
        if err then parseOutput err, yes
        else
          parseOutput res
          parseOutput "<br>$> " + commands.c + "<br>"
          kc.run withArgs  : command : commands.c , (err, res)->
            if err then parseOutput err, yes
            else
              parseOutput res
              parseOutput "<br>$> " + commands.d + "<br>"
              kc.run withArgs  : command : commands.d , (err, res)->
                if err then parseOutput err, yes
                else
                  parseOutput res
                  parseOutput "<br>$> " + commands.e + "<br>"
                  kc.run withArgs  : command : commands.e , (err, res)->
                    if err then parseOutput err, yes
                    else
                      parseOutput res
                      parseOutput "<br>$> " + commands.f + "<br>"
                      kc.run withArgs  : command : commands.f , (err, res)->
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
                          parseOutput "<br>$> " + commands.g + "<br>"
                          kc.run withArgs  : command : commands.g , (err, res)->
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
        itemClass  : InstalledAppListItem

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
          new KDNotificationView
            title    : "There was an error, you may need to remove it manually!"
            duration : 3333
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

    tabs = @getDelegate()
    tabs.showPane @
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
    <a target='_blank' class='name-link' href='#{url}'>{{ #(name)}}</a>
    <a target='_blank' class='admin-link' href='#{url}#{if path is "" then '' else '/'}wp-admin'>Admin</a>
    <a target='_blank' class='raw-link' href='#{url}'>#{url}</a>
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
              required      : "a name for your wordpress is required!"
          keyup             : => @completeInputs()
          blur              : =>
            @completeInputs()
            {name} = @form.inputs
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
          placeholder       : "type a path for your blog..."
          hint              : "leave empty if you want your blog to work on your domain root"
          defaultValue      : "my-wordpress"
          keyup             : => @completeInputs yes
          blur              : => @completeInputs yes
          validate          :
            rules           :
              regExp        : /(^$)|(^[a-z\d]+([-][a-z\d]+)*$)/i
            messages        :
              regExp        : "please enter a valid path!"
          nextElement       :
            timestamp       :
              name          : "timestamp"
              type          : "hidden"
              defaultValue  : Date.now()
        Database            :
          label             : "Create a new database:"
          name              : "db"
          title             : ""
          labels            : ["YES","NO"]
          itemClass         : KDOnOffSwitch

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

        {domain} = @form.inputs
        domain.setSelectOptions newSelectOptions

  completeInputs:(fromPath = no)->

    {path, name, pathExtension} = @form.inputs
    if fromPath
      val  = path.getValue()
      slug = __utils.slugify val
      path.setValue val.replace('/', '') if /\//.test val
    else
      slug = __utils.slugify name.getValue()
      path.setValue slug

    slug += "/" if slug

    pathExtension.inputLabel.updateTitle "/#{slug}"

  submit:(formData)=>

    split.resizePanel "50%", 1
    {path, domain, name} = formData
    formData.timestamp = parseInt formData.timestamp, 10
    formData.fullPath = "#{domain}/website/#{path}"
    installWordpress formData, (path, timestamp)=>
      @emit "WordPressInstalled", formData
      @form.buttons["Install Wordpress"].hideLoader()

  pistachio:-> "{{> @form}}"

class WpApp extends JView

  constructor:->

    super

    @dashboardTabs = new KDTabView
      hideHandleCloseIcons : yes
      hideHandleContainer  : yes
      cssClass             : "wp-installer-tabs"

    # @installButton = new KDButtonView
    #   title    : "Install a new Wordpress"
    #   callback : => @dashboardTabs.showPaneByIndex 1

    # @listButton = new KDButtonView
    #   title    : "Dashboard"
    #   callback : => @dashboardTabs.showPaneByIndex 0

    @buttonGroup = new KDButtonGroupView
      buttons       :
        "Dashboard" :
          cssClass  : "active"
          callback  : => @dashboardTabs.showPaneByIndex 0
        "Install a new Wordpress" :
          callback  : => @dashboardTabs.showPaneByIndex 1

    @dashboardTabs.on "PaneDidShow", (pane)=>
      if pane.name is "dashboard"
        @buttonGroup.buttonReceivedClick @buttonGroup.buttons.Dashboard
      else
        @buttonGroup.buttonReceivedClick @buttonGroup.buttons["Install a new Wordpress"]

  viewAppended:->

    super

    @dashboardTabs.addPane dashboard = new DashboardPane
      cssClass : "dashboard"
      name     : "dashboard"

    @dashboardTabs.addPane installPane = new InstallPane
      name     : "install"

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

    # {{> @listButton}}
    # {{> @installButton}}
    """
    <header>
      <figure></figure>
      <article>
        <h3>Wordpress Installer</h3>
        <p>This application installs wordpress instances and gives you a dashboard of what is already installed</p>
      </article>
      <section>
      {{> @buttonGroup}}
      </section>
    </header>
    {{> @dashboardTabs}}
    """

class WpSplit extends SplitView

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






