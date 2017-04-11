kd = require 'kd'
{ Component, PropTypes } = React = require 'app/react'
classnames = require 'classnames'

minimumNumberFn = -> 1
minimumRenderFn = -> null
noop = ->

###
# List component provides a structured way to compose list views.
#
# example:
#
# class MessagesList extends React.Component
#
#
#   numberOfSections: ->
#
#     return @props.data.sections.size
#
#
#   numberOfRowsInSection: (sectionIndex) ->
#
#     return @props.data.sections[sectionIndex].size
#
#
#   renderSectionHeaderAtIndex: (sectionIndex) ->
#
#     <header>{@props.data.sections[sectionIndex].title}</header>
#
#
#   renderRowAtIndex: (sectionIndex, rowIndex) ->
#
#     <p>{@props.data.sections[sectionIndex].messages[rowIndex].body</p>
#
#
#   renderEmptySectionAtIndex: (sectionIndex) ->
#
#     <div>No data found</div>
#
#
#   render: ->
#     <List
#       numberOfSections={@bound 'numberOfSections'}
#       numberOfRowsInSection={@bound 'numberOfRowsInSection'}
#       renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
#       renderRowAtIndex={@bound 'renderRowAtIndex'}
#       renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
#     />
###
module.exports = class List extends React.Component

  @propTypes =
    numberOfSections           : PropTypes.func
    numberOfRowsInSection      : PropTypes.func
    renderSectionHeaderAtIndex : PropTypes.func
    renderRowAtIndex           : PropTypes.func.isRequired
    onScroll                   : PropTypes.func
    renderEmptySectionAtIndex  : PropTypes.func


  @defaultProps =
    numberOfSections           : minimumNumberFn
    numberOfRowsInSection      : minimumNumberFn
    renderSectionHeaderAtIndex : minimumRenderFn
    renderRowAtIndex           : minimumRenderFn
    onScroll                   : noop
    renderEmptySectionAtIndex  : minimumRenderFn


  numberOfSections: ->

    return @props.numberOfSections()


  numberOfRowsInSection: (sectionIndex) ->

    return @props.numberOfRowsInSection sectionIndex


  renderSectionHeaderAtIndex: (sectionIndex) ->

    return @props.renderSectionHeaderAtIndex sectionIndex


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    return @props.renderRowAtIndex sectionIndex, rowIndex


  renderEmptySectionAtIndex: (sectionIndex) ->

    return @props.renderEmptySectionAtIndex? sectionIndex  unless @numberOfRowsInSection sectionIndex


  renderChildren: ->

    # this is intentionally left here for further improvements. ~Umut
    # I don't remember what my **intentions** were.
    dataSource = this

    sectionCount = dataSource.numberOfSections()

    if not sectionCount and @props.renderEmpty
      return @props.renderEmpty()

    { sectionClassName, rowClassName } = @props

    [0...sectionCount].map (sectionIndex) ->
      <Section key="s#{sectionIndex}" className={sectionClassName}>

        <Header source={dataSource} index={sectionIndex} />

        {[0...dataSource.numberOfRowsInSection sectionIndex].map (rowIndex) ->
          <Row
            key="s#{sectionIndex}-r#{rowIndex}"
            source={dataSource}
            className={rowClassName}
            sectionIndex={sectionIndex}
            rowIndex={rowIndex} />}
        {dataSource.renderEmptySectionAtIndex sectionIndex}
      </Section>


  render: ->

    <div className={kd.utils.curry 'ListView', @props.className} onScroll={@props.onScroll}>
      {@renderChildren()}
    </div>


Section = ({ className, children }) ->
  <div className={classnames 'ListView-section', className}>
    {children}
  </div>


Row = ({ source, className, sectionIndex, rowIndex }) ->
  <div className={classnames 'ListView-row', className}>
    {source.renderRowAtIndex sectionIndex, rowIndex}
  </div>


Header = ({ source, index }) ->

  unless headerAtIndex = source.renderSectionHeaderAtIndex index
    return null

  <div className={classnames 'ListView-SectionHeader'}>
    {headerAtIndex}
  </div>
