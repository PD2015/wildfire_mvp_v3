/**
 * Custom Service Worker Wrapper
 * 
 * Wraps Flutter's auto-generated service worker to add custom behaviors:
 * - Handles SKIP_WAITING message for immediate updates
 * - Enables update notifications
 */

// Import Flutter's service worker (no cache-busting needed, Flutter handles versioning)
self.importScripts('flutter_service_worker.js');

// Listen for SKIP_WAITING message from update prompt
self.addEventListener('message', function(event) {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    console.log('[Service Worker] Received SKIP_WAITING, activating immediately...');
    self.skipWaiting();
  }
});

// Claim clients immediately when service worker activates
self.addEventListener('activate', function(event) {
  console.log('[Service Worker] Activated, claiming clients...');
  event.waitUntil(self.clients.claim());
});

console.log('[Service Worker] Custom wrapper loaded');
