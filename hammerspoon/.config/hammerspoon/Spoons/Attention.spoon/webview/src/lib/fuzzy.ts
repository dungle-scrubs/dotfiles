/**
 * Attention.spoon - Fuzzy Matching Library
 * Shared fuzzy search implementation for consistent filtering across webviews
 */

/**
 * Simple fuzzy match - checks if all characters of query appear in text in order
 * @param text The text to search in
 * @param query The search query
 * @returns true if query characters appear in text in order
 */
export const fuzzyMatch = (text: string, query: string): boolean => {
  if (!query) return true;
  const lowerText = text.toLowerCase();
  const lowerQuery = query.toLowerCase();
  let queryIndex = 0;
  for (let i = 0; i < lowerText.length && queryIndex < lowerQuery.length; i++) {
    if (lowerText[i] === lowerQuery[queryIndex]) {
      queryIndex++;
    }
  }
  return queryIndex === lowerQuery.length;
};

/**
 * Score a fuzzy match (higher is better)
 * Useful for sorting results by match quality
 * @param text The text to search in
 * @param query The search query
 * @returns Score from 0 to 100, or -1 if no match
 */
export const fuzzyScore = (text: string, query: string): number => {
  if (!query) return 100;
  if (!fuzzyMatch(text, query)) return -1;

  const lowerText = text.toLowerCase();
  const lowerQuery = query.toLowerCase();

  // Exact match at start gets highest score
  if (lowerText.startsWith(lowerQuery)) return 100;

  // Contains query as substring gets high score
  if (lowerText.includes(lowerQuery)) return 80;

  // Calculate score based on gap between matched chars
  let totalGap = 0;
  let queryIndex = 0;
  let lastMatchIndex = -1;

  for (let i = 0; i < lowerText.length && queryIndex < lowerQuery.length; i++) {
    if (lowerText[i] === lowerQuery[queryIndex]) {
      if (lastMatchIndex >= 0) {
        totalGap += i - lastMatchIndex - 1;
      }
      lastMatchIndex = i;
      queryIndex++;
    }
  }

  // Normalize: fewer gaps = higher score
  const avgGap = totalGap / (lowerQuery.length || 1);
  return Math.max(10, 60 - avgGap * 5);
};

/**
 * Filter and sort items by fuzzy match
 * @param items Array of items to filter
 * @param query Search query
 * @param getText Function to extract searchable text from an item
 * @returns Filtered and sorted items
 */
export const fuzzyFilter = <T>(
  items: T[],
  query: string,
  getText: (item: T) => string
): T[] => {
  if (!query) return items;

  const scored = items
    .map(item => ({
      item,
      score: fuzzyScore(getText(item), query),
    }))
    .filter(({ score }) => score >= 0)
    .sort((a, b) => b.score - a.score);

  return scored.map(({ item }) => item);
};
