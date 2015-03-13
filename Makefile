HOST?=localhost
PORT?=8090

all: configure run

configure:
	@./configure --host "$(HOST):$(PORT)"

run:
	@./run

backend: configure
	@./run backend

.PHONY: configure run
