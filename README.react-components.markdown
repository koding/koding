## React Components

This folder contains react components.

We split components as **container** components(smart) and **view** components(dumb/presentational).

### **Container** components

 - Are concerned with how things work.
 - It contains `view` component inside for presentation.
 - Provide the data and behavior to view or other container components.
 - Call Flux actions and provide these as callbacks to view components.
 - It may have states and change own states
 - It may have ComponentDidMount, ComponentDidUpdate etc.. react lifecycle event handlers.

### **View** components

 - Are concerned with how things look.
 - May contain both view and container components inside, and usually have some DOM markup of their own.
 - Have no dependencies on the rest of the app, such as Flux actions or stores.
 - Don’t specify how the data is loaded or mutated.
 - Receive data and callbacks exclusively via props.
 - Have no states
 - Have no `ComponentDidMount, ComponentDidUpdate etc..` react lifecycle event handlers. We use this handlers and other methods to call Flux actions in `Container` components
 - Have only `render` methods.

### Benefits of this approach

 - Better separation of concerns. You understand your app and your UI better by writing components this way.
 - Better reusability. You can use the same view component with completely different state sources, and turn those into separate container components that can be further reused.
 - This forces us to extract `layout components` such as `Sidebar, Page, ContextMenu` and use `@props.children` instead of duplicating the same markup and layout in several container components.

### Folder structure

We create component folder structure as you can see below;

```
├── Readme.md
├── bant.json
└── lib
    └── components
       └── Readme.md
       └── commentList
            ├── index.coffee
            ├── view.coffee
            ├── container.coffee
            └── test
              ├── index.coffee
              ├── view.coffee
              └── container.coffee
```

### Creating Components


`index.coffee` should include `view` and `container` files.

```coffeescript
## /commentlist/index.coffee

module.exports           = require './view'
module.exports.Container = require './container'
```

---

`view.coffee` should contain only presentational part.

```coffeescript

## /commentlist/view.coffee

kd             = require 'kd'
React          = require 'kd-react'
immutable      = require 'immutable'

module.exports = class CommentListView extends React.Component

@propTypes =
  repliesCount    : React.PropTypes.number
  showMoreComment : React.PropTypes.func.isRequired
  comments        : React.PropTypes.instanceOf immutable.Map

@defaultProps =
  repliesCount    : 0
  comments        : immutable.Map()


renderShowMoreComments: -> ...


renderList: -> ...


render: ->
  <div className='CommentList'>
    {@renderShowMoreComments()}
    {@renderList()}
  </div>
```

---

`container.coffee` should call flux actions, provide data and behavior to view part. It may contain states, event handlers like `componentDidMount, componentDidUpdate etc...` and various methods to call Flux actions or to do arbitrary things.

```coffeescript

## /commentlist/container.coffee

kd              = require 'kd'
View            = require './view'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'

module.exports = class CommentListContainer extends React.Component

  constructor: (props) ->

    super props

    @state = { showModal: no, isEditingMode: no }


  @propTypes =
    repliesCount    : React.PropTypes.number
    channelId       : React.PropTypes.string
    messageId       : React.PropTypes.string
    comments        : React.PropTypes.instanceOf immutable.Map

  @defaultProps =
    repliesCount   : 0
    channelId      : ''
    messageId      : ''
    comments       : immutable.Map()


  componentDidMount: -> do something...


  componentDidUnmount: -> do another...


  showMoreComment: -> ActivityFlux.actions.message.loadComments()


  doSomething: -> ...


  render: ->

    <View
      ref             = 'view'
      comments        = { @props.comments }
      channelId       = { @props.channelId }
      messageId       = { @props.messageId }
      showModal       = { @state.showModal }
      repliesCount    = { @props.repliesCount }
      isEditingMode   = { @state.isEditingMode }
      showMoreComment = { @bound 'showMoreComment' }/>

```

##### Using Component in another component

```coffeescript

## /components/AnyComponentView.coffee

CommentList = require 'activity/components/commentlist'

render: ->

    <div className='CommentListWrapper'>
      <CommentList.Container
        ref            = 'CommentList'
        comments       = { @props.comments }
        channelId      = { @props.channelId }
        onMentionClick = { @props.onMentionClick }
        messageId      = { @props.messageId }
        repliesCount   = { @props.repliesCount }/>
    </div>

```




### Writing Tests

`index.coffee` should include `view` and `container` test files.

```coffeescript

## /test/index.coffee

describe 'CommentList', ->
  require './view'
  require './container'

```

---

`view.coffee` should contain view component tests.

```coffeescript

## /test/view.coffee

describe 'CommentListView', ->

  { Simulate
    renderIntoDocument
    findRenderedDOMComponentWithClass
    scryRenderedDOMComponentsWithClass } = TestUtils


  beforeEach -> do something...


  afterEach -> do something...


  describe '::render', ->

    it 'should render View with correct classNames', ->

      view = renderIntoDocument(<View {...@props} />)

      expect(findRenderedDOMComponentWithClass view, 'CommentList').toExist()
      expect((scryRenderedDOMComponentsWithClass view, 'CommentListItem').length).toEqual 10
      expect(findRenderedDOMComponentWithClass view, 'CommentList-showMoreComment').toExist()


  describe '::onClick', ->

    it 'should call passed showMoreComment handler when click the showMoreComment link', ->

      showMoreSpy = expect.createSpy()
      view        = renderIntoDocument(<View {...@props} showMoreComment={showMoreSpy}/>)
      node        = ReactDOM.findDOMNode view
      showMoreEl  = node.querySelector '.CommentList-showMoreComment'

      Simulate.click showMoreEl

      expect(showMoreSpy).toHaveBeenCalled()

```

---


`container.coffee` should contain container component tests.

```coffeescript

## /test/container.coffee

describe 'CommentListContainer', ->

  { renderIntoDocument } = TestUtils

  beforeEach -> do something...


  afterEach -> do something...


  describe '::showMoreComment', ->

    it 'should call loadComments action with correct parameters', ->

      { message }     = ActivityFlux.actions
      loadCommentsSpy = expect.spyOn message, 'loadComments'
      container       = renderIntoDocument(<Container {...@props} />)

      container.showMoreComment()

      expect(loadCommentsSpy).toHaveBeenCalledWith ...


```



