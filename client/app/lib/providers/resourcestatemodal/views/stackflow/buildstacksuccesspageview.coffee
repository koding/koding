kd = require 'kd'


module.exports = class BuildStackSuccessPageView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    @logsButton = new kd.ButtonView
      title    : 'View Logs'
      cssClass : 'GenericButton secondary'
      callback : =>
        unless Cookies.get 'use-ose'
          kd.singletons.computeController.showBuildLogs @getData().machine, 0
        @emit 'ClosingRequested'

    @installButton = new kd.ButtonView
      title    : 'Install'
      cssClass : 'GenericButton secondary'
      callback : @lazyBound 'emit', 'InstallRequested'

    @inviteButton = new kd.ButtonView
      title    : 'Invite'
      cssClass : 'GenericButton secondary'
      callback : @lazyBound 'emit', 'CollaborationInvite'

    @closeButton = new kd.ButtonView
      title    : 'Start Coding'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'ClosingRequested'


  pistachio: ->

    '''
      <div class="build-stack-success-page">
        <section class="main">
          <div class="background"></div>
          <h2>Success! Your stack has been built.</h2>
          <div>
            <div class="next-action">
              {{> @logsButton}}
              <div class="next-action-title">View The Logs</div>
              <div class="next-action-description">
                See the logs we captured during the build process.
              </div>
            </div>
            <div class="next-action">
              {{> @installButton}}
              <div class="next-action-title">Connect Your Local Machine</div>
              <div class="next-action-description">
                Use KD to use your local IDEs to interact with the file system
                on your new VM.
              </div>
            </div>
            <div class="next-action">
              {{> @inviteButton}}
              <div class="next-action-title">Invite to Collaborate</div>
              <div class="next-action-description">
                Invite your team members to collaborate in the online IDE.
              </div>
            </div>
          </div>
        </section>
        <footer>
          {{> @closeButton}}
        </footer>
      </div>
    '''
