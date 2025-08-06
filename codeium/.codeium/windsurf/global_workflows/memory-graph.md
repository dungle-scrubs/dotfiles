---
description: 🤖 AI: Please add a clear description of what this workflow does
---

<!-- Last synced: 2025-08-06T04:17:31.081Z -->
<!-- Source: /Users/kevin/dotfiles/claude/.claude/commands/memory-graph.md -->
<!-- Sync version: 1.0.0 -->

<!-- Last synced: 2025-08-06T04:17:31.081Z -->
<!-- Source: /Users/kevin/dotfiles/claude/.claude/commands/memory-graph.md -->
<!-- Sync version: 1.0.0 -->

## Memory Graph Setup Command

with a new test command
## Usage

Run this command: "Build the memory graph for this project"
## Instructions for Claude

When this command is triggered, create a comprehensive memory graph that models the relationships between widgets, global settings, and Shopify integration for the Reviewsion project.
## Tools for memory mcp

Tools for memory (9 tools):

- create_entities
- create_relations
- add_observations
- delete_entities
- delete_observations
- delete_relations
- read_graph
- search_nodes
- open_nodes
## Entity Types to Create

1. `Core Architecture Entities:`
   * `widget` - The 13 review widgets (all-reviews, featured-review, compact-reviews, etc.)
   * `store` - Zustand stores managing global state
   * `provider` - React providers handling context/data flow
   * `schema` - Zod validation schemas for prop validation
   * `liquid_block` - Shopify liquid templates
   * `package` - Internal packages (@rv/core, @rv/stores, etc.)

2. `Integration Entities:`
   * `shopify_integration` - Connections to Shopify APIs/features
   * `global_setting` - Settings shared across all widgets
   * `data_flow` - How data moves through the system
## Required Entities to Model

`Core State Management:`

- ReviewsionStore (store) - Global Zustand store at packages/stores/src/reviewsion-store.ts:98
- AppEmbedDetection (provider) - Shopify app embed integration provider  
- BlockProvider (provider) - Converts liquid props and merges global settings
- GlobalSettings (global_setting) - Shared settings from reviewsion.liquid

`Key Widgets (create entities for all 13):`

- AllReviewsWidget, FeaturedReviewWidget, CompactReviewsWidget, etc.
## Required Relationships to Create

`Data Flow Relationships:`

- Widgets `accesses_global_state` ReviewsionStore
- Widgets `wrapped_by` AppEmbedDetection  
- Widgets `receives_props_from` BlockProvider
- BlockProvider `merges_with_widget_props` GlobalSettings
- AppEmbedDetection `updates_app_embed_data` ReviewsionStore
- GlobalSettings `stored_in` ReviewsionStore
- ReviewsionStore `provides_state_to` all widgets

`Architecture Relationships:`

- Each widget `validates_props_with` its corresponding schema
- Each widget `renders_via` its corresponding liquid_block
- All widgets `share_settings_via` GlobalSettings
## Key Observations to Include

`For ReviewsionStore:`

- "Global Zustand store managing shopifyDesignMode, shopifyTheme, appEmbedData, and widgets array"
- "Accessed via window.reviewsionStore.getState() in all entrypoints"
- "Provides setWidget method for updating widget data and status"
- "Located at packages/stores/src/reviewsion-store.ts:98"

`For BlockProvider:`

- "Converts snake_case liquid props to camelCase React props"
- "Merges widget-specific props with global settings from reviewsion.liquid"
- "Provides useBlock() hook for accessing validated props"
- "Part of 4-component prop validation system"

`For Each Widget:`

- Brief description of widget functionality
- "Has liquid block, entrypoint, and widget component files"
- "Uses [WidgetName]LiquidContract schema for prop validation"
- Specific features or capabilities
## Usage Examples to Document

Document these query patterns in observations:

`Debugging widget issues:`

```javascript
search_nodes({ query: "carousel widget" })
search_nodes({ query: "accesses_global_state" })
```

`Adding new widgets:`

```javascript
create_entities([{name: "NewWidget", entityType: "widget", observations: [...]}])
create_relations([{from: "NewWidget", to: "ReviewsionStore", relationType: "accesses_global_state"}])
```

`Investigating Shopify integration:`

```javascript
search_nodes({ query: "shopify" })
search_nodes({ query: "provides_state_to" })
```
## Expected Outcome

After running this command, the memory graph should contain:

- All 13+ widget entities with their relationships
- Core architecture entities (stores, providers, schemas)
- Data flow relationships showing how props and state move through the system
- Shopify integration touchpoints
- Searchable observations for debugging and development

This creates a comprehensive map of the widget architecture, global state management, and Shopify integration relationships.