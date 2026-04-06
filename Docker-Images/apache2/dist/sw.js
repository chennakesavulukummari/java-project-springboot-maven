// Cloud Binary - Service Worker for Performance Optimization
const CACHE_NAME = 'cloud-binary-v1.0';
const urlsToCache = [
  '/',
  '/aws-devops-content',
  '/azure-devops-content', 
  '/multi-cloud-devops',
  '/finops-content',
  '/cb-white-logo.png',
  '/placeholder.svg',
  '/robots.txt',
  '/sitemap.xml'
];

// Install event - cache resources
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - serve from cache with network fallback
self.addEventListener('fetch', event => {
  // Skip cross-origin requests
  if (!event.request.url.startsWith(self.location.origin)) {
    return;
  }

  // Network first strategy for API calls
  if (event.request.url.includes('/api/')) {
    event.respondWith(
      fetch(event.request)
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // Cache first strategy for static assets
  if (event.request.url.includes('.js') || 
      event.request.url.includes('.css') || 
      event.request.url.includes('.png') || 
      event.request.url.includes('.jpg') || 
      event.request.url.includes('.svg')) {
    event.respondWith(
      caches.match(event.request)
        .then(response => {
          return response || fetch(event.request);
        })
    );
    return;
  }

  // Stale while revalidate for HTML pages
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        const fetchPromise = fetch(event.request).then(fetchResponse => {
          caches.open(CACHE_NAME).then(cache => {
            cache.put(event.request, fetchResponse.clone());
          });
          return fetchResponse;
        });
        return response || fetchPromise;
      })
  );
});