module.exports =

  'Register': (browser) ->

    browser
      .url                    'http://lvh.me:8090'
      .waitForElementVisible  '#main-header', 10000
      .setValue               'input[name=email]', 'didemacet+2@gmail.com'
      .setValue               'input[name=username]', 'didemcik'
      .click                  '.kdbutton.solid.medium'
      .setValue               'input[name=password]', '12345678'
      .setValue               'input[name=passwordConfirm]', '12345678'
      .waitForElementVisible  '.login-form-holder', 10000
      .click                  '.close-icon'
      .click                  '.acc-dropdown-icon'
      .click                  'a[href="/Logout"]'
      .waitForElementVisible  '#main-header', 10000
      .click                  '.custom-link-view.login'
      .waitForElementVisible  '.login-screen.login', 10000
      .setValue               'input[name=username]', 'didemcik'
      .setValue               'input[name=password]', '12345678'
      .click                  '.kdbutton.solid.medium.yellow'
      .waitForElementVisible  '.login-form-holder', 10000
      .end()
