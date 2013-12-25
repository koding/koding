#!/usr/bin/env python

import re
import datetime
import sys
from optparse import OptionParser
from operator import itemgetter

def parse_log_file(daemon_name, for_date):
	re_console_colors  = re.compile("\x1B\[[0-9;]*[JKmsu]", re.UNICODE)
	errors = {}
	stack_traces = {}
	is_met_first_line = False

	filename = '/var/log/koding/'+ daemon_name + '.log'

	try:
		f = open(filename)
	except Exception, e:
		return {'nodaemon':1}

	for line in f:
		line = re_console_colors.sub("", line)
		line = line.strip()

		if is_met_first_line is True and line.startswith("["):
			is_met_first_line = False

#		if line.startswith("[2013-12-19"):
		if line.startswith("[" + for_date.strftime("%Y-%m-%d")):
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
	return errors, stack_traces

if __name__ == '__main__':

	parser = OptionParser()
	parser.add_option('-d', '--daemon', dest='daemon_name')
	parser.add_option('-t', '--daysago', dest='daysago', default=1)
	parser.add_option('-m', '--mode', dest='mode', default="summary")
	options, args = parser.parse_args()

	if not options.daemon_name:
		print "-d | --daemon"
		sys.exit(2)

	yesterday = datetime.date.fromordinal(datetime.date.today().toordinal()-int(options.daysago))
	errors, stack_traces = parse_log_file(options.daemon_name, for_date=yesterday)

	if len(errors) < 1:
		print "No log for " + yesterday.strftime("%Y-%m-%d")
		sys.exit(1)
	if 'nodaemon' in errors.keys():
		print options.daemon_name, " not exist for this instance"
		sys.exit(1)

	errors = sorted(errors.iteritems(), key=lambda x: int(x[1]), reverse=True)

	if options.mode == "summary":
		print "-" * 100, "\n"
		for key, value in errors:
			print str(value) + " " + key

	elif options.mode == "details":
		print "-" * 100, "\n"
		for key, value in stack_traces.iteritems():
			print "\n" + key + " " + value
