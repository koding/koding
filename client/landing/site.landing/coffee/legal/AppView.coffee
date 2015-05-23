JView          = require './../core/jview'
FooterView     = require './../home/footerview'
CustomLinkView = require './../core/customlinkview'
UserPolicyView = require './userpolicy'
PrivacyView    = require './privacy'
TosView        = require './tos'
CopyrightView  = require './copyright'
MainHeaderView = require '../core/mainheaderview'

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
    
    @addSubView @mainHeader = new MainHeaderView
 
    @setPartial @partial()

    @handles = {}
    @prepareTabHandles()

    @addSubView @footer = new FooterView


  prepareTabHandles : ->

    for sectionToken, sectionSettings of SECTIONS
      { isDefault, tabTitle } = sectionSettings
      tabPath = if isDefault then '' else "/#{sectionToken}"
      @handles[sectionToken] = handle = new CustomLinkView
        title           : tabTitle
        href            : "/Legal#{tabPath}"

      @addSubView handle, 'nav'


  selectTab : (token) ->

    if not token
      for sectionToken, sectionSettings of SECTIONS
        if sectionSettings.isDefault
          token = sectionToken
          break

    {bigTitle, view} = SECTIONS[token]

    for sectionToken, handle of @handles
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
