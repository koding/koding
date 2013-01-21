srcdir = '.'
blddir = 'build'
VERSION = '1.1.0'

def set_options(opt):
  opt.tool_options('compiler_cxx')

def configure(conf):
  conf.check_tool('compiler_cxx')
  conf.check_tool('node_addon')
  conf.check( header_name='expat.h', 
              mandatory = True,
	          errmsg = "not installed")
	
  conf.env['LIB_EXPAT'] = ['expat']


def build(bld):
  obj = bld.new_task_gen('cxx', 'shlib', 'node_addon')
  obj.target = 'node-expat'
  obj.source = 'node-expat.cc'
  obj.lib = 'expat'
  obj.uselib = 'EXPAT'
