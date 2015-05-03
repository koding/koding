JView             = require './../core/jview'
MainHeaderView    = require './../core/mainheaderview'

module.exports = class TeamDomainTab extends KDFormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

    @input = new KDInputView
      placeholder : 'your-team'

    @button = new KDButtonView
      title       : 'NEXT'
      style       : 'SignupForm-button SignupForm-button--green'
      attributes  : testpath  : 'domain-button'
      loader      : yes
      callback    : =>
        console.log 'go to email:'
        KD.singletons.router.handleRoute '/Team/alloweddomain'


  pistachio: ->

    """
    <div class='login-input-view'>{{> @input}}<span>.koding.com</span></div>
    <p class='dim'>Your team url can only contain lowercase letters numbers and dashes.</p>
    {{> @button}}
    """