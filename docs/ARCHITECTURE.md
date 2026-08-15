# Architecture

## Core principle

The plugin stores promotion events; Koha stores library truth.

### Plugin-owned data
- Campaign metadata
- Campaign-to-item links
- Audit history
- Plugin settings

### Koha-owned data (read-only from this plugin unless explicitly required later)
- Bibliographic records
- Items and barcodes
- Patrons and extended attributes
- Circulation/statistics
- Branches, locations, authorised values

## API

Reserved namespace: `/api/v1/contrib/ajsn_promotion/`.

The Koha staff UI and future external applications should share the same service/business rules so KPI calculations cannot diverge between interfaces.
