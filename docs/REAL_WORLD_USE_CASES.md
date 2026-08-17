# Real-World Use Cases

## Purpose

This document records real library promotion workflows that the plugin must be able to support without hard-coding institution-specific campaign names, locations, languages, channels, or schedules.

The Nairobi examples below are acceptance criteria and design references. They are **not** default campaigns to be pre-filled into every installation.

The plugin must remain reusable by other Koha libraries and campuses through configurable campaign types, channels, locations, languages, audiences, frequencies, and reporting rules.

## Core design principle

Promotion & Engagement should record **what was promoted, where, how, when, to whom, and by whom**, then measure the effect using Koha circulation data as the source of truth.

A campaign/activity should therefore be able to represent configurable dimensions such as:

- Campaign/activity type
- Promotion channel
- Physical or digital location
- Language
- Audience
- Frequency/cadence
- Start and end date/time
- Bibliographic records/items promoted
- Subject, collection, author, resource type, or other theme
- Staff member responsible
- Notes/evidence
- Status/workflow stage
- Circulation-impact measurement windows

## Nairobi operational examples

### Subject-wise / New Arrivals Displays

Current practice: weekly physical displays.

Current display locations:

1. Reception – Ground Floor
2. Reception – First Floor
3. Ground Floor – Opposite Lift
4. Mezzanine – Boys
5. First Floor – Opposite Ma'mal
6. Mezzanine – Girls
7. Ground Floor – Girls

System requirement:

- Locations must be configurable data, not hard-coded fields.
- One campaign may use one or multiple locations.
- The same location must be reusable across many campaigns.
- Reports should eventually compare circulation impact by location, subject/theme, and time period.

### Email Campaigns

Current practice: weekly email promotions.

Current examples:

- English
- Arabic
- E-books

System requirement:

- Email must be treated as a configurable channel.
- Language and content/resource type must be separate configurable dimensions.
- The design must allow additional languages, audiences, or email campaign categories in future.
- Campaign records should be able to link the books/resources promoted in each email.

### Digital Signage

Current practice: daily digital signage in English and Arabic.

System requirement:

- Digital signage must be a configurable promotion channel.
- Multilingual campaigns must be supported.
- Recurring/daily activities should be recordable without forcing users to create unrelated duplicate definitions manually.

### Physical Signage

Current practice: weekly physical signage.

System requirement:

- Physical signage must be distinct from physical book displays where useful for reporting.
- It should still use the same underlying campaign model so analytics remain comparable across channels.

### E-resource of the Month

Current practice: monthly featured electronic resource.

System requirement:

- The platform must support promotion of electronic resources as well as physical Koha items.
- The data model should not assume every promoted object has a physical barcode.
- External identifiers/URLs or future e-resource identifiers should be supportable without compromising Koha item-linked analytics.

### Author of the Month

Current practice: monthly author-focused promotion.

System requirement:

- Campaigns must be able to represent a theme or entity such as an author and link multiple bibliographic records/items to that campaign.
- Analytics should aggregate results both at campaign level and promoted-title/item level.

### Newspaper / Magazine of the Week

Current practice: weekly periodical promotion.

System requirement:

- Promotion types must not be limited to monographs/books.
- The plugin should be compatible with Koha bibliographic/item records representing newspapers, magazines, serials, or similar material.

### Recommended for Review Display

Current practice: display of titles recommended for academic/book-review activity.

System requirement:

- The platform must support audience/purpose-specific campaigns.
- A promotion may be tagged for an academic purpose without requiring a separate hard-coded workflow.
- Future reporting should be able to distinguish academic/review promotions from general reading promotion.

## Universal configuration requirements

The above Nairobi activities must be achievable through generic configuration rather than special-case code.

At minimum, future versions should allow administrators to manage configurable values for:

- Campaign/activity types
- Channels
- Locations
- Languages
- Audiences
- Frequencies/cadences
- Statuses/workflow stages where appropriate
- Impact windows and analytics defaults

Configuration should be portable across campuses while allowing each installation to maintain its own operational vocabulary.

## Dashboard and analytics acceptance criteria

The dashboard should evolve beyond counting campaigns. It should help library management understand whether promotion changes reading/circulation behaviour.

The system should eventually be capable of answering questions such as:

- How many campaigns were run by week, month, term, channel, and location?
- Which promoted titles/items were subsequently issued?
- What percentage of promoted items converted to at least one checkout?
- How long after promotion did the first checkout occur?
- How did circulation change before, during, and after a campaign?
- Which campaign types create the strongest circulation uplift?
- Which physical display locations perform best?
- Which subjects/collections respond best to promotion?
- Which languages or audience segments respond best where that data can be measured safely?
- How does email performance compare with physical display, digital signage, or physical signage?
- Which promoted titles received no circulation response?
- Which campaigns contain the same titles repeatedly, and with what outcome?
- What is the circulation impact over configurable 7/14/30/60-day windows?

Analytics must use Koha circulation/statistics data as the source of truth and should not duplicate or rewrite Koha core transaction history.

## Data-safety and portability requirements

- Do not hard-code Nairobi branch codes, locations, languages, campaign names, or staff names into the plugin.
- Plugin-owned configuration and campaign data must remain namespaced and removable independently of Koha core data.
- Koha bibliographic, item, patron, branch, and circulation data should be read from Koha rather than copied unnecessarily.
- External applications should eventually consume the same business rules through the plugin API so dashboard figures do not diverge between Koha and other apps.
- Historical spreadsheets/manual records should be importable later through a controlled migration process with validation, duplicate detection, audit logging, and rollback planning.

## Production acceptance examples

Before a production release, testing should demonstrate that an administrator can configure Nairobi's current workflows without source-code changes, including:

- Weekly subject/new-arrival displays across the seven current locations
- Weekly English, Arabic, and e-book email activities
- Daily multilingual digital signage
- Weekly physical signage
- Monthly featured e-resource and author campaigns
- Weekly newspaper/magazine promotion
- Recommended-for-review displays

Passing these examples means the universal model is expressive enough for the current Nairobi operation; it does not mean these examples should ship as default data.
