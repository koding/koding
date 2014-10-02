JView          = require './../core/jview'
FooterView     = require './../home/footerview'
CustomLinkView = require './../core/customlinkview'
UserPolicyView = require './userpolicy'
PrivacyView    = require './privacy'
TosView        = require './tos'
CopyrightView  = require './copyright'

module.exports = class LegalView extends JView

  SECTIONS     =
    'User Policy'       :
      bigTitle          : 'Acceptable Use Policy'
      view              : new UserPolicyView
    'Privacy'           :
      bigTitle          : 'Privacy Policy'
      view              : new PrivacyView
    'Terms of Service'  :
      bigTitle          : 'Koding Terms and Conditions (\'Agreement\')'
      view              : new TosView
    'Copyright'         :
      bigTitle          : 'Copyright/DMCA Guidelines'
      view              : new CopyrightView

  constructor:->

    super

    @setPartial @partial()

    @handles = []
    @prepareTabHandles()
    @selectTab 'User Policy'

    @addSubView @footer = new FooterView


  prepareTabHandles : ->

    for title, content of SECTIONS
      do (title, content) =>
        @handles.push handle = new CustomLinkView
          title           : title
          click           : =>
            @selectTab title

            for item in @handles
              item.unsetClass 'active'
              handle.setClass 'active'

        @addSubView handle, 'nav'

    @handles[0].setClass 'active'

  selectTab : (name) ->
    {bigTitle, view} = SECTIONS[name]

    if @currentTab
      @currentTab.destroy()
      @bigTitle.destroy()

    @currentTab = view
    @bigTitle   = new KDCustomHTMLView
      tagName   : 'span'
      partial   : bigTitle

    @addSubView @currentTab, 'article'
    @addSubView @bigTitle, '.introduction'


  partial : ->
    """
    <section class='introduction'></section>
    <section class='content'>
      <nav class='handles'></nav>
      <article>
      </article>
    </section>
    """
