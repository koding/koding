kd              = require 'kd.js'
utils           = require './../core/utils'
MainHeaderView  = require './../core/mainheaderview'
JView           = require './../core/jview'
LoginInputView  = require './../login/logininputview'

track = (action, entry) ->

  category = 'TeamLogin'
  label    = 'SignupForm'
  entry    = entry

  utils.analytics.track action, { category, label, entry }


module.exports = class TeamSelectorView extends JView


  constructor:(options = {}, data)->

    options.cssClass = kd.utils.curry 'Team', options.cssClass

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : [
        { title : 'Blog',        href : 'http://blog.koding.com',   name : 'blog' }
        { title : 'Features',    href : '/Features',                name : 'features' }
      ]

    @form = new kd.FormView
      cssClass : 'login-form'
      partial  : """
        <div class='team-name-or-domain'></div>
        <div class='submit'></div>
        """
      callback : (formData) ->

        notify   = -> new kd.NotificationView
          title: 'We don\'t have this team! Please try again.'
          type: 'growl'
        navigate = (slug) ->
          location.assign "#{location.protocol}//#{slug}.#{location.host}"

        { companyName } = formData

        return notify()  if companyName is 'koding'

        track 'navigated to team login page', companyName

        utils.checkIfGroupExists companyName, (err, group) ->

          unless err
            return notify()  unless group
            return navigate group.slug

          utils.verifySlug slug = kd.utils.slugify(companyName),
            success: -> notify()
            error: ->
              utils.usernameCheck slug,
                success: ({kodingUser, forbidden}) ->
                  return notify()  if kodingUser or forbidden
                  navigate slug
                error: -> notify()


    @form.addSubView @form.companyName = new LoginInputView
      inputOptions    :
        name          : 'companyName'
        placeholder   : 'Team name or domain'
        attributes    : testpath : 'company-name'
        validate      :
          rules       :
            required  : yes
          messages    :
            required  : "Please enter a team name or domain."
    , '.team-name-or-domain'

    @form.addSubView @button = new kd.ButtonView
      title       : 'Go to your team'
      icon        : yes
      style       : 'TeamsModal-button TeamsModal-button--green'
      attributes  : testpath : 'goto-team-button'
      type        : 'submit'
    , '.submit'


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--select">
      <h4>Sign in to your team</h4>
      {{> @form}}
    </div>
    <footer>
      <a href="/Legal" target="_blank">Acceptable user policy</a><a href="/Legal/Copyright" target="_blank">Copyright/DMCA guidelines</a><a href="/Legal/Terms" target="_blank">Terms of service</a><a href="/Legal/Privacy" target="_blank">Privacy policy</a>
    </footer>
    """
