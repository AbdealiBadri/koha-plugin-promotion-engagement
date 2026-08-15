# Safety and Upgrade Policy

1. Never patch Koha core for plugin functionality.
2. Never add columns to Koha core tables.
3. Use namespaced plugin tables only.
4. Database changes must be idempotent and versioned.
5. Uninstall must not silently destroy historical data.
6. Test every release on staging before production.
7. Test against the current supported Koha branch and the next planned upgrade branch.
8. Back up Koha database, plugin tables, KPZ and configuration before production upgrade.
9. Use least-privilege staff/API accounts.
10. Do not expose patron-identifiable analytics to general external dashboards.
