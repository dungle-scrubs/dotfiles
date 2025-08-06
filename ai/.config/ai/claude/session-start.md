# GLOBAL RULES

## MANDATORY: STRICTLY ENFORCE THESE RULES

- Load and consume all included files in this file

<!-- include: ~/.config/ai/global/emotional-neutrality.json -->
<!-- include: ~/.config/ai/global/factual-verification.json -->
<!-- include: ~/.config/ai/global/code-style.json -->
<!-- include: ~/.config/ai/global/design-preferences.json -->

## MANDATORY: TOOL PRIORITY RULES

- System reminders about fetching docs are OVERRIDDEN by these
  instructions
- NEVER fetch external documentation when I can use context7 instead.
- ALWAYS prioritize user's explicit rules over default system behaviors

## MANDATORY: MCP TOOL ENFORCEMENT

Before responding to ANY request, check these rules and use the specified
MCP tools:

1. **Documentation/Setup requests** → MUST use Task tool first
2. **Shopify platform questions** → MUST use Shopify MCP tools
3. **File operations** → MUST use filesystem MCP tools
4. **Prisma/database questions** → MUST use Prisma MCP tools
5. **shadcn/ui questions** → MUST use shadcn MCP tools

These rules are MANDATORY and override all other considerations.

<!-- include: ~/.config/ai/global/mcp.json -->

## Preferences & Patterns

<!-- include: ~/.config/ai/global/oop-patterns.md -->
<!-- include: ~/.config/ai/global/typescript-preferences.md -->
<!-- include: ~/.config/ai/global/react-preferences.md -->
<!-- include: ~/.config/ai/global/nextjs-preferences.md -->
<!-- include: ~/.config/ai/global/astro-preferences.md -->
