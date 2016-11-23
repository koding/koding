BIN=./node_modules/.bin/

all: clean ace terminal workspace editor
	@node find-collisions.js > out/collisions.md
	@node get-all.js > out/all.json
	@gzip -c -6 out/all.json > out/all.json.gz

editor:
	@node editor-to-json.js > out/editor-bindings.json
	@cat out/editor-bindings.json|python to-csv.py > out/editor-bindings.csv

workspace:
	@$(BIN)coffee workspace-to-json.coffee > out/workspace-bindings.json
	@cat out/workspace-bindings.json|python to-csv.py > out/workspace-bindings.csv

terminal:
	@$(BIN)coffee terminal-to-json.coffee > out/terminal-bindings.json
	@cat out/terminal-bindings.json|python to-csv.py > out/terminal-bindings.csv

ace:
	@node ace-to-json.js > out/ace-bindings.json
	@cat out/ace-bindings.json|python to-csv.py > out/ace-bindings.csv

clean:
	@rm -f out/*
	@mkdir -p out
