MAKEFLAGS += -j

all: api topicfeed realtime followingfeed

api:
	../../../go/bin/rerun  socialapi/workers/api -c ./config/vagrant.toml -d
topicfeed:
	../../../go/bin/rerun socialapi/workers/topicfeed -c ./config/vagrant.toml -d
realtime:
	../../../go/bin/rerun socialapi/workers/realtime -c ./config/vagrant.toml  -d
followingfeed:
	../../../go/bin/rerun socialapi/workers/followingfeed -c ./config/vagrant.toml -d

.PHONY: all
