# React Patterns

## General

- Always pass the arg `props` and then destructure it in the component body
- Always used named exports for React components
- Use functional components over class components
- Custom hooks for shared logic
- Prefer composition over inheritance
- Use React.memo for expensive renders
- Keep state as close to where it's used as possible

## UI

- Always use [shadcn](https://ui.shadcn.com/docs/installation) for UI components.

## Hooks

- Always use React hooks at the top level of your component

## State Management

- Use React Context and Zustand where appropriate
- Use Tanstack Query for data fetching when server state is required
- Use URL parameters for client-side state when appropriate

## Additional Libraries

- Use `ahooks` for
  - `useControlledValue`
  - `useResponsive`
