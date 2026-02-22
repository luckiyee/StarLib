# Project File Schema (.starlibproj)

Version: 1.0

## Root Object

```json
{
  "meta": { ... },
  "settings": { ... },
  "window": { ... },
  "tabs": [ ... ],
  "templates": [ ... ],
  "assets": { ... }
}
```

## meta

| Field | Type | Description |
|-------|------|-------------|
| schemaVersion | string | Schema version (e.g., "1.0") |
| appVersion | string | App version that created this file |
| createdAt | string | ISO 8601 timestamp |
| updatedAt | string | ISO 8601 timestamp |
| projectName | string | Human-readable project name |
| starLibFileHash | string? | SHA256 hash of the StarLib.lua used |

## settings

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| useUpgradedStarLib | boolean | false | Use StarLibUpgraded.lua |
| starLibPath | string | "StarLib/StarLib.lua" | Path in loadstring preamble |
| bundleStarLib | boolean | true | Include StarLib source in export |

## window

| Field | Type | Description |
|-------|------|-------------|
| name | string | Window title |
| guiName | string | ScreenGui name |
| toggleKey | string? | KeyCode name (e.g., "RightShift") |
| position | string? | UDim2 position (null = center) |
| theme | object | Only overridden theme keys (Color3 as "#RRGGBB") |

## tabs[]

| Field | Type | Description |
|-------|------|-------------|
| id | string | UUID v4 |
| name | string | Tab display name |
| icon | string? | Asset ID for tab icon |
| nodes | array | Ordered list of UINode objects |

## nodes[]

| Field | Type | Description |
|-------|------|-------------|
| id | string | UUID v4 |
| type | string | Widget type enum name |
| props | object | Widget-specific properties |
| callbackCode | string? | Raw Lua callback body |
| bindVariable | string? | Variable name for code gen |
| enabled | boolean | Include in code gen |
| visible | boolean | Show in designer |

## templates[]

Same structure as a tab with id, name, and nodes array.

## assets

```json
{
  "icons": [
    { "id": "uuid", "name": "Display Name", "assetId": "rbxassetid://12345" }
  ]
}
```
