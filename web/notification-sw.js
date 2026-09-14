// Service Worker מינימלי, שהתפקיד היחיד שלו הוא "להיות פעיל" כדי
// שנוכל להציג דרכו התראות מערכת אמיתיות (registration.showNotification).
// לא עושה שום caching, לא מתערב ב-Flutter service worker.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

