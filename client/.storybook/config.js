import { configure, addDecorator } from '@kadira/storybook'
import centered from './centered'

require('app/styl')

addDecorator(centered)


const req = require.context('../component-lab', true, /\.story\.(js|coffee)$/)

const loadStories = () => req.keys().forEach(req)

configure(loadStories, module)
