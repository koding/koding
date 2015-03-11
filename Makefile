HOST?=localhost
PORT?=8090

all: configure
	@./run

configure:
	@./configure --host "$(HOST):$(PORT)"

backend: configure
	@./run backend

.PHONY: configure
