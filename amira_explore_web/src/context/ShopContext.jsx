import { createContext, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { watchAuth, isFullAccount } from '../services/auth.js';
import { watchProducts, categoriesOf } from '../services/products.js';
import {
  watchCart,
  watchFavourites,
  addToCart as addToCartSvc,
  setQty as setQtySvc,
  removeFromCart as removeFromCartSvc,
  clearCart as clearCartSvc,
  setFavourite as setFavouriteSvc,
} from '../services/cart.js';

const ShopContext = createContext(null);

/**
 * Single source of truth for the shop: the (anonymous-or-full) user, the live
 * catalogue, and the user's cart + favourites. Re-subscribes cart/favourites
 * whenever the uid changes (e.g. anonymous → upgraded account).
 */
export function ShopProvider({ children }) {
  const [user, setUser] = useState(null);
  const [authReady, setAuthReady] = useState(false);

  const [products, setProducts] = useState([]);
  const [productsLoading, setProductsLoading] = useState(true);
  const [productsError, setProductsError] = useState(null);

  const [cart, setCart] = useState([]);
  const [favourites, setFavourites] = useState(new Set());

  // Auth — resolves to an anonymous user on first load.
  useEffect(() => {
    return watchAuth((u, err) => {
      setUser(u);
      setAuthReady(true);
      if (err) setProductsError(err);
    });
  }, []);

  // Live catalogue (needs a signed-in user; waits for auth to resolve).
  useEffect(() => {
    if (!user) return undefined;
    setProductsLoading(true);
    const unsub = watchProducts(
      (list) => {
        setProducts(list);
        setProductsLoading(false);
        setProductsError(null);
      },
      (err) => {
        console.error('[Amira] Products read failed:', err?.code, err?.message);
        setProductsError(err);
        setProductsLoading(false);
      },
    );
    return unsub;
  }, [user?.uid]);

  // Cart + favourites for the current uid.
  useEffect(() => {
    if (!user) {
      setCart([]);
      setFavourites(new Set());
      return undefined;
    }
    const unsubCart = watchCart(user.uid, setCart);
    const unsubFav = watchFavourites(user.uid, setFavourites);
    return () => {
      unsubCart();
      unsubFav();
    };
  }, [user?.uid]);

  const categories = useMemo(() => categoriesOf(products), [products]);

  const cartCount = useMemo(
    () => cart.reduce((s, l) => s + l.qty, 0),
    [cart],
  );
  const cartSubtotal = useMemo(
    () => cart.reduce((s, l) => s + l.value * l.qty, 0),
    [cart],
  );

  // ── Actions (no-ops until a uid exists) ───────────────────────────────────
  const requireUid = () => user?.uid ?? null;

  const actions = useMemo(
    () => ({
      addToCart: (product, qty = 1) => {
        const uid = requireUid();
        return uid ? addToCartSvc(uid, product, qty) : Promise.resolve();
      },
      setQty: (productId, qty) => {
        const uid = requireUid();
        return uid ? setQtySvc(uid, productId, qty) : Promise.resolve();
      },
      removeFromCart: (productId) => {
        const uid = requireUid();
        return uid ? removeFromCartSvc(uid, productId) : Promise.resolve();
      },
      clearCart: () => {
        const uid = requireUid();
        return uid ? clearCartSvc(uid) : Promise.resolve();
      },
      toggleFavourite: (productId) => {
        const uid = requireUid();
        if (!uid) return Promise.resolve();
        return setFavouriteSvc(uid, productId, !favourites.has(productId));
      },
    }),
    // favourites is read inside toggleFavourite; user.uid gates the rest.
    [user?.uid, favourites],
  );

  const value = {
    user,
    authReady,
    hasAccount: isFullAccount(user),
    products,
    productsLoading,
    productsError,
    categories,
    cart,
    cartCount,
    cartSubtotal,
    favourites,
    ...actions,
  };

  return <ShopContext.Provider value={value}>{children}</ShopContext.Provider>;
}

export function useShop() {
  const ctx = useContext(ShopContext);
  if (!ctx) throw new Error('useShop must be used within a ShopProvider');
  return ctx;
}
