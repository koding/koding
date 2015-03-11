JView          = require './../core/jview'
FooterView     = require './../home/footerview'
CustomLinkView = require './../core/customlinkview'
UserPolicyView = require './userpolicy'
PrivacyView    = require './privacy'
TosView        = require './tos'
CopyrightView  = require './copyright'

module.exports = class LegalView extends JView

  SECTIONS     =
    'Policy'            :
      isDefault         : yes
      tabTitle          : 'User Policy'
      bigTitle          : 'Acceptable Use Policy'
      view              : new UserPolicyView
    'Privacy'           :
      tabTitle          : 'Privacy'
      bigTitle          : 'Privacy Policy'
      view              : new PrivacyView
    'Terms'             :
      tabTitle          : 'Terms of Service'
      bigTitle          : 'Koding Terms and Conditions (\'Agreement\')'
      view              : new TosView
    'Copyright'         :
      tabTitle          : 'Copyright'
      bigTitle          : 'Copyright/DMCA Guidelines'
      view              : new CopyrightView

  constructor:->

    super

    @setPartial @partial()

    @handles = {}
    @prepareTabHandles()
    @selectTab()

    @addSubView @footer = new FooterView


  prepareTabHandles : ->

    for token, settings of SECTIONS
      { isDefault, tabTitle } = settings
      tabPath = if isDefault then '' else "/#{token}"
      @handles[token] = handle = new CustomLinkView
        title           : tabTitle
        href            : "/Legal#{tabPath}"

      @addSubView handle, 'nav'


  selectTab : (token = 'Policy') ->
    {bigTitle, view} = SECTIONS[token]

    for tkn, handle of @handles
      handle.unsetClass 'active'

    @handles[token]?.setClass 'active'

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
