# Project Evolution Changelog

This is a product/engineering evolution log, not a reconstruction of every Git commit.

## 2026-08-15 — v0.1 foundation

- Initial Koha Tool Plugin scaffold established.
- Project committed to Koha-as-source-of-truth architecture.
- Plugin-owned campaigns/items/audit/settings schema created.
- Non-destructive uninstall policy established.
- Dashboard shell and intentionally read-only New Promotion mockup introduced.
- REST namespace reserved with authenticated health endpoint.
- Initial version set to 0.1.0.

## 2026-08-15 to 2026-08-17 — KTD/plugin-loading stabilization

- Worked through Koha plugin discovery/loading errors in KTD.
- Correct plugin support/path initialization and Plack restart sequence established.
- Resolved a Template Toolkit render failure that had prevented Run Tool/dashboard use.
- Plugin became visible, enabled and runnable in Koha 25.11 development environment.
- Real-world Nairobi campaign workflows were documented as universal acceptance requirements rather than hard-coded defaults.

## 2026-08-17 — KPZ packaging and clean-install validation

- Python KPZ builder added/documented.
- Versioned v0.1.0 KPZ and SHA-256 checksum successfully produced and archive structure inspected.
- Disposable clean KTD instance used to test normal Koha plugin upload/install path.
- Plugin load, screens, table creation and health endpoint smoke tests passed.
- Disable/re-enable persistence was manually verified with plugin-owned settings data.

## 2026-08-18 — v0.2 campaign creation checkpoint

- Active development moved to `feature/v0.2-campaign-crud`.
- Plugin version moved to 0.2.0.
- Writable campaign form implemented.
- Added campaign channel and broader campaign metadata input.
- Added Koha branch selection/validation.
- Barcode paste/scan parsing and live Koha item validation implemented.
- Invalid barcodes block the entire campaign save.
- Duplicate barcode entries are ignored/reported and DB uniqueness protects campaign-item links.
- Campaign, item links and audit record are written transactionally.
- Dashboard shows saved campaign/item counts and recent campaigns.
- Manual tests passed for no-barcode campaign, valid barcode, invalid barcode, duplicate input, DB audit verification and mixed valid+invalid rollback.
- Health endpoint stale-version defect discovered: endpoint still returned 0.1.0 while plugin was 0.2.0.
- Commit `3537b8e` changed health controller to use the authoritative plugin `$VERSION`.

## 2026-08-29 — environment recovery and Project Brain

- A temporary WSL routing problem prevented HTTPS connections to GitHub while Windows connectivity remained healthy; WSL networking was refreshed and Git pull succeeded.
- During KTD recovery, only `kohadev-koha-1` was recreated while populated `kohadev-db-1` remained. The new application container exited with code 11 because KTD initialization detected a non-empty database.
- Current blocker classified as KTD environment lifecycle mismatch, not verified plugin-code failure.
- Durable Project Brain structure introduced to preserve requirements, architecture, decisions, issues, tests, current state, roadmap and session handoff outside chat history.

## Next evolution

Close v0.2 checkpoint security/runtime verification, then expand campaign management/configuration, multi-location support and the analytics engine before UI modernization and production release work.