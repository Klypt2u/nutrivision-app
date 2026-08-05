# Assets / data directory

This folder is reserved for **bundled offline data** that ships with the app:

- `meal_templates.json` — pre-baked meal templates indexed by dietary preference
- `region_foods.json` — region-specific food expansions (e.g. Mediterranean)

The mock data currently lives in `lib/core/services/` so the app runs without
shipping JSON files. Drop replacement JSONs here as the dataset grows.
