jspath = require 'jspath'

module.exports = do ->

  events = [
    'CredentialChangesRevertRequested'
    'CredentialChangesSaveRequested'
    'CredentialSelectionChanged'
    'CredentialFilterChanged'
    'SelectedProviderChanged'
    'CredentialListUpdated'
    'StackWizardCancelled'
    'InitializeRequested'
    'TemplateDataChanged'
    'ProviderSelected'
    'LazyLoadFinished'
    'LazyLoadStarted'
    'ToggleSideView'
    'ShowSideView'
    'HideWarning'
    'WarnUser'
    'GotFocus'
    'Action'
    'Log'
    'Menu.Test'
    'Menu.Initialize'
    'Menu.MakeTeamDefault'
    'Menu.Rename'
    'Menu.Clone'
    'Menu.Credentials'
    'Menu.Logs'
    'Menu.Delete'
    'Banner.ActionClicked'
    'Banner.Close'
  ]

  obj = {}
  events.forEach (event) ->
    jspath.setAt obj, event, event

  return obj
