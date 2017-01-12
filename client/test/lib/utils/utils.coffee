fs        = require 'fs'
faker     = require 'faker'
tempDir   = require 'os-tmpdir'
formatter = require 'json-format'
_ = require 'lodash'

async = require 'async'

module.exports =

  generateUsers: ->

    users = []

    for [1..10]

      name     = faker.name.findName()
      username = faker.helpers.slugify(faker.internet.userName()).toLowerCase().replace(/\./g, '').replace(/_/g, '')
      username = username.substring(0, 7) + Date.now()
      password = @getPassword()
      teamSlug = name.toLowerCase().replace(/\s/g, '-').replace(/'/g, '').replace('.', '')
      helpers  = require '../helpers/helpers'
      fakeText = helpers.getFakeText()

      email = "kodingtestuser+#{username}@koding.com"

      users.push { name, email, username, password, teamSlug, fakeText }

    fs.writeFileSync 'users.json', formatter(users)

    return users


  getPassword: ->

    password = faker.helpers.slugify(faker.internet.userName())

    while password.length < 12
      password = faker.helpers.slugify(faker.internet.userName())

    return password


  getUser: (createNewUserData, index = 0) ->

    if createNewUserData
      users = @generateUsers()
      return if index is -1 then users else users[index]

    try
      usersFile = fs.readFileSync('users.json')
      users = JSON.parse(usersFile)

      return if index is -1 then users else users[index]

    catch

      users = @generateUsers()
      return if index is -1 then users else users[index]


  getHookFilePath: (type) ->

    hookDir = process.env.TEST_SUITE_HOOK_DIR
    { TEST_GROUP, TEST_SUITE } = process.env

    return "#{hookDir}/#{TEST_GROUP}_#{TEST_SUITE}_#{type}"


  registerSuiteHook: (type) -> fs.writeFileSync @getHookFilePath(type), ''


  suiteHookHasRun: (type) ->
    try
      fs.statSync @getHookFilePath type
      return yes
    catch
      return no



  getCollabLinkFilePath: -> return "#{tempDir()}/collabLink.txt"

  getMemberInvitationPath: -> return "#{tempDir()}/invitation.txt"


  beforeCollaborationSuite: ->

    @getUser()  if process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    @registerSuiteHook 'before'  unless @suiteHookHasRun 'before'


  afterEachCollaborationTest: (browser, done) ->
    queue = [
      (next) ->
        browser.deleteCollabLink (result) ->
          next null, result
      (next) ->
        browser.deleteMemberInvitation (res) ->
          next null, res
    ]

    async.series queue, (err, result) ->
      done()  unless err

  getInvitationData: ->

    targetUsers = [0..6].map (index) =>
      @getUser no, index + 1

    index = 0
    invitations = targetUsers.map (user) ->
      if user
        firstName = if (index is 0 or index is 2) then '' else user.fakeText.split(' ')[0]
        lastName = if (index is 1 or index is 2) then '' else user.fakeText.split(' ')[2]
        index = index + 1
        password = user.password
        username = user.username
        { 'email': user.email, 'role': 'member', firstName, lastName, password, username }

    host = @getUser()
    invitations.push host

    invitations = _.sortBy(_.sortBy(_.sortBy(invitations, 'firstName'), 'lastName'), 'email')

    index = invitations.indexOf host
    return { invitations, index }
