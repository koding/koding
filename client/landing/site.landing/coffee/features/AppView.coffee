CustomLinkView = require './../core/customlinkview'
FooterView     = require './../home/footerview'

module.exports = class FeaturesView extends KDView

  IMAGEPATH     = '/a/site.landing/images/features'
  TABS          =
    'VMs'       :
      image     : 'vms-ss.png'
      text      : "
        <h4>Hosted on Amazon</h4>
        <p>Koding VMs are essentially Amazon VMs which means they carry with
        them the dependability that Amazon's cloud infrastructure is known for.
        Your Koding VM will be an Amazon t2.micro instance.</p>

        <h4>Docker</h4>
        <p>Koding VMs are not sliced up hosts running LXC. This means that
        you can easily run advanced technologies like Docker and still keep your file tree clean.
       </p>

        <h4>Ubuntu 14.04</h4>
        <p>Koding VMs run Ubuntu 14.04 and come with
        all the default packages and software that ship with a standard
        Ubuntu image (plus we have added a few more goodies).</p>
      "
    'IDE'       :
      image     : 'ide-ss.png'
      text      : "
        <h4>Multiple language support</h4>
        <p>Go, NodeJS, Ruby, Python, PHP, Java, C, C++, Javascript, Coffeescript,
        etc. whatever your language of choice, our IDE supports it and gives you
        gorgeous syntax highlighting.</p>

        <h4>Awesome shortcuts</h4>
        <p>Let that mouse take a rest for a while and unleash your typing super
        powers by using our extensive keyboard shortcuts to control everything
        inside the IDE.</p>

        <h4>Themes</h4>
        <p>Easily switch the default color theme and font to one from a growing
        list of choices. We are sure that you will find a favorite within minutes.</p>
      "
    'Terminal'  :
      image     : 'terminal-ss.png'
      text      : "
        <h4>Themes</h4>
        <p>Terminal offers multiple color themes and font selections so that
        you can change the default to one that makes it easier for you to
        spend hours on Koding.</p>

        <h4>Chromebook Friendly</h4>
        <p>Linux terminal and Chromebooks...together at last. Terminal runs
        nicely inside your Chromebook giving you the full power of Koding
        on the go.</p>

        <h4>Multi-tab</h4>
        <p>Open as many Terminal tabs as you would like. Each Terminal tab lives
        inside its own independent process. Multitask like there’s no tomorrow!</p>
      "
    'Community' :
      image     : 'community-ss.png'
      text      : "
        <h4>Diverse global community</h4>
        <p>Our developer community is comprised of users from
        all over the globe so no matter what language you speak,
        you can make new friends and learn together.</p>

        <h4>Channels for everything code related</h4>
        <p>Post, comment or follow your favorite topic channels and contribute
        to the collective learning of the Koding community.
        Get help and help others.</p>

        <h4>Chat</h4>
        <p>Not all conversations are publick, so if you want to take something private,
        we offer the ability to easily host private one-on-one and private group
        conversations.</p>
      "

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
        text               : "Use workspaces to organize your project. Workpsaces keeps everything neat and tidy."
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
      'multi-cursor support' :
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

    @handles = []
    @prepareTabHandles()
    @selectTab('VMs')

    @createBottomFeatures()

    @addSubView @footer = new FooterView


  prepareTabHandles: ->

    for title, content of TABS
      do (title, content) =>
        @handles.push handle = new CustomLinkView
          title           : title
          click           : =>
            @selectTab title

            for item in @handles
              item.unsetClass 'active'
              handle.setClass 'active'


        @addSubView handle, '.tab-handles'

    @handles[0].setClass 'active'


  selectTab : (name) ->
    {text, image}   = TABS[name]

    tabView         = new KDCustomHTMLView
      tagName       : 'article'
      cssClass      : "tab-#{name.toLowerCase()} tab-enter clearfix"

    tabView.addSubView new KDCustomHTMLView
      cssClass      : 'tab-text'
      partial       : text

    tabView.addSubView new KDCustomHTMLView
      cssClass      : 'tab-image'
      tagName       : 'img'
      attributes    :
        'src'       : "#{IMAGEPATH}/#{image}"

    tabView.addSubView new KDCustomHTMLView cssClass: 'clearfix'

    tabView.addSubView @createBottomFeatures name

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


