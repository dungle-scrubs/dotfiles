import { render } from 'preact';
import { useState, useEffect, useRef, useCallback } from 'preact/hooks';
import { MODELS, type ModelOption } from './lib/models';
import { fuzzyMatch } from './lib/fuzzy';

// =============================================================================
// Types
// =============================================================================

interface Message {
  id: string;
  role: 'user' | 'assistant' | 'error';
  content: string;
  actualModel?: string; // Model that actually responded (for auto routing)
}

interface AiChatAppState {
  messages: Message[];
  isLoading: boolean;
  initialQuery: string;
  currentModel: string;
}

// Declare global window extensions
declare global {
  interface Window {
    appState: AiChatAppState;
    receiveResponse: (content: string, isError: boolean, actualModel?: string) => void;
    setInitialQuery: (query: string) => void;
    setModel: (modelId: string) => void;
    webkit: {
      messageHandlers: {
        hammerspoon: {
          postMessage: (msg: { action: string; message?: string; model?: string }) => void;
        };
      };
    };
  }
}

// Post message to Hammerspoon
const postMessage = (action: string, message?: string, model?: string) => {
  window.webkit?.messageHandlers?.hammerspoon?.postMessage({ action, message, model });
};

// =============================================================================
// Components
// =============================================================================

// Loading indicator - fixed width "Thinking..." animation
const LoadingIndicator = () => {
  const [frame, setFrame] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setFrame(f => (f + 1) % 3);
    }, 400);
    return () => clearInterval(interval);
  }, []);

  // Always 3 chars: ".  " -> ".. " -> "..."
  const dots = '.'.repeat(frame + 1) + ' '.repeat(2 - frame);

  return (
    <div class="loading-indicator">
      <span class="loading-text">Thinking</span>
      <span class="loading-dots">{dots}</span>
    </div>
  );
};

// Single message component
const MessageComponent = ({ msg }: { msg: Message }) => {
  const className = `message ${msg.role}`;
  const showModel = msg.role === 'assistant' && msg.actualModel;

  return (
    <div class={`message-wrapper ${msg.role}`}>
      {showModel && (
        <div class="message-model">{msg.actualModel}</div>
      )}
      <div class={className}>
        <div class="message-content">{msg.content}</div>
      </div>
    </div>
  );
};

// Main App component
const App = () => {
  const [messages, setMessages] = useState<Message[]>(window.appState.messages);
  const [isLoading, setIsLoading] = useState(false);
  const [inputValue, setInputValue] = useState(window.appState.initialQuery || '');
  const [currentModel, setCurrentModel] = useState(window.appState.currentModel || 'openai/gpt-4o-mini');
  const [showModelSelector, setShowModelSelector] = useState(false);
  const [modelFilter, setModelFilter] = useState('');
  const messagesRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const modelInputRef = useRef<HTMLInputElement>(null);
  const msgIdCounterRef = useRef(0);

  // Get display name for current model
  const currentModelName = MODELS.find(m => m.id === currentModel)?.name || currentModel.split('/')[1];

  // Filter models with fuzzy search
  const filteredModels = MODELS.filter(m =>
    fuzzyMatch(m.name, modelFilter) || fuzzyMatch(m.id, modelFilter)
  );

  // Auto-scroll to bottom when messages change
  useEffect(() => {
    if (messagesRef.current && !showModelSelector) {
      messagesRef.current.scrollTop = messagesRef.current.scrollHeight;
    }
  }, [messages, isLoading, showModelSelector]);

  // Auto-submit initial query on mount
  useEffect(() => {
    const initialQuery = window.appState.initialQuery;
    if (initialQuery && initialQuery.trim()) {
      const userMsg: Message = {
        id: `msg-${++msgIdCounterRef.current}`,
        role: 'user',
        content: initialQuery.trim(),
      };
      setMessages([userMsg]);
      setInputValue('');
      setIsLoading(true);
      postMessage('send', initialQuery.trim());
    } else if (inputRef.current) {
      inputRef.current.focus();
    }
  }, []);

  // Focus model input when selector opens
  useEffect(() => {
    if (showModelSelector && modelInputRef.current) {
      modelInputRef.current.focus();
    } else if (!showModelSelector && inputRef.current) {
      inputRef.current.focus();
    }
  }, [showModelSelector]);

  // Expose functions to Hammerspoon
  useEffect(() => {
    window.receiveResponse = (content: string, isError: boolean, actualModel?: string) => {
      setIsLoading(false);
      const newMsg: Message = {
        id: `msg-${++msgIdCounterRef.current}`,
        role: isError ? 'error' : 'assistant',
        content,
        actualModel: actualModel || undefined,
      };
      setMessages(prev => [...prev, newMsg]);
      setTimeout(() => inputRef.current?.focus(), 50);
    };

    window.setInitialQuery = (query: string) => {
      setInputValue(query);
      if (inputRef.current) {
        inputRef.current.focus();
        inputRef.current.select();
      }
    };

    window.setModel = (modelId: string) => {
      setCurrentModel(modelId);
    };
  }, []);

  // Send message handler
  const sendMessage = useCallback(() => {
    const text = inputValue.trim();
    if (!text || isLoading) return;

    const userMsg: Message = {
      id: `msg-${++msgIdCounterRef.current}`,
      role: 'user',
      content: text,
    };
    setMessages(prev => [...prev, userMsg]);
    setInputValue('');
    setIsLoading(true);

    postMessage('send', text);
  }, [inputValue, isLoading]);

  // Handle key events on chat input
  const handleChatKeyDown = useCallback((e: KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  }, [sendMessage]);

  // Handle model selection
  const selectModel = useCallback((model: ModelOption) => {
    setCurrentModel(model.id);
    setShowModelSelector(false);
    setModelFilter('');
    postMessage('setModel', undefined, model.id);
  }, []);

  // Handle key events on model input
  const handleModelKeyDown = useCallback((e: KeyboardEvent) => {
    if (e.key === 'Escape') {
      e.preventDefault();
      e.stopPropagation();
      setShowModelSelector(false);
      setModelFilter('');
      return;
    }

    // Check for hotkey selection (only when filter is empty)
    if (!modelFilter) {
      const model = filteredModels.find(m => m.key === e.key);
      if (model) {
        e.preventDefault();
        selectModel(model);
        return;
      }
    }

    // Enter selects first filtered result
    if (e.key === 'Enter' && filteredModels.length > 0) {
      e.preventDefault();
      selectModel(filteredModels[0]);
    }
  }, [modelFilter, filteredModels, selectModel]);

  // Auto-resize textarea
  const handleInput = useCallback((e: Event) => {
    const target = e.target as HTMLTextAreaElement;
    setInputValue(target.value);
    target.style.height = 'auto';
    target.style.height = Math.min(target.scrollHeight, 120) + 'px';
  }, []);

  // Toggle model selector
  const toggleModelSelector = useCallback(() => {
    setShowModelSelector(prev => !prev);
    setModelFilter('');
  }, []);

  const hasMessages = messages.length > 0 || isLoading;

  // Global key handler for Shift+Space hotkey
  useEffect(() => {
    const handleGlobalKey = (e: KeyboardEvent) => {
      // ESC always closes
      if (e.key === 'Escape') {
        if (showModelSelector) {
          e.preventDefault();
          setShowModelSelector(false);
          setModelFilter('');
        } else {
          postMessage('close');
        }
        return;
      }

      // Shift+Space opens model selector (works from anywhere)
      if (e.key === ' ' && e.shiftKey && !showModelSelector) {
        e.preventDefault();
        setShowModelSelector(true);
        setModelFilter('');
      }
    };

    document.addEventListener('keydown', handleGlobalKey);
    return () => document.removeEventListener('keydown', handleGlobalKey);
  }, [showModelSelector]);

  return (
    <div class="chat-container">
      <div class="header">
        <span class="header-title">AI Chat</span>
        <span class="header-hint"><kbd>ESC</kbd> close</span>
      </div>

      <div class="content-area" ref={messagesRef}>
        {showModelSelector ? (
          <div class="model-list">
            {filteredModels.map(model => (
              <div
                key={model.id}
                class={`model-item ${model.id === currentModel ? 'active' : ''}`}
                onClick={() => selectModel(model)}
              >
                <span class="model-key">{model.key}</span>
                <span class="model-name">{model.name}</span>
                {model.id === currentModel && <span class="model-check">*</span>}
              </div>
            ))}
            {filteredModels.length === 0 && (
              <div class="model-empty">No models match "{modelFilter}"</div>
            )}
          </div>
        ) : (
          <>
            {!hasMessages && (
              <div class="empty-state">Type a message to start chatting</div>
            )}
            {messages.map(msg => (
              <MessageComponent key={msg.id} msg={msg} />
            ))}
            {isLoading && <LoadingIndicator />}
          </>
        )}
      </div>

      <div class="input-area">
        {showModelSelector ? (
          <input
            ref={modelInputRef}
            type="text"
            class="input-field model-search-input"
            placeholder="Search models..."
            value={modelFilter}
            onInput={(e) => setModelFilter((e.target as HTMLInputElement).value)}
            onKeyDown={handleModelKeyDown}
          />
        ) : (
          <textarea
            ref={inputRef}
            class="input-field chat-input"
            placeholder="Ask anything..."
            rows={1}
            value={inputValue}
            onInput={handleInput}
            onKeyDown={handleChatKeyDown}
            disabled={isLoading}
          />
        )}
        <div class="model-indicator" onClick={toggleModelSelector}>
          <span class="model-name-display">{currentModelName}</span>
        </div>
        {!showModelSelector && (
          <button
            class="send-btn"
            onClick={sendMessage}
            disabled={isLoading || !inputValue.trim()}
          >
            Send
          </button>
        )}
      </div>
    </div>
  );
};

// Mount app when DOM is ready
const mount = () => {
  const appEl = document.getElementById('app');
  if (appEl) {
    render(<App />, appEl);
  }
};

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', mount);
} else {
  mount();
}
