CustomLinkView = require './../core/customlinkview'
FooterView     = require './../home/footerview'

module.exports = class FeaturesView extends KDView

  IMAGEPATH     = '/a/site.landing/images/features'

  BOTTOMFEATURES =
    'VMs'                  :
      'VM Specs'           :
        text               : "1 GB RAM, 3GB Storage, 1 Core CPU (burstable). So much power!"
        iconClass          : "vms-specs"
      'SSH Access'         :
        text               : "Full SSH access to your box so you can still use your localhost to connect to your Koding VM."
        iconClass          : "vms-access"
      'sudo Access'        :
        text               : "Unrestricted root access to your box. Delete anything, update anything. You are in control."
        iconClass          : "vms-access"
      'Install anything'   :
        text               : "No restrictions on what you can and can not install. Try anything. Explore everything!"
        iconClass          : "vms-install"
      'Public IPs'         :
        text               : "VMs come with publicly accessible IPs making it super easy to work with them."
        iconClass          : "vms-publicip"
      'Multiple VMs'       :
        text               : "Upgrading will get you the ability to create up to 5 VMs."
        iconClass          : "vms-multiple"
      'Always-on'          :
        text               : "If you want to, you can now have an always-on VM to run your blog, database or anything!"
        iconClass          : "vms-alwayson"
      'Great for'         :
        text               : "Development environments, code repositories, experimentation and small databases."
        iconClass          : "vms-install"
      'Custom domains and nicknames' :
        text               : "Don’t like the machine name we picked, change it to something meaningful like 'app-box-1'!"
        iconClass          : "vms-specs"

    'IDE'                  :
      'Workspaces'         :
        text               : "Use workspaces to organize your project. Workspaces keep everything neat and tidy."
        iconClass          : "ide-workspaces"
      'Previews'           :
        text               : "Easily preview your work using the built-in browser. No more tab switching."
        iconClass          : "ide-preview"
      'Collapsable Panes'  :
        text               : "Collapse the IDE main frame to get more screen real estate."
        iconClass          : "ide-collapse"
      'Open Source'        :
        text               : "Don't like something? Change it and make the IDE better for everyone!"
        iconClass          : "ide-opensource"
      'Common editor settings' :
        text               : "Autocomplete, soft tabs, line numbers, word wrap, tab size, auto-indenting..are all there."
        iconClass          : "ide-settings"
      'Resize and Split panes' :
        text               : "Open several IDE tabs and resize them the way you want."
        iconClass          : "terminal-split"
      'Graphical permissions' :
        text               : "Don't like setting permissions on the command line, do it via a handy GUI."
        iconClass          : "ide-permissions"
      'Multi-cursor support' :
        text               : "Create multiple cursors and selections in order to make lots of similar edits at once."
        iconClass          : "ide-multiplecursor"
      'Code folding'       :
        text               : "Easily fold away fragments of code that you don't need to look at."
        iconClass          : "ide-fold"

    'Terminal'             :
      'Fonts'              :
        text               : "Terminal has a nice selection of monospaced fonts to choose from."
        iconClass          : "terminal-fonts"
      'Split views'        :
        text               : "Split terminals into other Terminals...so many Terminals!"
        iconClass          : "terminal-split"
      'Resizeable'         :
        text               : "Resize the Terminal frame to make it perfect for your tasks."
        iconClass          : "terminal-resize"

    'Community'            :
      'Support for Markdown':
        text               : "Full support for markdown in posts and comments. Say it with flair!"
        iconClass          : "com-markdown"
      'Follow/Unfollow anytime':
        text               : "Like a topic, follow it... No longer interested, unfollow. One click!"
        iconClass          : "com-diverse"
      'Search to get to what you want' :
        text               : "Scan through topic histories with our robust topic search."
        iconClass          : "com-search"


  constructor:(options = {}, data)->

    super options, data

    @setPartial @partial()

    @handles = {}
    @prepareTabHandles()

    @addSubView @footer = new FooterView


  prepareTabHandles: ->

    for tabName, content of TABS
      { isDefault } = content
      tabPath = if isDefault then '' else "/#{tabName}"
      @handles[tabName] = handle = new CustomLinkView
        title           : tabName
        href            : "/Features#{tabPath}"

      @addSubView handle, '.tab-handles'


  selectTab : (tabName) ->

    if not tabName
      for name, content of TABS
        if content.isDefault
          tabName = name
          break

    for name, handle of @handles
      handle.unsetClass 'active'

    @handles[tabName]?.setClass 'active'

    {text, image}   = TABS[tabName]

    tabView         = new KDCustomHTMLView
      tagName       : 'article'
      cssClass      : "tab-#{tabName.toLowerCase()} tab-enter clearfix"

    tabView.addSubView new KDCustomHTMLView
      cssClass      : 'tab-text'
      partial       : text

    tabView.addSubView new KDCustomHTMLView
      cssClass      : 'tab-image'
      tagName       : 'img'
      attributes    :
        'src'       : "#{IMAGEPATH}/#{image}"

    tabView.addSubView new KDCustomHTMLView cssClass: 'clearfix'

    tabView.addSubView @createBottomFeatures tabName

    if @currentTab
      leaveFn = =>
        @currentTab.destroy()
        @addSubView @currentTab = tabView, '.tab-contents'

      domElement = @currentTab.getDomElement()[0]

      domElement.addEventListener 'webkitAnimationEnd', leaveFn, false
      domElement.addEventListener 'animationend',       leaveFn, false

      @currentTab.setClass 'tab-leave'

    else
      @addSubView @currentTab = tabView, '.tab-contents'


  createBottomFeatures: (tabName) ->
    bottomFeatures = new KDCustomHTMLView
      cssClass     : 'bottom-features clearfix'

    for title, content of BOTTOMFEATURES[tabName]
      do (title, content) =>
        view = new KDCustomHTMLView
          cssClass    : 'feature-item'
          partial     : "
            <h5 class='#{content.iconClass}'><cite></cite>#{title}</h5>
            <p>#{content.text}</p>
          "
        bottomFeatures.addSubView view

    return bottomFeatures


  partial: ->

    """
    <section class='feature-tabs'>
      <nav class='tab-handles'></nav>
      <div class='tab-contents'></div>
    </section>
    """


