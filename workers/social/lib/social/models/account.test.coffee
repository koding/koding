beforeTests = -> before (done) ->

    bongo = new Bongo
      root   : __dirname
      mongo  : mongo
      models : ''

    bongo.once 'dbClientReady', ->
      done()


# here we have actual tests
runTests = -> describe 'workers.social.user.account', ->

  describe '#modify()', ->

    it 'should pass error if fields contain invalid key', (done) ->

      client       = null
      account      = null
      fields       = { someInvalidField : 'someInvalidField' }
      userFormData = generateDummyUserFormData()

      queue = [

        ->
          # generating dummy client
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            client  = client_
            account = client.connection.delegate
            queue.next()

        ->
          # registering user
          JUser.convert client, userFormData, (err, data) ->
            expect(err).to.not.exist
            # set credentials
            { account, newToken }      = data
            client.sessionToken        = newToken
            client.connection.delegate = account
            queue.next()

        ->
          # expecting error when using unallowed field
          account.modify client, fields, (err) ->
            expect(err?.message).to.be.equal 'Modify fields is not valid'
            queue.next()

        -> done()

      ]

      daisy queue


    it 'should update given fields correctly', (done) ->

      fields =
        'profile.about'     : 'newAbout'
        'profile.lastName'  : 'newLastName'
        'profile.firstName' : 'newFirstName'

      client        = null
      account       = null
      userFormData  = generateDummyUserFormData()
      socialAccount = null

      queue = [

        ->
          # generating dummy client
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            client  = client_
            account = client.connection.delegate
            queue.next()

        ->
          # registering user
          JUser.convert client, userFormData, (err, data) ->
            expect(err).to.not.exist
            # set credentials
            { account, newToken }      = data
            client.sessionToken        = newToken
            client.connection.delegate = account
            queue.next()

        ->
          # expecting account to be modified
          account.modify client, fields, (err, data) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting account's values to be changed
          for key, value of fields
            expect(account.getAt key).to.be.equal value
          queue.next()

        -> done()

      ]

      daisy queue


beforeTests()

runTests()


