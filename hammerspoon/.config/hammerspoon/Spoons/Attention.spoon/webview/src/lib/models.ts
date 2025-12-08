/**
 * Attention.spoon - Shared LLM Model Definitions
 * Single source of truth for available AI models
 */

export interface ModelOption {
  id: string;
  name: string;
  key: string; // hotkey
}

/**
 * Available LLM models via OpenRouter
 * Kept in sync with init.lua LLM_MODELS
 */
export const MODELS: ModelOption[] = [
  { id: 'openrouter/auto', name: 'Auto (Best)', key: 'a' },
  { id: 'openai/gpt-4o-mini', name: 'GPT-4o Mini', key: 'b' },
  { id: 'openai/gpt-4o', name: 'GPT-4o', key: 'c' },
  { id: 'anthropic/claude-3.5-haiku', name: 'Claude 3.5 Haiku', key: 'd' },
  { id: 'anthropic/claude-sonnet-4', name: 'Claude Sonnet 4', key: 'e' },
  { id: 'x-ai/grok-4.1-fast', name: 'Grok 4.1 Fast', key: 'f' },
  { id: 'google/gemini-2.0-flash-exp:free', name: 'Gemini 2.0 Flash', key: 'g' },
  { id: 'meta-llama/llama-3.3-70b-instruct', name: 'Llama 3.3 70B', key: 'h' },
  { id: 'deepseek/deepseek-chat', name: 'DeepSeek V3', key: 'i' },
  { id: 'qwen/qwen-2.5-72b-instruct', name: 'Qwen 2.5 72B', key: 'j' },
];

/**
 * Get display name from model ID
 * @param modelId Full model ID (e.g., "openai/gpt-4o")
 * @returns Display name or extracted model name
 */
export const getModelDisplayName = (modelId: string): string => {
  const model = MODELS.find(m => m.id === modelId);
  if (model) return model.name;
  // Extract just the model name from the full ID
  const parts = modelId.split('/');
  return parts[parts.length - 1];
};

/**
 * Find model by hotkey
 * @param key The hotkey (a-j)
 * @returns Model option or undefined
 */
export const getModelByKey = (key: string): ModelOption | undefined => {
  return MODELS.find(m => m.key === key);
};
