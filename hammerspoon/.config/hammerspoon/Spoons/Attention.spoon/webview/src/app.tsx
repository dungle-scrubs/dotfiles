import { render } from 'preact';
import { useState, useEffect, useRef, useCallback } from 'preact/hooks';

// Types
interface Message {
  id: string;
  user: string;
  time: string;
  text: string;
  replyCount: number;
  threadTs: string;
  isReply: boolean;
}

interface AppState {
  messages: Message[];
  viewMode: 'history' | 'thread';
  isLoadingMore: boolean;
  isInitialLoading: boolean;
  showChannelUp: boolean;
}

// Declare global window extensions
declare global {
  interface Window {
    appState: AppState;
    updateMessages: (messages: Message[], prepend?: boolean) => void;
    setLoading: (loading: boolean) => void;
    webkit: {
      messageHandlers: {
        hammerspoon: {
          postMessage: (action: string) => void;
        };
      };
    };
  }
}

// Post message to Hammerspoon
const postMessage = (action: string) => {
  window.webkit?.messageHandlers?.hammerspoon?.postMessage(action);
};

// Format message text with links and mentions
const formatText = (text: string): string => {
  if (!text) return '';
  // Convert markdown-style links to HTML
  text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="#" class="link" data-url="$2">$1</a>');
  // Make plain URLs clickable (but not ones we already processed)
  text = text.replace(/(^|[^"'])(https?:\/\/[^\s<]+)/g, (_, prefix, url) => {
    return prefix + '<a href="#" class="link" data-url="' + url + '">' + url + '</a>';
  });
  // Style @mentions
  text = text.replace(/@([a-zA-Z0-9._-]+)/g, '<span class="mention">@$1</span>');
  // Convert newlines to <br>
  text = text.replace(/\n/g, '<br>');
  return text;
};

// Message component
const MessageComponent = ({ msg, onThreadClick }: { msg: Message; onThreadClick: (ts: string) => void }) => {
  const showReplies = window.appState.viewMode === 'history' && msg.replyCount > 0;
  const className = msg.isReply ? 'message reply' : 'message';

  return (
    <div class={className} data-id={msg.id}>
      <div class="message-header">
        <span class="sender">{msg.user}</span>
        <span class="time">{msg.time}</span>
      </div>
      <div
        class="message-text"
        dangerouslySetInnerHTML={{ __html: formatText(msg.text) }}
      />
      {showReplies && (
        <span class="thread-link" onClick={() => onThreadClick(msg.threadTs)}>
          {msg.replyCount} replies
        </span>
      )}
    </div>
  );
};

// Thread separator
const ThreadSeparator = ({ count }: { count: number }) => (
  <div class="thread-separator">Thread ({count} replies)</div>
);

// Main App component
const App = () => {
  const [messages, setMessages] = useState<Message[]>(window.appState.messages);
  const [isLoading, setIsLoading] = useState(false);
  const [isInitialLoading, setIsInitialLoading] = useState(window.appState.isInitialLoading);
  const [loadingDots, setLoadingDots] = useState('.');
  const contentRef = useRef<HTMLDivElement>(null);
  const messagesContainerRef = useRef<HTMLDivElement>(null);

  // Animate loading dots
  useEffect(() => {
    if (!isInitialLoading) return;
    const interval = setInterval(() => {
      setLoadingDots(d => {
        if (d === '.') return '..';
        if (d === '..') return '...';
        return '.';
      });
    }, 300);
    return () => clearInterval(interval);
  }, [isInitialLoading]);

  // Expose update function globally
  useEffect(() => {
    window.updateMessages = (newMessages: Message[], prepend = false) => {
      if (prepend && contentRef.current && messagesContainerRef.current) {
        // Calculate remaining time to reach 750ms minimum
        const elapsed = Date.now() - loadingStartTime.current;
        const minDelay = 750;
        const remainingDelay = Math.max(0, minDelay - elapsed);

        setTimeout(() => {
          const content = contentRef.current;
          const container = messagesContainerRef.current;
          if (!content || !container) return;

          // Measure before
          const scrollHeightBefore = content.scrollHeight;
          const scrollTopBefore = content.scrollTop;

          // Create HTML for new messages
          const html = newMessages.map(msg => {
            const className = msg.isReply ? 'message reply' : 'message';
            const showReplies = window.appState.viewMode === 'history' && msg.replyCount > 0;
            return `<div class="${className}" data-id="${msg.id}">
              <div class="message-header">
                <span class="sender">${msg.user}</span>
                <span class="time">${msg.time}</span>
              </div>
              <div class="message-text">${formatText(msg.text)}</div>
              ${showReplies ? `<span class="thread-link" data-thread-ts="${msg.threadTs}">${msg.replyCount} replies</span>` : ''}
            </div>`;
          }).join('');

          // Insert at the beginning
          container.insertAdjacentHTML('afterbegin', html);

          // Restore scroll position
          const scrollHeightAfter = content.scrollHeight;
          const heightDiff = scrollHeightAfter - scrollHeightBefore;
          content.scrollTop = scrollTopBefore + heightDiff;

          // Hide loading indicator and stop animation
          const loader = content.querySelector('.loading-indicator');
          if (loader) {
            loader.classList.remove('visible');
            if ((loader as any)._animateId) {
              clearInterval((loader as any)._animateId);
              (loader as any)._animateId = null;
            }
          }
          window.appState.isLoadingMore = false;
        }, remainingDelay);
      } else {
        // Initial load or full replacement
        setMessages(newMessages);
        setIsLoading(false);
        setIsInitialLoading(false);
        window.appState.isLoadingMore = false;
        window.appState.isInitialLoading = false;
        // Scroll to bottom after initial load
        requestAnimationFrame(() => {
          const content = contentRef.current;
          if (content) content.scrollTop = content.scrollHeight;
        });
      }
    };

    window.setLoading = (loading: boolean) => {
      setIsLoading(loading);
    };
  }, []);

  // Initial scroll to bottom (only if not keeping position)
  useEffect(() => {
    const content = contentRef.current;
    // @ts-ignore - keepScrollPosition is injected by Lua
    if (content && !window.keepScrollPosition) {
      content.scrollTop = content.scrollHeight;
    }
  }, []);

  // Track when loading started for minimum delay
  const loadingStartTime = useRef<number>(0);

  // Animated loading dots
  const startLoadingAnimation = useCallback(() => {
    const content = contentRef.current;
    if (!content) return;
    const loader = content.querySelector('.loading-indicator');
    if (!loader) return;

    loadingStartTime.current = Date.now();
    loader.classList.add('visible');
    let dotCount = 0;
    const animateId = setInterval(() => {
      dotCount = (dotCount % 3) + 1;
      const dots = '.'.repeat(dotCount) + ' '.repeat(3 - dotCount);
      loader.textContent = 'Loading' + dots;
    }, 300);
    // Store interval ID on the element for cleanup
    (loader as any)._animateId = animateId;
  }, []);

  // Scroll event for loading more (ignores bounce)
  const handleScroll = useCallback((e: Event) => {
    const content = e.target as HTMLDivElement;
    // Ignore negative scrollTop (bounce zone only)
    if (content.scrollTop < 0) return;
    // Trigger when at or near top
    if (content.scrollTop < 50 && !window.appState.isLoadingMore) {
      window.appState.isLoadingMore = true;
      startLoadingAnimation();
      postMessage('loadMore');
    }
  }, [startLoadingAnimation]);

  // Thread click handler
  const handleThreadClick = useCallback((threadTs: string) => {
    postMessage('thread:' + threadTs);
  }, []);

  // Link click handler
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      const link = (e.target as HTMLElement).closest('a.link');
      if (link) {
        e.preventDefault();
        const url = link.getAttribute('data-url');
        if (url) postMessage('openUrl:' + url);
      }
    };
    document.addEventListener('click', handleClick);
    return () => document.removeEventListener('click', handleClick);
  }, []);

  // Render messages based on view mode
  const renderMessages = () => {
    if (window.appState.viewMode === 'thread' && messages.length > 1) {
      return (
        <>
          <MessageComponent msg={messages[0]} onThreadClick={handleThreadClick} />
          <ThreadSeparator count={messages.length - 1} />
          {messages.slice(1).map(msg => (
            <MessageComponent key={msg.id} msg={{ ...msg, isReply: true }} onThreadClick={handleThreadClick} />
          ))}
        </>
      );
    }
    return messages.map(msg => (
      <MessageComponent key={msg.id} msg={msg} onThreadClick={handleThreadClick} />
    ));
  };

  return (
    <div class="content" id="content" ref={contentRef} onScroll={handleScroll}>
      <div class="loading-indicator">
        Loading.
      </div>
      {isInitialLoading ? (
        <div class="initial-loading">Loading{loadingDots}</div>
      ) : (
        <div ref={messagesContainerRef}>
          {renderMessages()}
        </div>
      )}
    </div>
  );
};

// Keyboard handling (outside React for performance)
let lastKeyTime = 0;
let lastKey = '';

document.addEventListener('keydown', (e) => {
  const content = document.getElementById('content');
  if (!content) return;

  const scrollAmount = 60;
  const pageAmount = content.clientHeight * 0.8;
  const now = Date.now();

  // Handle gg (go to top)
  if (e.key === 'g' && !e.shiftKey) {
    if (lastKey === 'g' && (now - lastKeyTime) < 500) {
      content.scrollTop = 0;
      lastKey = '';
      e.preventDefault();
      return;
    }
    lastKey = 'g';
    lastKeyTime = now;
    e.preventDefault();
    return;
  }

  // Handle G (go to bottom)
  if (e.key === 'G' && e.shiftKey) {
    content.scrollTop = content.scrollHeight;
    e.preventDefault();
    return;
  }

  lastKey = '';

  switch (e.key) {
    case 'j':
      content.scrollTop += scrollAmount;
      e.preventDefault();
      break;
    case 'k':
      content.scrollTop -= scrollAmount;
      e.preventDefault();
      break;
    case 'd':
      if (e.ctrlKey) {
        content.scrollTop += pageAmount;
        e.preventDefault();
      }
      break;
    case 'u':
      if (e.ctrlKey) {
        content.scrollTop -= pageAmount;
        e.preventDefault();
      } else if (!e.metaKey) {
        console.log('[app.tsx] u pressed, showChannelUp=' + window.appState.showChannelUp + ', viewMode=' + window.appState.viewMode);
        if (window.appState.showChannelUp) {
          postMessage('channelUp');
          e.preventDefault();
        }
      }
      break;
    case 'b':
      postMessage('back');
      e.preventDefault();
      break;
    case 'O':
      postMessage('openSlack');
      e.preventDefault();
      break;
    case 'Escape':
      postMessage('back');
      e.preventDefault();
      break;
  }
});

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
