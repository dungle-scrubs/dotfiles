/**
 * Attention.spoon - Shared Design Tokens
 * Generated from tokens.json - Single source of truth for colors, fonts, spacing
 */

export const colors = {
  bg: {
    primary: '#1a1a1a',
    secondary: '#252525',
    tertiary: '#2a2a2a',
  },
  text: {
    primary: '#ffffff',
    secondary: '#8b8b8b',
    muted: '#666666',
    dim: '#555555',
  },
  border: {
    subtle: '#333333',
    medium: '#444444',
  },
  accent: {
    primary: '#5e6ad2',
    slack: '#e01e5a',
    ai: '#8b5cf6',
    warning: '#f97316',
    success: '#10b981',
    notion: '#c9a67a',
  },
} as const;

export const fonts = {
  mono: 'CaskaydiaCove Nerd Font Mono',
  sizes: {
    xs: 11,
    sm: 12,
    base: 14,
    lg: 16,
    xl: 18,
    xxl: 20,
  },
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
} as const;

export const radii = {
  sm: 4,
  md: 6,
  lg: 10,
} as const;

export const dimensions = {
  boxWidth: 900,
  boxWidthWide: 1400,
  boxHeight: 600,
  titleHeight: 36,
  footerHeight: 40,
  searchBarHeight: 40,
  sectionHeaderHeight: 30,
  groupHeaderHeight: 26,
  lineHeight: 24,
  sectionSpacing: 20,
  groupSpacing: 8,
} as const;

// Type exports for type-safe usage
export type ColorPath =
  | 'bg.primary' | 'bg.secondary' | 'bg.tertiary'
  | 'text.primary' | 'text.secondary' | 'text.muted' | 'text.dim'
  | 'border.subtle' | 'border.medium'
  | 'accent.primary' | 'accent.slack' | 'accent.ai' | 'accent.warning' | 'accent.success' | 'accent.notion';

export type FontSize = keyof typeof fonts.sizes;
export type SpacingSize = keyof typeof spacing;
export type RadiusSize = keyof typeof radii;
