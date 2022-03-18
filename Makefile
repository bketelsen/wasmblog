WAGI ?= wagi
# If PREVIEW_MODE is on then unpublished content will be displayed.
PREVIEW_MODE ?= 0
SHOW_DEBUG ?= 1
BASE_URL ?= http://localhost:3000

.PHONY: serve
serve:
	$(WAGI) -c ./modules.toml --log-dir ./logs -e PREVIEW_MODE=$(PREVIEW_MODE) -e SHOW_DEBUG=$(SHOW_DEBUG) -e BASE_URL=$(BASE_URL)

.PHONY: run
run: serve

# Quick ergonomic to create an ISO 8601 date on Mac or on Linux (Gnu date)
.PHONY: date
date:
	date -u +"%Y-%m-%dT%H:%M:%SZ"
