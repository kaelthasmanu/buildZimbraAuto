include zimbra.ver

PHONY: release
release:
	@echo "Releasing zimbra v$(ZIMBRA_VER)"
	git tag $(ZIMBRA_VER)
	git push --atomic origin main $(ZIMBRA_VER)
	@echo "Done"