/**
 * Attention.spoon - Vim-style Hint System
 * Reusable hint labels for keyboard navigation of clickable elements
 */

/**
 * Generate hint labels using home row keys first for ergonomics
 * Single chars first (a-z), then two-char combos (aa, as, ad, ...)
 * @param count Number of labels needed
 * @returns Array of hint labels
 */
export const generateHintLabels = (count: number): string[] => {
  const labels: string[] = [];
  const chars = 'asdfghjklqwertyuiopzxcvbnm'; // Home row first

  // First pass: single characters
  for (let i = 0; i < Math.min(count, chars.length); i++) {
    labels.push(chars[i]);
  }

  // Second pass: two-character combinations if needed
  if (count > chars.length) {
    for (let i = 0; i < chars.length && labels.length < count; i++) {
      for (let j = 0; j < chars.length && labels.length < count; j++) {
        labels.push(chars[i] + chars[j]);
      }
    }
  }

  return labels;
};

/**
 * Target element info for hint system
 */
export interface HintTarget {
  label: string;
  element: HTMLElement;
  action: () => void;
}

/**
 * Hint system state manager
 */
export class HintSystem {
  private targets: HintTarget[] = [];
  private buffer = '';
  private active = false;
  private onActivate?: () => void;
  private onDeactivate?: () => void;

  constructor(options?: {
    onActivate?: () => void;
    onDeactivate?: () => void;
  }) {
    this.onActivate = options?.onActivate;
    this.onDeactivate = options?.onDeactivate;
  }

  /**
   * Update targets from DOM elements
   * @param selector CSS selector for target elements
   * @param getAction Function to create action for each element
   */
  updateTargets(
    selector: string,
    getAction: (el: HTMLElement) => (() => void) | null
  ): void {
    const elements = document.querySelectorAll<HTMLElement>(selector);
    const labels = generateHintLabels(elements.length);

    this.targets = [];

    elements.forEach((el, index) => {
      const label = labels[index];
      const action = getAction(el);
      if (!action) return;

      // Add or update hint badge
      let badge = el.querySelector('.hint-badge') as HTMLElement;
      if (!badge) {
        badge = document.createElement('span');
        badge.className = 'hint-badge';
        el.appendChild(badge);
      }
      badge.textContent = label;
      badge.dataset.full = label;

      this.targets.push({ label, element: el, action });
    });
  }

  /**
   * Check if hint mode is active
   */
  isActive(): boolean {
    return this.active;
  }

  /**
   * Enter hint mode
   */
  enter(): void {
    if (this.targets.length === 0) return;
    this.active = true;
    this.buffer = '';
    document.body.classList.add('hint-mode');
    this.updateHighlights();
    this.onActivate?.();
  }

  /**
   * Exit hint mode
   */
  exit(): void {
    this.active = false;
    this.buffer = '';
    document.body.classList.remove('hint-mode');
    this.updateHighlights();
    this.onDeactivate?.();
  }

  /**
   * Handle key input
   * @param key The key pressed
   * @returns true if key was handled, false if should exit hint mode
   */
  handleInput(key: string): boolean {
    if (!/^[a-z]$/i.test(key)) {
      this.buffer = '';
      this.updateHighlights();
      return false;
    }

    this.buffer += key.toLowerCase();

    // Find exact match
    const exactMatch = this.targets.find(t => t.label === this.buffer);
    if (exactMatch) {
      this.buffer = '';
      this.updateHighlights();
      exactMatch.action();
      return true;
    }

    // Find partial matches
    const partialMatches = this.targets.filter(t =>
      t.label.startsWith(this.buffer)
    );
    if (partialMatches.length === 0) {
      // No matches, reset
      this.buffer = '';
      this.updateHighlights();
      return false;
    }

    // Update highlights to show matched portion
    this.updateHighlights();
    return true;
  }

  /**
   * Update visual highlights based on current buffer
   */
  private updateHighlights(): void {
    this.targets.forEach(target => {
      const badge = target.element.querySelector('.hint-badge') as HTMLElement;
      if (!badge) return;

      if (this.buffer && target.label.startsWith(this.buffer)) {
        // Show matched/unmatched portions
        const matched = target.label.substring(0, this.buffer.length);
        const remaining = target.label.substring(this.buffer.length);
        badge.innerHTML = `<span class="hint-matched">${matched}</span>${remaining}`;
        badge.classList.add('hint-active');
      } else {
        badge.textContent = target.label;
        badge.classList.remove('hint-active');
        if (this.buffer) {
          badge.classList.add('hint-dimmed');
        } else {
          badge.classList.remove('hint-dimmed');
        }
      }
    });
  }

  /**
   * Get current targets count
   */
  getTargetCount(): number {
    return this.targets.length;
  }
}
