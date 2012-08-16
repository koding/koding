#!/usr/bin/env python

def set_options(ctx):
	ctx.tool_options('compiler_cxx')

def configure(ctx):
	ctx.check_tool('compiler_cxx')
	ctx.check_tool('node_addon')

def build(ctx):
	t = ctx.new_task_gen('cxx', 'shlib', 'node_addon')
	t.target = 'buffertools'
	t.source = 'buffertools.cc'
