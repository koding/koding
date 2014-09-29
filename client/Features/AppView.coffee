class FeaturesView extends KDView

  IMAGEPATH     = '/a/site.landing/images/features'
  TABS          =
    'VMs'       :
      image     : 'vms-ss.png'
      text      : "
        <h4>VMs with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>

        <h4>Terminal with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>

        <h4>Terminal with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>
      "
    'IDE'       :
      image     : 'ide-ss.png'
      text      : "
        <h4>IDE with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>

        <h4>Terminal with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>

        <h4>Terminal with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>
      "
    'Terminal'  :
      image     : 'terminal-ss.png'
      text      : "
        <h4>Terminal with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>

        <h4>Terminal with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>

        <h4>Terminal with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>
      "
    'Community' :
      image     : 'community-ss.png'
      text      : "
        <h4>Community with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>

        <h4>Terminal with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>

        <h4>Terminal with root access</h4>
        <p>It's time to play the music, it's time to light the lights.
        It's time to meet the Muppets on the Muppet Show tonight!
        It's time to put on makeup, it's time to dress up right.
        It's time to raise the curtain.</p>
      "

  BOTTOMFEATURES =
    'VMs'                  :
      'VM Specs'           :
        text               : "1 GB RAM, 3GB Storeage, 1Core CPU (burstable)"
        iconClass          : "pink vms-specs"
      'SSH Access'         :
        text               : "Full ssh access to your box. Use your localhost to connect to your Koding VM."
        iconClass          : "sand vms-access"
      'sudo Access'        :
        text               : "Unrestricted sudo access. Install anything, delete anything. You are in control."
        iconClass          : "green vms-access"
      'Install anything'   :
        text               : "No restrictions on what you can and can not install. Try anything."
        iconClass          : "light-blue vms-install"
      'Public IPs'         :
        text               : "VMs come with publicly accessible IPs making it super easy to connect to then."
        iconClass          : "blue vms-publicip"
      'Multiple VMs'       :
        text               : "Want more than one VM, easy!"
        iconClass          : "purple vms-multiple"
      'Always On'          :
        text               : "If you want to, you can now have an always on VM to run your dev server, blog, database or anything!"
        iconClass          : "red vms-alwayson"
      'Great for:'         :
        text               : "Development environtments, code repositories, experiments and small databases."
        iconClass          : "yellow vms-install"
      'Custom domains and nicknames' :
        text               : "It's time to play the music, it's time to light the lights. "
        iconClass          : "tinted-yellow vms-specs"

    'IDE'                  :
      'Workspaces'         :
        text               : "Use workspaces to organize your project work, just like on Sublime."
        iconClass          : "pink ide-workspaces"
      'Previews'           :
        text               : "Easily preview your work using the built-in browser."
        iconClass          : "sand ide-preview"
      'Collapsable Panes'  :
        text               : "Easily collapse our IDE's main frame to get more screen real estate for the IDE."
        iconClass          : "green ide-collapse"
      'Open Source'        :
        text               : "Don't like something? Change it and make the IDE better for everyone!"
        iconClass          : "light-blue ide-opensource"
      'Common editor settings' :
        text               : "Autocomplete, soft tabs, line numbers, word wrap, tab size, auto-indenting..are all there."
        iconClass          : "blue ide-settings"
      'Resize and Split panes' :
        text               : "Open many IDE windows and resize them the way you want."
        iconClass          : "purple terminal-split"
      'Graphical permissions' :
        text               : "Don't like setting permissions on the command line, do it via a handy GUI."
        iconClass          : "red ide-permissions"
      'multi-cursor support' :
        text               : "Easily change code/text across multiple lines."
        iconClass          : "yellow ide-multiplecursor"
      'Code folding'       :
        text               : "Easily fot away fragments of code taht you don't need to look at."
        iconClass          : "tinted-yellow ide-fold"

    'Terminal'             :
      'Fonts'              :
        text               : "A nice range of mono spaced fonts to chose from to make it your way."
        iconClass          : "pink terminal-fonts"
      'Split views'        :
        text               : "Split terminals into other Terminals...so many Terminals!"
        iconClass          : "sand terminal-split"
      'Resizeable'         :
        text               : "Resize the Terminal frame to make it perfect for your tasks."
        iconClass          : "green terminal-resize"
      'Chromebook friendly':
        text               : "Now you can have a Terminal on your Chromebook!"
        iconClass          : "light-blue terminal-chromebook"

    'Community'            :
      'Diverse global community':
        text               : "Our developer community is comprised of users from all over the globe so no matter what language you speak, you can make new friends and learn together."
        iconClass          : "pink com-diverse"
      'Channels for everything':
        text               : "Follow favorite topics or contribute to the collective learning for the same topic. Get help and help others."
        iconClass          : "sand ide-workspaces"
      'Chat'               :
        text               : "What to make something private? You can easily have private chats on Koding."
        iconClass          : "green ide-autocomplete"

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
      cssClass     : 'bottom-features'

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


