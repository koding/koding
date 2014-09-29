

faker    = require('faker')
user     = faker.Helpers.createCard()

# enable tweets some other time vs boring fuckin lorem ipsums.
# twit     = new require('twitter')
#     consumer_key        : '2WX5bYPbkosELsee5m5sRTkww'
#     consumer_secret     : '8oNpgHakB81AU6KnXfzgyVSPrgvTaMGRWYrRoWyFRZvyBgivWV'
#     access_token_key    : '42704386-mdSOlYAbl2psZgueScsRT5nUprgZak0eaLkXRUnBU'
#     access_token_secret : 'owpnsShoaRyOND6DXfPkfN2jrCLHUCmRzopClPaBWcFks'

# tweets = []
# twit.search 'nodejs OR #node',(data) -> tweets = data

# gotTweet = []
# getTweet = ->
#   randomnumber = Math.floor(Math.random()*11)
#   tweet =
#     text : tweets.statuses[randomnumber].text
#     username :

#   gotTweet.push tweet
#   return tweet

# getLastTweet = ->
#   return gotTweet[gotTweet.length-1]




module.exports = client =
  "Registration": (browser) ->

    koding_username = "ktu-#{user.name.replace(/[^A-Za-z0-9]/g, '')}"

    browser
        # .url                    "http://koding:1q2w3e4r@sandbox.koding.com/"
        # .url                    "http://sandbox.koding.com/"
        .url                    "http://lvh.me:8090"
        .waitForElementVisible  "form.login-form", 10000
        .setValue               "input[name='email']"    , "devrim+#{user.username}@koding.com"
        .setValue               "input[name='username']" , koding_username
        .click                  "button[type='button']"

        .waitForElementVisible  "div.kdmodal.password", 10000
        .setValue               "form input[name='password']", "1q2w3e4r"
        .setValue               "form input[name='passwordConfirm']","1q2w3e4r"
        .click                  "button[type='submit']"
        .waitForElementVisible  "body.logged-in", 10000


  "Logged in": (browser) ->
    browser
        # .assert.containsText    "input[name='email']", "nightwatch"
        .waitForElementVisible  "div.welcome-modal", 10000
        .click                  "div.welcome-modal a.custom-link-view:nth-child(6)"
        # .saveScreenshot         "hulo1.png"

  "Change name": (browser) ->
    browser
      .click                    "[testpath='AvatarAreaIconLink']"
      .click                    "[testpath='AccountSettingsLink']"
      .waitForElementVisible    "form input[name='firstName']", 10000
      .clearValue               "form input[name='firstName']"
      .setValue                 "form input[name='firstName']", user.name.split(" ")[0]
      .setValue                 "form input[name='lastName']", [user.name.split(" ")[1],browser.Keys.ENTER]

  "Test Activity": (browser)->

    getPost = ->
      lastPost = faker.Lorem.sentence()

    postActivity = (data) ->
      $("[testpath='ActivityInputView'] div[contenteditable='true']").html(data)

    browser
      .click                  "[testpath='public-feed-link']"
      .waitForElementVisible  "[testpath='ActivityInputView'] div[contenteditable='true']", 10000
      .click                  "[testpath='ActivityTabHandle-/Activity/Public/Recent']"
      .waitForElementVisible  "[testpath='ActivityListItemView']", 60000

      for i in [0..30]
        post = i+ " " + getPost()
        browser.execute                postActivity,[post]
        browser.click                  "[testpath='post-activity-button']"
        browser.assert.containsText    "[testpath='ActivityListItemView'] article",post
        browser.pause                  1000

  "Test IDE": (browser)->

    getTerminalInput = ->
      x =Math.floor(Math.random()*110000)
      y =Math.floor(Math.random()*110000)
      input  = "echo $((#{x}*#{y}))"
      result = (x*y)
      return [input,result]

    browser
      .click                  "a[href='/IDE/koding-vm-0/my-workspace']"
      .waitForElementVisible  "div.kdview.pane.terminal-pane.terminal",200000
      .pause                  2000

    for i in [0..30]
      [input,result]               = getTerminalInput()
      browser.execute              "KD.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.server.input('#{input}');"
      browser.execute              "KD.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.keyDown({type: 'keydown', keyCode: 13, stopPropagation: function() {}, preventDefault: function() {}});"
      browser.pause                2000
      browser.assert.containsText  "div.kdview.kdtabpaneview.terminal.clearfix.active div[contenteditable='true']",result
      browser.pause                1000

    browser.end()
