module.exports =

  'Login': (browser) ->

    browser
      .url                    'http://lvh.me:8090'
      .waitForElementVisible  '[testpath=main-header]', 10000
      .click                  '[testpath=login-link]'
      .waitForElementVisible  '[testpath=login-container]', 10000
      .setValue               '[testpath=login-form-username]', 'didemacet'
      .setValue               '[testpath=login-form-password]', 'didemacet'
      .click                  '[testpath=login-button]'
      .waitForElementVisible  '[testpath=main-sidebar]', 10000
      .end()


  'Login with email': (browser) ->

    browser
      .url                    'http://lvh.me:8090'
      .waitForElementVisible  '[testpath=main-header]', 10000
      .click                  '[testpath=login-link]'
      .waitForElementVisible  '[testpath=login-container]', 10000
      .setValue               '[testpath=login-form-username]', 'didemacet@koding.com'
      .setValue               '[testpath=login-form-password]', 'didemacet'
      .click                  '[testpath=login-button]'
      .waitForElementVisible  '[testpath=main-sidebar]', 10000
      .end()

  'Invalid username': (browser) ->

    browser
      .url                    'http://lvh.me:8090'
      .waitForElementVisible  '[testpath=main-header]', 10000
      .click                  '[testpath=login-link]'
      .waitForElementVisible  '[testpath=login-container]', 10000
      .setValue               '[testpath=login-form-username]', 'invalidusername'
      .setValue               '[testpath=login-form-password]', 'didemacet'
      .click                  '[testpath=login-button]'
      .waitForElementVisible  '[testpath=login-container]', 10000
      .end()

  'Invalid email': (browser) ->

    browser
      .url                    'http://lvh.me:8090'
      .waitForElementVisible  '[testpath=main-header]', 10000
      .click                  '[testpath=login-link]'
      .waitForElementVisible  '[testpath=login-container]', 10000
      .setValue               '[testpath=login-form-username]', 'invalidemail@gmail.com'
      .setValue               '[testpath=login-form-password]', 'didemacet'
      .click                  '[testpath=login-button]'
      .waitForElementVisible  '[testpath=login-container]', 10000
      .end()

  'Invalid password': (browser) ->

    browser
      .url                    'http://lvh.me:8090'
      .waitForElementVisible  '[testpath=main-header]', 10000
      .click                  '[testpath=login-link]'
      .waitForElementVisible  '[testpath=login-container]', 10000
      .setValue               '[testpath=login-form-username]', 'didemacet@koding.com'
      .setValue               '[testpath=login-form-password]', 'invalidpassword'
      .click                  '[testpath=login-button]'
      .waitForElementVisible  '[testpath=login-container]', 10000
      .end()
