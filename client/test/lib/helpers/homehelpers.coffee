helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
myteamHelpers = require '../helpers/myteamhelpers.js'
myTeamLink = "#{helpers.getUrl(yes)}/Home/my-team"

module.exports =

  
  verifyStackView: (browser, targetUser) ->
   
    url = helpers.getUrl(yes)
    stackLink = ".WelcomeStacksView ul.bullets li:nth-of-type(1)"
    @acceptInvitation browser, targetUser
    myteamHelpers.logoutTeam browser, =>
      browser.url url
      teamsHelpers.loginToTeam browser, targetUser, no
      browser
        .pause 3000
        .waitForElementVisible '.WelcomeStacksView', 20000
        .click stackLink
        .waitForElementVisible '.StackEditor-OnboardingModal',20000
        .end()

  verifyTeamView: (browser, targetUser) ->
   
    url = helpers.getUrl(yes)
    teamLink = ".WelcomeStacksView ul.bullets li:nth-of-type(2)"
    @acceptInvitation browser, targetUser
    myteamHelpers.logoutTeam browser, =>
      browser.url url
      teamsHelpers.loginToTeam browser, targetUser, no
      browser
        .pause 3000
        .waitForElementVisible '.WelcomeStacksView', 20000
        .click teamLink
        .waitForElementVisible '.HomeAppView--section.send-invites',20000
        .end()

  acceptInvitation: (browser, targetUser) ->
    fn = ( email, done ) ->
      _remote.api.JInvitation.some { 'email': email }, {}, (err, invitations) ->
        if invitations.length
          invitation = invitations[0]
          done invitation.code
        else
          done()
    browser
      .timeoutsAsyncScript 10000
      .executeAsync fn, [targetUser.email], (result) =>

        { status, value } = result

        if status is 0 and value
          browser.waitForElementVisible '.HomeAppView', 20000, yes, =>
            myteamHelpers.logoutTeam browser, =>
              teamUrl       = helpers.getUrl yes
              invitationUrl = "#{teamUrl}/Invitation/#{result.value}"
              console.log(invitationUrl)
              browser.url invitationUrl, ->
                teamsHelpers.fillJoinForm browser, targetUser
                  
     
                    
