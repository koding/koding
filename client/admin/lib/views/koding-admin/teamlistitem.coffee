kd                        = require 'kd'
JView                     = require 'app/jview'
remote                    = require('app/remote').getInstance()

showError                 = require 'app/util/showError'
applyMarkdown             = require 'app/util/applyMarkdown'
objectToString            = require 'app/util/objectToString'

AdminAppView              = require 'admin/views/customviews/adminappview'
GroupsDangerModalView     = require 'admin/views/permissions/groupsdangermodalview'


module.exports = class TeamListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type   or= 'member'
    options.cssClass = kd.utils.curry 'team-item clearfix', options.cssClass

    super options, data

    { inuse, privacy, config } = @getData()

    @roleLabel = new kd.CustomHTMLView
      cssClass : 'role'
      partial  : "Details <span class='settings-icon'></span>"
      click    : @getDelegate().lazyBound 'toggleDetails', this

    @createDetailsView()


  createDetailsView: ->

    team     = @getData()
    delegate = @getDelegate()

    @details = new kd.CustomHTMLView
      cssClass : 'hidden'

    message = if plan = team.config?.plan
    then "Current plan is #{plan}."
    else 'Currently no plan is set, which means there is no limit for this team.'

    @details.addSubView new kd.View { partial: message }

    @details.addSubView new kd.ButtonView
      title    : 'Change Team Plan'
      cssClass : 'solid compact'
      callback : =>
        kd.singletons.computeController.fetchTeamPlans (plans) =>
          @showPlanModal team, plans

    { appManager } = kd.singletons

    @details.addSubView new kd.ButtonView
      title    : 'Open Team Settings'
      cssClass : 'solid compact'
      callback : ->
        appManager.tell 'Admin', 'fetchNavItems', (NAV_ITEMS) ->
          new AdminAppView
            title        : "Team Settings of #{team.slug}"
            cssClass     : 'AppModal AppModal--admin team-settings'
            width        : 1000
            height       : '90%'
            overlay      : yes
            overlayClick : no
            useRouter    : no
            tabData      : NAV_ITEMS
          , team

    @details.addSubView new kd.ButtonView
      title    : 'Destroy Team'
      cssClass : 'solid compact red'
      callback : ->
        modal = new GroupsDangerModalView
          action     : 'Destroy Team'
          longAction : 'destroy whole team'
          callback   : ->
            team.destroy (err) ->
              return  if showError err

              new kd.NotificationView
                title: 'Team has been destroyed!'

              delegate.emit 'ReloadRequested'
              modal.destroy()
        , team


  toggleDetails: ->

    @details.toggleClass  'hidden'
    @roleLabel.toggleClass 'active'


  showPlanModal: (team, _plans) ->

    getDetails = (plan) ->

      data = if not plan or plan is 'noplan' \
        then { restriction: 'No restriction' }
        else _plans[plan]

      details = objectToString data, { separator: '  ' }

      applyMarkdown "```json \n#{details}\n```"

    plans = [ { title: 'No plan', value: 'noplan' } ]
    for plan of _plans
      plans.push { title: plan, value: plan }

    delegate = @getDelegate()

    overrides = team.config?.planOverrides
    if overrides
      try
        overrides = JSON.stringify overrides
      catch e
        overrides = ''

    modal = new kd.ModalViewWithForms
      title                       : "Set team plan for #{team.slug}"
      overlay                     : yes
      height                      : 'auto'
      tabs                        :
        forms                     :
          setplan                 :
            buttons               :
              Cancel              :
                itemClass         : kd.ButtonView
                style             : 'solid medium'
                loader            :
                  color           : '#444444'
                callback          : -> modal.destroy()
              Save                :
                itemClass         : kd.ButtonView
                style             : 'solid green medium'
                loader            :
                  color           : '#444444'
                callback          : ->

                  { setplan }   = modal.modalTabs.forms
                  planOverrides = setplan.inputs.planOverrides
                  button        = setplan.buttons.Save

                  planOverrides.validate()
                  return button.hideLoader()  unless planOverrides.valid

                  plan      = setplan.inputs.plan.getValue()

                  overrides = planOverrides.getValue()
                  overrides = JSON.parse overrides  if overrides

                  team.setPlan { plan, overrides }, (err) ->

                    button.hideLoader()

                    unless showError err
                      new kd.NotificationView { title: 'Team plan has been changed!' }
                      delegate.emit 'ReloadRequested'
                      modal.destroy()

            fields                :

              plan                :
                name              : 'plan'
                label             : 'Plan'
                type              : 'hidden'
                nextElement       :
                  plan            :
                    itemClass     : kd.SelectBox
                    defaultValue  : team.config?.testplan ? 'noplan'
                    selectOptions : plans
                    callback      : (plan) ->
                      { setplan } = modal.modalTabs.forms
                      { planDetails, planOverrides } = setplan.inputs
                      planDetails.updatePartial getDetails plan
                      if plan is 'noplan'
                        planOverrides.setValue ''
                        planOverrides.validate()
                        planOverrides.makeDisabled()
                      else
                        planOverrides.makeEnabled()
                      modal._windowDidResize()

              planDetails         :
                name              : 'plandetails'
                label             : 'Plan Details'
                type              : 'hidden'
                nextElement       :
                  planDetails     :
                    cssClass      : 'has-markdown'
                    itemClass     : kd.View
                    partial       : getDetails team.config?.testplan

              planOverrides       :
                name              : 'planoverrides'
                label             : 'Overrides'
                type              : 'hidden'
                nextElement       :
                  planOverrides   :
                    itemClass     : kd.InputView
                    type          : 'textarea'
                    disabled      : not team.config?.testplan
                    defaultValue  : overrides
                    validate      :
                      rules       :
                        JSON      : yes
                      events      :
                        JSON      : 'blur'


  pistachio: ->

    """
      {div.details{#(title)}}
      {{> @roleLabel}}
      <div class='clear'></div>
      {{> @details}}
    """
