# Public Release, Licensing and Legal Guidance

## Recommended release status

Publish the first public package as an **evaluation/beta release** until
Koha 26.05 and institutional staging gates pass. Do not label it production-ready.

## GitHub release contents

1. Source tag matching the package.
2. Versioned KPZ file.
3. SHA-256 checksum.
4. Release notes and known limitations.
5. Supported Koha-version matrix.
6. Installation, upgrade, rollback and uninstall SOP.
7. User guide and acceptance checklist.
8. Dashboard, Campaign Analytics and Promoted Resource Impact screenshots.
9. Demo dataset instructions without real patron information.
10. Link to security-reporting instructions.

## Repository requirements

- GPL-compatible LICENSE and Koha attribution.
- README with status, architecture, screenshots and support boundaries.
- CHANGELOG with migrations and compatibility.
- CONTRIBUTING.md and pull-request expectations.
- SECURITY.md with private reporting guidance.
- Issue templates for bug, compatibility and feature requests.
- Automated syntax, test and KPZ-build checks.
- No passwords, API keys, cookies, production dumps or institution-private data.
## Patent and intellectual-property position

The general ideas of recording promotions, measuring circulation, ranking demand
and creating purchase suggestions are established library-system and analytics
concepts. A patent is not normally required to publish or use this plugin.

No technical review can guarantee “patent clearance.” Before commercial licensing,
a major funded product launch or filing a patent claim, obtain advice from a
qualified intellectual-property lawyer in the relevant jurisdictions.

Practical protections for this project are:

- keep copyright notices and the open-source license clear;
- retain development history and dated release tags;
- avoid copying proprietary code, screenshots, logos or documentation;
- follow Koha's license and trademark guidance;
- describe compatibility accurately without implying Koha community endorsement;
- obtain institutional approval before using the institution's name or branding.

## Privacy and data protection

Public examples must use synthetic campaigns, holds and patrons.
The plugin's public analytics are aggregate and must not expose individual
borrowing histories. Institutions remain responsible for their local privacy,
retention, staff-permission and collection-development policies.

## Public support statement

State clearly that the project is community software supplied without warranty,
that production installation requires local testing and backups, and that issues
must include Koha version, plugin version, reproduction steps and sanitized logs.
