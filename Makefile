# SPDX-FileCopyrightText: 2024 SAP SE or an SAP affiliate company and Greenhouse contributors
# SPDX-License-Identifier: Apache-2.0

PREFIX ?=greenhouse
TITLE ?=
docsFolder=architecture-decision-records
LC_PREFIX=$(shell echo $(PREFIX) | tr '[:upper:]' '[:lower:]')
LC_TITLE=$(shell echo $(TITLE) | tr '[:upper:]' '[:lower:]')

.PHONY: check
check:
	@if [ -z "$(LC_TITLE)" ]; then \
		echo "TITLE is required. Please provide a title using make init TITLE=Your Title Here"; \
		exit 1; \
	fi
	@echo "$(LC_TITLE)" | grep -qE "^[a-zA-Z0-9-]+$$" || { \
	echo "TITLE contains invalid characters. Only alphanumeric characters and hyphens are allowed."; \
	exit 1; \
	}

.PHONY: init
init: check
	echo "Checking for Node.js..."
	@command -v node >/dev/null 2>&1 || { echo >&2 "Node.js is not installed. Please install Node.js."; exit 1; }
	@echo "Checking for log4brains..."
	@command -v log4brains >/dev/null 2>&1 || { echo >&2 "log4brains is not installed globally. Please install it by running 'npm install -g log4brains'."; exit 1; }
	$(eval MAX_INDEX=$(shell find ${docsFolder} -name '[0-9][0-9][0-9]-*.md' | sed 's/.*\/\([0-9][0-9][0-9]\)-.*/\1/' | sort -n | tail -1))
	$(eval NEW_INDEX=$(shell printf "%03d" $$((10#$(MAX_INDEX) + 1))))
	@echo "Next ADR index: $(NEW_INDEX)"
	@echo "Creating new ADR with title prefix $(NEW_INDEX)-$(LC_PREFIX)-$(LC_TITLE).md"
	$(eval ADR_TITLE=$(shell echo "$(NEW_INDEX)-$(LC_PREFIX)-$(LC_TITLE)"))
	$(eval GENERATED_FILE=$(shell log4brains adr new --quiet $(ADR_TITLE)))
	@mv "${docsFolder}/${GENERATED_FILE}.md" "${docsFolder}/$(ADR_TITLE).md"
