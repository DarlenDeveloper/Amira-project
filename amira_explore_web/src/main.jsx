import React from 'react';
import ReactDOM from 'react-dom/client';
import ExplorePage from './ExplorePage.jsx';
import { ShopProvider } from './context/ShopContext.jsx';
import './styles.css';

// Mounts into #explore-root — the same id you'd drop onto a WordPress page
// when embedding this build.
ReactDOM.createRoot(document.getElementById('explore-root')).render(
  <React.StrictMode>
    <ShopProvider>
      <ExplorePage />
    </ShopProvider>
  </React.StrictMode>,
);
