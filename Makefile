################################################################################
# CONFIGURATION

# COFFEE & NODE ################################################################
COFFEE_EXE ?= ./node_modules/.bin/coffee
NODE_EXE ?= node
COFFEE_COMPILE ?= $(COFFEE_EXE) -c
COFFEE_COMPILE_ARGS ?=
COFFEE_SRCS ?= $(wildcard lib/gleaning/*.coffee lib/*.coffee *.coffee)
COFFEE_TEST_SRCS ?= $(wildcard test/*.coffee test/gleaning/*.coffee)
COFFEE_JS ?= ${COFFEE_SRCS:.coffee=.js}
COFFEE_TEST_JS ?= ${COFFEE_TEST_SRCS:.coffee=.js}

# NPM ##########################################################################
NPM_EXE ?= npm
PACKAGE_JSON ?= package.json
NODE_MODULES ?= node_modules
MODULE_DIR ?= module
NPM_ARGS ?= --silent

# PACKAGING ####################################################################
PACKAGE_VERSION ?= $(shell $(NODE_EXE) -e "console.log(require('./$(PACKAGE_JSON)').version)")
PACKAGE_NAME ?= $(shell $(NODE_EXE) -e "console.log(require('./$(PACKAGE_JSON)').name)")
TMP_PACKAGE_DIR ?= packaging-$(PACKAGE_NAME)-$(PACKAGE_VERSION)-tmp
PACKAGE_DIR ?= $(PACKAGE_NAME)-$(PACKAGE_VERSION)

# MOCHA ########################################################################
MOCHA_EXE ?= ./node_modules/.bin/mocha
MOCHA_TESTS ?= $(wildcard test/test-*.coffee test/gleaning/test-*.coffee)
MOCHA_TEST_PATTERN ?=
MOCHA_TIMEOUT ?=-t 3000
MOCHA_TEST_ARGS  ?= -R list --compilers coffee:coffee-script $(MOCHA_TIMEOUT) $(MOCHA_TEST_PATTERN)
MOCHA_EXTRA_ARGS ?=

# JSCOVERAGE ###################################################################
JSCOVERAGE_EXE ?= node-jscoverage
JSCOVERAGE_REPORT ?= docs/coverage.html
JSCOVERAGE_TMP_DIR ?=  ./jscov-tmp
LIB_COV ?= lib-cov
LIB ?= lib
MOCHA_COV_ARGS  ?= -R html-cov --compilers coffee:coffee-script -t 6000 --globals "_\$$jscoverage"

# MARKDOWN #####################################################################
MARKDOWN_SRCS ?= $(shell find . -type f -name '*.md' | grep -v node_modules)
MARKDOWN_HTML ?= ${MARKDOWN_SRCS:.md=.html}
MARKDOWN_PROCESSOR ?= pandoc
# MARKDOWN_STYLESHEET ?= ../docs/styles/markdown.css
# MARKDOWN_PROCESSOR_ARGS ?= -f markdown -t html -s -H $(MARKDOWN_STYLESHEET) --toc --highlight-style pygments
MARKDOWN_PROCESSOR_ARGS ?= -f markdown -t html -s --toc --highlight-style pygments
LITCOFFEE_SRCS ?= $(shell find . -type f -name '*.litcoffee' | grep -v node_modules)
LITCOFFEE_HTML ?= ${LITCOFFEE_SRCS:.litcoffee=.html}

# OTHER ########################################################################
RM_DASH_I ?= -f

################################################################################
# META-TARGETS AND SIMILAR

# `.SUFFIXES` - reset suffixes in case any were previously defined
.SUFFIXES:

# `.PHONY` - make targets that aren't actually files
.PHONY: all build-coffee clean clean-coverage clean-docco clean-docs clean-js clean-markdown clean-module clean-node-modules clean-test-module-install coverage docco docs fully-clean-node-modules help js markdown module targets test test-module-install todo pack

# `all` - the default target
all: coverage docco

# `help` - list targets.
help:
	make -rpn | sed -n -e '/^$$/ { n ; /^[^ ]*:/p }' | egrep -v '^\.' | egrep --color '^[^ ]*:'

# `targets` - list targets that are not likely to be .PHONY targets
targets:
	grep -E "^[^ #.$$]+:( |$$)" Makefile | sort

# `todo` - list todo comments in found files
todo:
	grep -C 0 --exclude-dir=node_modules --exclude-dir=.git --exclude=#*# --exclude=.#* -IrH "TODO" *

################################################################################
# CLEAN UP TARGETS

clean: clean-coverage clean-docco clean-docs clean-js clean-module clean-test-module-install clean-node-modules

clean-test-module-install:
	rm -r $(RM_DASH_I) ../testing-module-install

clean-module:
	rm -r $(RM_DASH_I) $(MODULE_DIR)

clean-node-modules:
	$(NPM_EXE) $(NPM_ARGS) prune &

really-clean: clean really-clean-node-modules

really-clean-node-modules: # deletes rather that simply pruning node_modules
	rm -r $(RM_DASH_I) $(NODE_MODULES)

clean-js:
	rm $(RM_DASH_I) $(COFFEE_JS) $(COFFEE_TEST_JS)

clean-coverage:
	rm -r $(RM_DASH_I) $(JSCOVERAGE_TMP_DIR)
	rm -r $(RM_DASH_I) $(LIB_COV)
	rm $(RM_DASH_I) $(JSCOVERAGE_REPORT)
	(rmdir --ignore-fail-on-non-empty docs) || true

clean-docs: clean-markdown clean-docco

clean-docco:
	rm -r $(RM_DASH_I) docs/docco
	(rmdir --ignore-fail-on-non-empty docs) || true

clean-markdown:
	rm $(RM_DASH_I) $(MARKDOWN_HTML)
	(rmdir --ignore-fail-on-non-empty docs) || true

################################################################################
# NPM TARGETS

module: js test docs coverage
	mkdir -p $(MODULE_DIR)
	cp -r lib $(MODULE_DIR)
	cp -r test $(MODULE_DIR)
	cp -r docs $(MODULE_DIR)
	cp $(PACKAGE_JSON) $(MODULE_DIR)
	cp README.* $(MODULE_DIR)
	cp Makefile $(MODULE_DIR)

test-module-install: clean-test-module-install js test docs coverage module
	mkdir ../testing-module-install; cd ../testing-module-install; npm install "$(CURDIR)/module"; node -e "require('assert').ok(1==2)" && cd $(CURDIR) && rm -r $(RM_DASH_I) ../testing-module-install

$(NODE_MODULES): $(PACKAGE_JSON)
	$(NPM_EXE) $(NPM_ARGS) prune
	$(NPM_EXE) $(NPM_ARGS) install
	touch $(NODE_MODULES) # touch the module dir so it looks younger than `package.json`

npm: $(NODE_MODULES) # an alias
install: $(NODE_MODULES) # an alias
#node_modules/: $(NODE_MODULES) # an alias

################################################################################
# COFFEE TARGETS

build-coffee: $(NODE_MODULES)
	rm -r $(RM_DASH_I) $(LIB_COV)

js: build-coffee $(COFFEE_JS) $(COFFEE_TEST_JS)

.SUFFIXES: .js .coffee
.coffee.js:
	$(COFFEE_COMPILE) $(COFFEE_COMPILE_ARGS) $<
$(COFFEE_JS_OBJ): $(NODE_MODULES) $(COFFEE_SRCS) $(COFFEE_TEST_SRCS)

################################################################################
# TEST TARGETS

test: js $(MOCHA_TESTS)
	$(MOCHA_EXE) $(MOCHA_TEST_ARGS) ${MOCHA_EXTRA_ARGS} $(MOCHA_TESTS)

test-watch: js $(MOCHA_TESTS)
	$(MOCHA_EXE) --watch $(MOCHA_TEST_ARGS) ${MOCHA_EXTRA_ARGS} $(MOCHA_TESTS)

coverage: js
	rm -r $(RM_DASH_I) $(JSCOVERAGE_TMP_DIR)
	rm -r $(RM_DASH_I) $(LIB_COV)
	mkdir -p $(JSCOVERAGE_TMP_DIR)
	mkdir -p $(JSCOVERAGE_TMP_DIR)/gleaning
	cp $(LIB)/*.js $(JSCOVERAGE_TMP_DIR)/.
	cp $(LIB)/gleaning/*.js $(JSCOVERAGE_TMP_DIR)/gleaning/.
	$(JSCOVERAGE_EXE) -v $(JSCOVERAGE_TMP_DIR) $(LIB_COV)
	mkdir -p `dirname $(JSCOVERAGE_REPORT)`
	$(MOCHA_EXE) $(MOCHA_COV_ARGS) $(MOCHA_TESTS) > $(JSCOVERAGE_REPORT)
	rm -r $(RM_DASH_I) $(JSCOVERAGE_TMP_DIR)
	rm -r $(RM_DASH_I) $(LIB_COV)

################################################################################
# MARKDOWN & OTHER DOC TARGETS

docs: markdown docco

.SUFFIXES: .html .md
.md.html:
	$(MARKDOWN_PROCESSOR) $(MARKDOWN_PROCESSOR_ARGS) -o $@ $<
$(MARKDOWN_HTML_OBJ): $(MARKDOWN_SRCS)

.SUFFIXES: .html .litcoffee
.litcoffee.html:
	$(MARKDOWN_PROCESSOR) $(MARKDOWN_PROCESSOR_ARGS) -o $@ $<
$(LITCOFFEE_HTML_OBJ): $(LITCOFFEE_SRCS)

markdown: $(MARKDOWN_HTML) $(LITCOFFEE_HTML)
html: markdown

docco: $(COFFEE_SRCS) $(NODE_MODULES)
	rm -r $(RM_DASH_I) docs/docco
	mkdir -p docs
	mv docs docs-temporarily-renamed-so-docco-doesnt-clobber-it
	docco $(COFFEE_SRCS)
	mv docs docs-temporarily-renamed-so-docco-doesnt-clobber-it/docco
	mv docs-temporarily-renamed-so-docco-doesnt-clobber-it docs

################################################################################
# PROUDCTION DEPLOYMENTS
deployable: npm js test
	mkdir "../$(TMP_PACKAGE_DIR)" && cd "../$(TMP_PACKAGE_DIR)" && cp -r ../web "$(PACKAGE_DIR)" && cd "$(PACKAGE_DIR)" && ln -s $(RM_DASH_I) config/config-prod.json config.json && cd .. && tar -czf "$(PACKAGE_DIR).tgz" "$(PACKAGE_DIR)" && mv "$(PACKAGE_DIR).tgz" ../web/. && cd .. && rm -r $(RM_DASH_I) "$(TMP_PACKAGE_DIR)" && cd web
