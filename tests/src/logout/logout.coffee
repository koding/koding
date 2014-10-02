module.exports =

  'Logout': (browser) ->

    browser
      .url                    'http://lvh.me:8090'
      .waitForElementVisible  '#main-header', 10000
      .click                  '.custom-link-view.login'
      .waitForElementVisible  '.login-screen.login', 10000
      .setValue               'input[name=username]', 'didemcik'
      .setValue               'input[name=password]', '12345678'
      .click                  '.kdbutton.solid.medium'
      .waitForElementVisible  '.login-form-holder', 10000
      .click                  '.acc-dropdown-icon'
      .click                  'a[href="/Logout"]'
      .waitForElementVisible  '#main-header', 10000
      .end()
