module.exports = (browser) ->

  paragraph     = @getFakeText()
  workspaceName = paragraph.split(' ')[0]

  browser
    .pause                       5000 # required
    .waitForElementVisible       '.activity-sidebar .workspaces-link', 20000
    .click                       '.activity-sidebar .workspaces-link'
    .waitForElementVisible       '.kdmodal-inner', 20000
    .click                       '.kdmodal-inner button'
    .pause                       3000 # required
    .waitForElementVisible       '.add-workspace-view', 20000
    .setValue                    '.add-workspace-view input.kdinput.text', workspaceName + '\n'
    .waitForElementVisible       '.vm-info', 20000
    .url (data) ->
      url    = data.value
      vmName = url.split('/IDE/')[1].split('/')[0]

      browser
        .waitForElementPresent   'a[href="/IDE/' + vmName + '/' + workspaceName + '"]', 40000 # Assertion
        .pause                   10000
        .assert.urlContains      workspaceName # Assertion
        .waitForElementVisible   '.vm-info', 20000
        .assert.containsText     '.vm-info', '~/Workspaces/' + workspaceName # Assertion

  return workspaceName
