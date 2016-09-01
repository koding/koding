import { configure, addDecorator } from '@kadira/storybook'
import centered from './centered'

addDecorator(centered)

const req = require.context('../component-lab', true, /\.story\.js$/)

const loadStories = () => req.keys().forEach(req)

configure(loadStories, module)
