# Attention Dashboard: Intercom + Shopify Integrations

## Overview

Add two new data sources to the Attention dashboard:
1. **Intercom** - Show new/unassigned customer support conversations
2. **Shopify Apps** - Show recent app installations

## Intercom Integration

### API Setup
- Uses Intercom API v2.x with bearer token auth
- API key stored in `~/.config/hammerspoon/secrets.json` as `INTERCOM_API_KEY`
- Base URL: `https://api.intercom.io`

### Endpoints Needed
- `GET /conversations` - List conversations with filters
  - Filter by `state=open` and `assignee=unassigned` for new requests
  - Sort by `created_at` descending

### Data to Display
- Conversation subject/preview
- Customer name
- Created time (relative: "2h ago")
- Clickable to open in Intercom web

### Implementation Steps
1. Create `api/intercom.lua` module
2. Add `fetchOpenConversations(callback)` function
3. Parse response to extract: id, subject, user_name, created_at, url
4. Add Intercom section to dashboard (right column with Slack)
5. Add click handler to open conversation URL

## Shopify Apps Integration

### API Setup
- Uses Shopify Partners API (GraphQL)
- API key stored in `~/.config/hammerspoon/secrets.json` as `SHOPIFY_PARTNERS_TOKEN`
- Partner organization ID needed: `SHOPIFY_PARTNER_ORG_ID`

### GraphQL Query
```graphql
query RecentInstalls($appId: ID!) {
  app(id: $appId) {
    installations(first: 10, sortKey: INSTALLED_AT, reverse: true) {
      edges {
        node {
          shop {
            name
            myshopifyDomain
          }
          installedAt
        }
      }
    }
  }
}
```

### Data to Display
- Shop name
- Shop domain
- Install time (relative)
- App name (if monitoring multiple apps)

### Implementation Steps
1. Create `api/shopify.lua` module
2. Add `fetchRecentInstalls(callback)` function
3. Support multiple app IDs via config
4. Parse response to extract: shop_name, domain, installed_at
5. Add Shopify section to dashboard
6. Click handler optional (could open Shopify Partners dashboard)

## Dashboard Layout Considerations

With 5 data sources (Calendar, Linear, Slack, Intercom, Shopify), consider:
- 3-column layout for wide screens
- Left: Calendar + Linear
- Center: Slack
- Right: Intercom + Shopify

Or keep 2-column with scrolling if content overflows.

## Environment Variables Needed

```json
{
  "INTERCOM_API_KEY": "dG9rOm...",
  "SHOPIFY_PARTNERS_TOKEN": "shppa_...",
  "SHOPIFY_PARTNER_ORG_ID": "123456",
  "SHOPIFY_APP_IDS": ["gid://partners/App/123", "gid://partners/App/456"]
}
```

## Priority

1. Intercom first (simpler REST API)
2. Shopify second (GraphQL, may need Partners API access setup)

## Testing

- Mock API responses for development
- Test with actual API keys in secrets.json
- Verify click handlers open correct URLs
