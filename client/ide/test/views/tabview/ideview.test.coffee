expect                = require 'expect'
IDEView               = require 'ide/views/tabview/ideview'
IDEApplicationTabView = require 'ide/views/tabview/ideapplicationtabview'

ideView = null


describe 'IDEView', ->


  beforeEach -> ideView = new IDEView


  afterEach -> expect.restoreSpies()


  describe 'constructor', ->


    it 'should be instantiated', ->

      expect(ideView).toBeA IDEView


    it 'should have default options set and invoke required methods', ->

      expect.spyOn IDEView.prototype, 'setHash'
      expect.spyOn IDEView.prototype, 'bindListeners'

      ideView = new IDEView
      options = ideView.getOptions()

      expect(options.tabViewClass).toBe IDEApplicationTabView
      expect(options.createNewEditor).toBe yes
      expect(options.bind).toBe 'dragover drop'
      expect(options.addSplitHandlers).toBe yes

      expect(ideView.openFiles).toEqual []
      expect(ideView.setHash).toHaveBeenCalled()
      expect(ideView.bindListeners).toHaveBeenCalled()
