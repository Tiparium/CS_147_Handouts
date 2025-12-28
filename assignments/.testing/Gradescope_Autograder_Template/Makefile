LABNAME_FILE := labname.cfg
LABNAME ?= $(shell [ -f $(LABNAME_FILE) ] && cat $(LABNAME_FILE) || echo "")

.PHONY: name submit

name:
	@lab="$(LAB)"; \
	if [ -z "$$lab" ]; then lab="$(NAME)"; fi; \
	if [ -z "$$lab" ]; then read -r -p "Enter lab name: " lab; fi; \
	if [ -z "$$lab" ]; then echo "Lab name is required (or set LAB=<name>)"; exit 1; fi; \
	echo "$$lab" > $(LABNAME_FILE); \
	echo "Lab name set to '$$lab'"

submit:
	@lab="$(LAB)"; \
	if [ -z "$$lab" ]; then lab="$(NAME)"; fi; \
	if [ -z "$$lab" ]; then lab="$(LABNAME)"; fi; \
	if [ -z "$$lab" ]; then echo "Lab name not set. Run 'make name LAB=<name>' first."; exit 1; fi; \
	echo "$$lab" > $(LABNAME_FILE); \
	mkdir -p drafts; \
	last=$$(ls drafts/"$$lab"_draft_*.zip 2>/dev/null | sed -E 's/.*_draft_([0-9]+)\.zip/\1/' | sort -n | tail -1); \
	if [ -z "$$last" ]; then next=1; else next=$$((last+1)); fi; \
	next_padded=$$(printf "%02d" "$$next"); \
	out="drafts/$$lab"_draft_"$$next_padded".zip; \
	echo "Creating $$out"; \
	zip -r "$$out" . -x "drafts/*" "docker/*" "test_submissions/*"
