import { defineStore } from 'pinia';
import api from '../api/axios';
import { useToast } from 'vue-toastification';

const toast = useToast();

export const useCustomerStore = defineStore('customer', {
    state: () => ({
        categories: [],
        products: [], // Popular/All
        recommendedProducts: [], // Specifically for Home "Recommended"
        banners: [],
        cart: JSON.parse(localStorage.getItem('customer_cart')) || [],
        member: null, // Logged in member
        loading: false,
        error: null,
        orderType: localStorage.getItem('orderType') || 'pickup', // Default to stored or pickup
        settings: JSON.parse(localStorage.getItem('app_settings')) || null, // Store info
        selectedVoucher: null,
        promos: [], // Cache promos
        rewards: [],
        myVouchers: [],
        favorites: JSON.parse(localStorage.getItem('customer_favorites')) || [],
    }),

    getters: {
        cartCount: (state) => state.cart.reduce((total, item) => total + item.quantity, 0),
        
        cartTotal: (state) => {
            return state.cart.reduce((total, item) => {
                let itemTotal = item.price * item.quantity;
                if (item.toppings && item.toppings.length) {
                    return total + (item.unit_price * item.quantity);
                }
                return total + itemTotal;
            }, 0);
        },
        
        discountAmount: (state) => {
            if (!state.selectedVoucher) return 0;
            // Re-use getter logic or state.cart check? Can use this.cartTotal inside getter? 
            // In pinia: (state) => { const subtotal = state.cart... } OR using other getters:
            // "getters receive the state as the first argument"
            // "you can access other getters via `this`" (but not in arrow function effectively if context lost, better pass standard func or use state logic).
            // Pinia: getters: { doubleCount: (state) => state.count * 2, doublePlusOne() { return this.doubleCount + 1 } }
            
            // Let's re-calculate subtotal or define separate subtotal getter. cartTotal IS the subtotal.
            // Since 'this' context is tricky in arrow functions in some specific setups, I will just re-reduce or convert cartTotal to non-arrow?
            // Existing `cartTotal` is arrow. I'll stick to arrow and re-calc to be safe/simple.
            
            const subtotal = state.cart.reduce((total, item) => {
                if (item.toppings && item.toppings.length) {
                    return total + (item.unit_price * item.quantity);
                }
                return total + (item.price * item.quantity);
            }, 0);

            // Check for reward voucher (free_product)
            if (state.selectedVoucher.reward) {
                const reward = state.selectedVoucher.reward;
                if (reward.type === 'free_product' && reward.product_id) {
                     const cartItem = state.cart.find(item => item.id == reward.product_id);
                     if (cartItem) {
                         return cartItem.unit_price; 
                     }
                     return 0; 
                }
            }

            if (state.selectedVoucher.min_purchase && subtotal < state.selectedVoucher.min_purchase) return 0;

            if (state.selectedVoucher.type === 'fixed') {
                return parseFloat(state.selectedVoucher.value);
            } else {
                 return Math.round(subtotal * (parseFloat(state.selectedVoucher.value) / 100));
            }
        },

        taxRate: (state) => state.settings?.tax_rate ? parseFloat(state.settings.tax_rate) : 11,
        
        taxAmount() { // switch to function to access other getters via `this`?
            // Actually in Pinia defineStore options API style, `this` works.
            const rate = this.taxRate;
            const taxable = Math.max(0, this.cartTotal - this.discountAmount);
            return Math.round(taxable * (rate / 100));
        },
        
        finalTotal() {
            return Math.max(0, this.cartTotal - this.discountAmount + this.taxAmount);
        },
    },

    actions: {
        async fetchCategories() {
            try {
                const response = await api.get('/public/categories');
                const rawData = response.data?.data || response.data || [];
                this.categories = Array.isArray(rawData) ? rawData : [];
            } catch (err) {
                console.error('Error fetching categories:', err);
            }
        },

        async fetchProducts(params = {}) {
            this.loading = true;
            try {
                const response = await api.get('/public/products', { params });
                const resData = response.data?.data || response.data || {};
                this.products = resData.data || resData || [];
            } catch (err) {
                console.error('Error fetching products:', err);
            } finally {
                this.loading = false;
            }
        },

        async fetchRecommendedProducts() {
            try {
                const response = await api.get('/public/products', { 
                    params: { is_recommended: 1, per_page: 10 } 
                });
                const resData = response.data?.data || response.data || {};
                this.recommendedProducts = resData.data || resData || [];
            } catch (err) {
                console.error('Error fetching recommended products:', err);
            }
        },

        async fetchUpsellProducts() {
            try {
                const response = await api.get('/public/products', { 
                    params: { is_upsell: 1, per_page: 10 } 
                });
                const resData = response.data?.data || response.data || {};
                return resData.data || resData || [];
            } catch (err) {
                console.error('Error fetching upsell products:', err);
                return [];
            }
        },
        
        async fetchPromos() {
            try {
                const response = await api.get('/public/promos');
                const rawData = response.data?.data || response.data || [];
                this.promos = Array.isArray(rawData) ? rawData : [];
                return this.promos;
            } catch (err) {
                console.error('Error fetching promos:', err);
                return [];
            }
        },

        async fetchBanners() {
            try {
                const response = await api.get('/public/banners');
                const rawData = response.data?.data || response.data || [];
                this.banners = Array.isArray(rawData) ? rawData : [];
            } catch (err) {
                console.error('Error fetching banners:', err);
            }
        },

        async fetchProduct(id) {
            try {
                const response = await api.get(`/public/products/${id}`);
                return response.data?.data || response.data || null;
            } catch (err) {
                console.error('Error fetching product:', err);
                return null;
            }
        },

        addToCart(product, options = {}) {
            const { quantity = 1, modifiers = [], notes = '' } = options;
            
            // Calculate base price + additions from dynamic modifiers
            let unitPrice = parseFloat(product.price);
            
            // Add modifier option prices
            if (modifiers && modifiers.length > 0) {
                modifiers.forEach(mod => {
                    unitPrice += parseFloat(mod.price) || 0;
                });
            }

            // Create unique ID for cart item (composite key from modifiers)
            let cartId = product.id;
            if (modifiers && modifiers.length > 0) {
                const modifierKey = modifiers.map(m => `${m.modifier_id}:${m.option_id}`).sort().join('-');
                cartId = `${product.id}-${modifierKey}`;
            }

            const existingItem = this.cart.find(item => item.cartId === cartId);

            if (existingItem) {
                existingItem.quantity += quantity;
            } else {
                this.cart.push({
                    cartId,
                    id: product.id,
                    name: product.name,
                    image_url: product.image_url,
                    price: parseFloat(product.price), // Base price
                    unit_price: unitPrice, // Price with modifiers
                    quantity,
                    modifiers, // Array of { modifier_id, modifier_name, option_id, option_name, price }
                    notes,
                });
            }
            
            localStorage.setItem('customer_cart', JSON.stringify(this.cart));
            return cartId;
        },

        updateQuantity(cartId, delta) {
            const item = this.cart.find(item => item.cartId === cartId);
            if (item) {
                item.quantity += delta;
                if (item.quantity <= 0) {
                    this.removeFromCart(cartId);
                }
                localStorage.setItem('customer_cart', JSON.stringify(this.cart));
            }
        },
        
        removeFromCart(cartId) {
            const index = this.cart.findIndex(item => item.cartId === cartId);
            if (index !== -1) {
                this.cart.splice(index, 1);
                localStorage.setItem('customer_cart', JSON.stringify(this.cart));
            }
        },

        async submitOrder(paymentDetails) {
            this.loading = true;
            try {
                const payload = {
                    items: this.cart.map(item => ({
                        product_id: item.id,
                        quantity: item.quantity,
                        modifiers: item.modifiers || [], // Dynamic modifiers array
                        note: item.modifiers?.length 
                            ? `${item.modifiers.map(m => m.option_name).join(', ')}. ${item.notes || ''}`
                            : `${item.notes || ''}`
                    })),
                    customer_id: this.member?.id || null, // If member logged in
                    customer_name: paymentDetails.customerName || (this.member ? this.member.name : 'Guest'),
                    customer_phone: paymentDetails.customerPhone || null,
                    order_type: paymentDetails.orderType || this.orderType || 'pickup_app',
                    payment_method: paymentDetails.method,
                    payment_status: 'paid', // Simulate successful payment
                    note: paymentDetails.note || '',
                    customer_voucher_id: this.selectedVoucher?.code?.startsWith('RWD') ? this.selectedVoucher.id : null,
                    discount_id: this.selectedVoucher?.code?.startsWith('RWD') ? null : this.selectedVoucher?.id, 
                };
                
                // If it's a reward voucher, we use customer_voucher_id. If it's a normal discount, we use discount_id.
                // Logic: Reward vouchers have 'reward' relationship or specific code pattern. 
                // Better: Check property.
                if (this.selectedVoucher?.reward) {
                    payload.customer_voucher_id = this.selectedVoucher.id;
                    payload.discount_id = null;
                } else if (this.selectedVoucher) {
                     payload.discount_id = this.selectedVoucher.id;
                     payload.customer_voucher_id = null;
                }

                const response = await api.post('/public/orders', payload);
                
                this.cart = [];
                localStorage.removeItem('customer_cart');
                // Handle different response structures (Resource vs Json)
                const data = response.data;
                const orderData = data.order || data.data || data;
                
                return orderData || true;
            } catch (err) {
                console.error("Order failed", err);
                toast.error(err.response?.data?.message || "Failed to place order");
                return false;
            } finally {
                this.loading = false;
            }
        },
        
        loginAsMember(memberData) {
            this.member = memberData;
        },

        setOrderType(type) {
            this.orderType = type;
            localStorage.setItem('orderType', type);
        },

        async fetchSettings() {
            try {
                const response = await api.get('/public/settings');
                const resData = response.data?.data || response.data || {};
                this.settings = resData; 
                localStorage.setItem('app_settings', JSON.stringify(this.settings));
            } catch (err) {
                console.error('Error fetching settings:', err);
            }
        },

        applyVoucher(voucher) {
            this.selectedVoucher = voucher;
        },

        removeVoucher() {
            this.selectedVoucher = null;
        },

        async fetchRewards() {
            try {
                const response = await api.get('/public/rewards');
                const rawData = response.data?.data || response.data || [];
                this.rewards = Array.isArray(rawData) ? rawData : [];
            } catch (err) {
                console.error('Error fetching rewards:', err);
            }
        },

        async redeemReward(rewardId) {
            this.loading = true;
            try {
                const response = await api.post(`/public/member/rewards/${rewardId}/redeem`);
                const resData = response.data?.data || response.data || {};
                // Update points balance
                if (this.member) {
                    // response.data.remaining_points
                    this.member.points_balance = resData.remaining_points;
                    // Also refresh my vouchers if needed
                    await this.fetchMyVouchers();
                }
                return true;
            } catch (err) {
                console.error('Redeem failed:', err);
                toast.error(err.response?.data?.message || 'Gagal menukar poin');
                return false;
            } finally {
                this.loading = false;
            }
        },

        async fetchMyVouchers() {
            // Token handled by axios interceptor
            try {
                const response = await api.get('/public/member/vouchers');
                const rawData = response.data?.data || response.data || [];
                this.myVouchers = Array.isArray(rawData) ? rawData : [];
            } catch (err) {
                console.error('Error fetching my vouchers:', err);
            }
        },
        
        async fetchMyVoucher(id) {
            try {
                const response = await api.get(`/public/member/vouchers/${id}`);
                return response.data?.data || response.data || null;
            } catch (err) {
                console.error('Error fetching voucher:', err);
                return null;
            }
        },

        toggleFavorite(product) {
            const index = this.favorites.findIndex(f => f.id === product.id);
            if (index === -1) {
                this.favorites.push(product);
                toast.success("Produk Favorit berhasil ditambahkan", {
                    position: "top-left",
                    toastClassName: "customer-toast"
                });
                localStorage.setItem('customer_favorites', JSON.stringify(this.favorites));
                return true; // Added
            } else {
                this.favorites.splice(index, 1);
                toast.info("Produk dihapus dari favorit", {
                    position: "top-left",
                    toastClassName: "customer-toast"
                });
                localStorage.setItem('customer_favorites', JSON.stringify(this.favorites));
                return false; // Removed
            }
        }
    }
});
