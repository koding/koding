CustomLinkView = require './../core/customlinkview'

module.exports = class FeaturesView extends KDView

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

  constructor:(options = {}, data)->

    super options, data

    @setPartial @partial()

    @handles = []
    @prepareTabHandles()
    @selectTab('VMs')


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


  partial: ->

    """
    <section class='feature-tabs'>
      <nav class='tab-handles'></nav>
      <div class='tab-contents'></div>
    </section>
    """


