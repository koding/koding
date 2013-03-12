class GroupsVocabulariesListItemView extends KDListItemView

  viewAppended: JView::viewAppended

  pistachio:->
    """
    A vocabulary ({{#(group)}})
    """


class GroupsCreateVocabularyView extends JView
  constructor:(options, data)->
    super

    @createButton = new KDButtonView
      title     : 'Create vocabulary'
      cssClass  : 'clean-gray'
      callback  :=> @emit 'VocabularyCreateRequested'

  pistachio:->
    """
    <section>
      <h2>Create a vocabulary</h2>
      <div class="formline">This group does not have a related vocabulary.<div>
      {div.formline{> @createButton}}
    </section>
    """


class GroupsVocabulariesView extends JView

  constructor:(options, data)->
    super

    @createVocabularyView = new GroupsCreateVocabularyView
    @createVocabularyView.hide()
    @createVocabularyView.on 'VocabularyCreateRequested', =>
      @emit 'VocabularyCreateRequested'

    @vocabularyController = new KDListViewController
      itemClass : GroupsVocabulariesListItemView
    @vocabularyView = @vocabularyController.getListView()

  setVocabulary:(vocab)->
    unless vocab?
      @createVocabularyView.show()
    else
      @createVocabularyView.hide()
      @vocabularyController.removeAllItems()
      @vocabularyController.instantiateListItems [vocab]

  pistachio:->
    """
    Vocabularies admin view will go here.
    {{> @createVocabularyView}}
    {{> @vocabularyView}}
    """