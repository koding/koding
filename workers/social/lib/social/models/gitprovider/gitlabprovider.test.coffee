GitLabProvider = require './gitlabprovider'
{ expect }     = require '../../../../testhelper'

runTests = -> describe 'workers.social.models.gitprovider.gitlabprovider', ->

  describe '#GitLabProvider.parseImportData()', ->

    it 'returns nothing if url host is not gitlab.com', ->

      url = 'http://www.google.com'
      expect(GitLabProvider.parseImportData { url }).not.exist


    it 'returns nothing if gitlab url is not repository url', ->

      url = 'https://gitlab.com/skratchdot/underscore/blob/master/package.json'
      expect(GitLabProvider.parseImportData { url }).not.exist


    it 'returns parse result if url is correct gitlab repository url', ->

      url = 'https://gitlab.com/skratchdot/underscore/tree/master'
      parseResult = GitLabProvider.parseImportData { url }
      expect(parseResult.user).to.be.equal 'skratchdot'
      expect(parseResult.repo).to.be.equal 'underscore'
      expect(parseResult.branch).to.be.equal 'master'

    it 'returns parse result if repo is correct gitlab repository', ->

      repo = 'skratchdot/underscore/master'
      parseResult = GitLabProvider.parseImportData { repo }
      expect(parseResult.user).to.be.equal 'skratchdot'
      expect(parseResult.repo).to.be.equal 'underscore'
      expect(parseResult.branch).to.be.equal 'master'


runTests()
