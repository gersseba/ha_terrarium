# Copilot Instructions for ha_terrarium

## Project Scope
- This repository stores Home Assistant configuration YAML files only.
- Do not add database files, recorder exports, or runtime state artifacts.
- Deployment is done locally via SSH, so all changes must be file-based and reproducible from git.

## Goal
Automate lighting and heating for three areas:
- Terrarium
- Fruehbeet Kruemel
- Fruehbeet Sternies

Each area has:
- A thermometer (temperature sensor)
- A smart plug for lighting
- A smart plug for heating

## Existing Naming Conventions
Use the established entity ID style from this repo:
- Lowercase snake_case for IDs
- Prefix IDs by area:
  - terrarium_
  - fruehbeet_kruemel_
  - fruehbeet_sternies_
- Transliterate umlauts in IDs:
  - fruehbeet (not fruhbeet)
  - kruemel (ASCII ID form)
- Use German domain terms already present in helpers:
  - lampen
  - heizung
  - modus

Examples already in use:
- input_select.terrarium_heizung_modus
- input_select.fruehbeet_kruemel_lampen
- input_datetime.fruehbeet_sternies_heizung_morgens

## Automation and Helper Patterns
When adding new logic, prefer these patterns:
- Keep `configuration.yaml` include structure intact.
- Add schedule helper times to `helpers/input_datetime.yaml`.
- Add mode selectors to `helpers/input_select.yaml`.
- Keep mode options consistent with existing values: `Auto`, `An`, `Aus`.
- Place actual automation logic in `automations.yaml`.
- Use clear aliases that include area and function (Lampen or Heizung).

## Behavioral Expectations for Future Changes
- In `Auto` mode, control outputs by schedule and/or temperature conditions.
- In `An` mode, force the output on.
- In `Aus` mode, force the output off.
- Keep lighting and heating logic separate per area to avoid cross-area side effects.
- Keep thresholds and times configurable via helpers instead of hardcoding values in automations.

## File Safety and Quality
- Preserve YAML formatting and list structure expected by Home Assistant.
- Avoid renaming existing entities unless explicitly requested, to prevent broken references.
- Prefer incremental, reviewable changes over large rewrites.
- If introducing new entities, follow the same prefix and suffix schema used by current helpers.
