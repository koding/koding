kd      = require 'kd'
mock    = require '../../../mocks/mockingjay'
expect  = require 'expect'

KDModalView     = kd.ModalView
mockCredential  = mock.getMockCredential()
KodingListView  = require 'app/kodinglist/kodinglistview'

AccountCredentialList       = require 'account/accountcredentiallist'
AccountCredentialListItem   = require 'account/accountcredentiallistitem'
AccountCredentialEditModal  = require 'account/accountcredentialeditmodal'


describe 'AccountCredentialList', ->

  describe 'constructor', ->

    it 'should instantiate with default options', ->

      listView = new AccountCredentialList

      { itemClass } = listView.getOptions()

      expect(listView.hasClass 'credential-list').toBeTruthy()
      expect(itemClass).toBe AccountCredentialListItem

    it 'listen ItemDeleted event and call removeItem method', ->

      expect.spyOn AccountCredentialList.prototype, 'removeItem'
      listView = new AccountCredentialList

      listView.emit 'ItemDeleted'

      expect(listView.removeItem).toHaveBeenCalled()


  describe '::showCredential', ->

    it 'should show modal with given parameters', ->

      listView    = new AccountCredentialList
      modal       = listView.showCredential
        cred        : 'cred'
        credential  : mockCredential

      modal.hide()

      { title, subtitle, overlay } = modal.getOptions()

      expect(title).toEqual mockCredential.title
      expect(subtitle).toEqual mockCredential.provider
      expect(overlay).toBeTruthy()
      expect(modal.hasClass('credential-modal')).toBeTruthy()


  describe '::showCredentialEditModal', ->

    it 'should show modal with given parameters', ->

      listView      = new AccountCredentialList
      modal         = listView.showCredentialEditModal
        provider    : mockCredential.provider
        credential  : mockCredential
        data        : { }

      modal.hide()

      { provider, credential } = modal.getOptions()

      expect(modal).toBeA AccountCredentialEditModal
      expect(credential).toEqual mockCredential
