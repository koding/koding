#!/usr/bin/env python

import re
import datetime
import sys
from optparse import OptionParser


parser = OptionParser()
parser.add_option('-d', '--daemon', dest='daemon_name')
parser.add_option('-m', '--mode', dest='mode', default="summary")
options, args = parser.parse_args()

if not options.daemon_name:
	print "-d | --daemon"
	sys.exit(2)

yesterday = datetime.date.fromordinal(datetime.date.today().toordinal()-1)

re_console_colors  = re.compile("\x1B\[[0-9;]*[JKmsu]", re.UNICODE)

errors = {}
stack_traces = {}
is_met_first_line = False

try:
	f = open('/var/log/koding/'+ options.daemon_name + '.log')
except IOError, e:
	print e
	sys.exit(2)

for line in f:
	line = re_console_colors.sub("", line)
	line = line.strip()

	if is_met_first_line is True and line.startswith("["):
		is_met_first_line = False
	
#	if line.startswith("[2013-12-19"):
	if line.startswith("[" + yesterday.strftime("%Y-%m-%d")):
		if "[ERROR]" in line:
			err_part = line.split()
			err = ' '.join(err_part[2:len(err_part)])
			if err not in errors:
				errors[err] = 1
				stack_traces[err] = ""
				is_met_first_line = True
			else:
				errors[err] =  errors[err] + 1
	elif is_met_first_line is True and line.startswith("at"):
		stack_traces[err] = stack_traces[err] + "\n   " + line
	else:
		is_met_first_line = False

if len(errors) < 1:
	print "No log for " + yesterday.strftime("%Y-%m-%d")
	sys.exit(1)

if options.mode == "summary":
	print "--------------------------------------------------------------------------------\n"
	for key, value in errors.iteritems():
		print str(value) + " " + key

elif options.mode == "details":
	print "--------------------------------------------------------------------------------\n"
	for key, value in stack_traces.iteritems():
		print "\n" + key + " " + value
