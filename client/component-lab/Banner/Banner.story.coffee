React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'
Button = require 'lab/Button'
Box = require 'lab/Box'
{ Header, Message, Footer, Container, List, Divider, Actions, PriceSegment } = Banner = require 'lab/Banner'
styles = require './StoryStyles.stylus'

storiesOf 'Banner', module


  .add 'default', ->

    <Banner
      type='success'
      image='banner_for_billing'>
      <Container>
        <Header
          heading='Boost Your Koding with'
          target='Business Add-On and Support Plans'/>
        <Message>
          Fusce dapibus, tellus ac cursus commodo, tortor mauriscondimentum nibh, ut fermentum massa
        </Message>
        <Footer>
          <a href=''><Button type='primary-1' size='medium'>EXPLORE</Button></a>
        </Footer>
      </Container>
    </Banner>


  .add 'Business Add-On', ->

    <Banner
      type='primary'
      image='banner_business_add_on'
      className={styles.BusinessAddOnBanner}>
      <Container>
        <Header
          heading='Empower Your Koding with'
          target='Business Add-On'/>
        <Message>
          Fusce dapibus, tellus ac cursus commodo, tortor mauriscondimentum nibh, ut fermentum massa justo sit amet risus.
        </Message>
        <Divider />
        <List
          title='Features'
          items={[
            'Try on Koding functionality'
            'Direct communication with leads through <br/> Intercom and Chatlio Integration'
            'Analytics (Coming soon)'
          ]} />
        <Footer>
          <a href='/Home/add-ons'>See what you will get with Business Add-On below</a>
        </Footer>
      </Container>
      <Actions>
        <PriceSegment price='5,000' onClick={action 'button clicked'} link='#'/>
      </Actions>
    </Banner>
