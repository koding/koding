faker    = require('faker')

dogapi = require 'dogapi'

options =
  api_key: 'da163c47df4e1bdec0645604a129846c'
  app_key: 'eb916d4dd0b7101b8e5b00a73b405cae5d804b8e'

doglog = new dogapi options

module.exports = client = do ()->

  user = faker.Helpers.createCard()

  getTerminalInput = ->
    x =Math.floor(Math.random()*110000)
    y =Math.floor(Math.random()*110000)
    input  = "echo $((#{x}*#{y}))"
    result = (x*y)
    return [input,result]

  getPost = ->
    lastPost = faker.Lorem.sentence()

  postActivity = (data) ->
    $("[testpath='ActivityInputView'] div[contenteditable='true']").html(data)


  tests =
    beforeEach: (browser, done)->
      browser.globals.time = new Date()
      done()

    afterEach: (done)->
      browser = this.client;

      duration = (new Date()) - browser.globals.time

      metric =
        metric : browser.currentTest.name
        points : [[Date.now(), duration]]
        host   : "load.koding.com"
        type   : "counter"

      doglog.add_metrics series:[metric], ()->
        done()


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
        .waitForElementVisible  "div.welcome-modal", 10000
        .click                  "div.welcome-modal a.custom-link-view:nth-child(6)"

    "Change name": (browser) ->
      browser
        .click                    "[testpath='AvatarAreaIconLink']"
        .click                    "[testpath='AccountSettingsLink']"
        .waitForElementVisible    "form input[name='firstName']", 10000
        .clearValue               "form input[name='firstName']"
        .setValue                 "form input[name='firstName']", user.name.split(" ")[0]
        .setValue                 "form input[name='lastName']", [user.name.split(" ")[1],browser.Keys.ENTER]

  for i in [1..20]
    tests["Test Activity #{i}"] = do (i)-> (browser)->
      # open activity only first time
      if i is 1
        browser
          .click                  "[testpath='public-feed-link']"
          .waitForElementVisible  "[testpath='ActivityInputView'] div[contenteditable='true']", 10000
          .click                  "[testpath='ActivityTabHandle-/Activity/Public/Recent']"
          .waitForElementVisible  "[testpath='ActivityListItemView']", 60000

      post = i+ " " + getPost()
      browser.execute                postActivity,[post]
      browser.click                  "[testpath='post-activity-button']"
      browser.assert.containsText    "[testpath='ActivityListItemView'] article",post
      browser.pause                  1000

  for i in [1..20]
    tests["Test IDE #{i}"] = do (i)-> (browser)->
      # select VM only first time, no need to select it again
      if i is 1
        browser
          .click                  "a[href='/IDE/koding-vm-0/my-workspace']"
          .waitForElementVisible  "div.kdview.pane.terminal-pane.terminal",200000
          .pause                  2000

      [input,result]               = getTerminalInput()
      browser.execute              "KD.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.server.input('#{input}');"
      browser.execute              "KD.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.keyDown({type: 'keydown', keyCode: 13, stopPropagation: function() {}, preventDefault: function() {}});"
      browser.pause                2000
      browser.assert.containsText  "div.kdview.kdtabpaneview.terminal.clearfix.active div[contenteditable='true']",result
      browser.pause                1000


      # specialcase, close test suite when we reach to end
      browser.end() if i is 20

  return tests
