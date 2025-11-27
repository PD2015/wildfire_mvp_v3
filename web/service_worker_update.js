/**
 * Service Worker Update Handler
 * 
 * Detects when a new service worker is available and prompts user to update.
 * This ensures users always get the latest version of the PWA with updated
 * theme colors, assets, and code.
 */

// Wait for the service worker to be ready
if ('serviceWorker' in navigator) {
  // Listen for service worker updates
  navigator.serviceWorker.addEventListener('controllerchange', function() {
    console.log('[PWA] New service worker activated, reloading page...');
    window.location.reload();
  });

  // Check for updates on page load
  navigator.serviceWorker.register('custom_service_worker.js').then(function(registration) {
    console.log('[PWA] Service Worker registered with scope:', registration.scope);

    // Check for updates every 60 seconds when app is active
    setInterval(function() {
      registration.update();
    }, 60000);

    // Listen for new service worker waiting to activate
    registration.addEventListener('updatefound', function() {
      const newWorker = registration.installing;
      
      newWorker.addEventListener('statechange', function() {
        if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
          // New service worker is installed but waiting to activate
          console.log('[PWA] New version available!');
          
          // Show update prompt to user
          showUpdatePrompt(newWorker);
        }
      });
    });
  }).catch(function(error) {
    console.error('[PWA] Service Worker registration failed:', error);
  });
}

/**
 * Show a material design snackbar prompting user to update
 */
function showUpdatePrompt(newWorker) {
  // Create snackbar container
  const snackbar = document.createElement('div');
  snackbar.id = 'update-snackbar';
  snackbar.style.cssText = `
    position: fixed;
    bottom: 16px;
    left: 50%;
    transform: translateX(-50%);
    background-color: #323232;
    color: white;
    padding: 14px 24px;
    border-radius: 4px;
    box-shadow: 0 3px 5px -1px rgba(0,0,0,.2), 0 6px 10px 0 rgba(0,0,0,.14), 0 1px 18px 0 rgba(0,0,0,.12);
    z-index: 9999;
    display: flex;
    align-items: center;
    gap: 16px;
    max-width: 568px;
    animation: slideUp 0.3s ease-out;
  `;

  // Add animation
  const style = document.createElement('style');
  style.textContent = `
    @keyframes slideUp {
      from {
        transform: translateX(-50%) translateY(100px);
        opacity: 0;
      }
      to {
        transform: translateX(-50%) translateY(0);
        opacity: 1;
      }
    }
  `;
  document.head.appendChild(style);

  // Message text
  const message = document.createElement('span');
  message.textContent = 'A new version is available!';
  message.style.flex = '1';

  // Update button
  const updateButton = document.createElement('button');
  updateButton.textContent = 'RELOAD';
  updateButton.style.cssText = `
    background: none;
    border: none;
    color: #1B6B61;
    font-weight: 500;
    cursor: pointer;
    padding: 8px 16px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    font-size: 14px;
  `;
  updateButton.onclick = function() {
    console.log('[PWA] User accepted update, activating new service worker...');
    
    // Tell the new service worker to skip waiting and take over
    newWorker.postMessage({ type: 'SKIP_WAITING' });
    
    // Remove snackbar
    snackbar.remove();
  };

  // Dismiss button
  const dismissButton = document.createElement('button');
  dismissButton.textContent = '✕';
  dismissButton.style.cssText = `
    background: none;
    border: none;
    color: white;
    cursor: pointer;
    padding: 8px;
    font-size: 18px;
    opacity: 0.7;
  `;
  dismissButton.onclick = function() {
    snackbar.remove();
  };

  snackbar.appendChild(message);
  snackbar.appendChild(updateButton);
  snackbar.appendChild(dismissButton);
  document.body.appendChild(snackbar);

  // Auto-dismiss after 10 seconds
  setTimeout(function() {
    if (snackbar.parentNode) {
      snackbar.remove();
    }
  }, 10000);
}
