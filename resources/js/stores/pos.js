import { defineStore } from 'pinia';
import api from '../api/axios';

export const usePosStore = defineStore('pos', {
    state: () => ({
        products: [],
        categories: [],
        cart: [],
        customers: [], 
        selectedCustomer: null,
        orderType: 'Dine In',
        loading: false,
        shift: null, 
        settings: JSON.parse(localStorage.getItem('pos_settings')) || {
            tax_rate: 11, 
            store_name: null 
        },
        error: null,
        pagination: {
            current_page: 1,
            last_page: 1,
            per_page: 50, 
            total: 0
        },
        pendingOrderCount: 0,
        pollingInterval: null,
        
        // Discount Support
        discounts: [],
        activeDiscount: null
    }),

    getters: {
        cartItems: (state) => state.cart,
        
        subTotal: (state) => {
            return state.cart.reduce((sum, item) => sum + (item.unit_price * item.quantity), 0);
        },
        
        // Calculate Discount Amount
        discountAmount: (state) => {
            if (!state.activeDiscount) return 0;
            
            // Validate minimum purchase
            if (state.activeDiscount.min_purchase && state.subTotal < state.activeDiscount.min_purchase) {
                return 0; // Or better, we could automatically remove it, but returning 0 is safer for calculation
            }
            
            if (state.activeDiscount.type === 'fixed') {
                return Math.min(parseFloat(state.activeDiscount.value), state.subTotal);
            } else if (state.activeDiscount.type === 'percentage') {
                return state.subTotal * (parseFloat(state.activeDiscount.value) / 100);
            }
            return 0;
        },
        
        tax: (state) => {
            const rate = parseFloat(state.settings.tax_rate) || 0;
            // Tax is usually calculated on subtotal after discount
            const taxableAmount = Math.max(0, state.subTotal - state.discountAmount);
            return taxableAmount * (rate / 100);
        },
        
        grandTotal: (state) => {
            return Math.max(0, state.subTotal - state.discountAmount + state.tax);
        }
    },

    actions: {
        async fetchSettings() {
            try {
                const response = await api.get('/settings');
                const resData = response.data?.data || response.data || {};
                // Response is { key: value, ... } object based on Controller
                this.settings = { ...this.settings, ...resData };
                localStorage.setItem('pos_settings', JSON.stringify(this.settings));
            } catch (err) {
                console.error('Error fetching settings:', err);
            }
        },

        async fetchCategories() {
            try {
                const response = await api.get('/admin/categories');
                // Filter out any null/undefined values to prevent runtime errors
                const resData = response.data?.data || response.data || [];
                const data = Array.isArray(resData) ? resData : [];
                this.categories = data.filter(cat => cat != null);
            } catch (err) {
                console.error('Error fetching categories:', err);
                this.error = 'Failed to load categories';
            }
        },

        async searchCustomers(query) {
            if (!query) {
                this.customers = [];
                return;
            }
            try {
                const response = await api.get(`/admin/customers?search=${query}`);
                const resData = response.data?.data || response.data || {};
                this.customers = resData.data || resData || [];
            } catch (err) {
                console.error('Error searching customers:', err);
            }
        },

        selectCustomer(customer) {
            this.selectedCustomer = customer;
            this.customers = []; 
        },
        
        clearCustomer() {
            this.selectedCustomer = null;
        },

        setOrderType(type) {
            this.orderType = type;
        },

        async fetchProducts(params = {}) {
            this.loading = true;
            try {
                const { category_id, search, page = 1 } = params;
                const queryParams = new URLSearchParams();
                
                if (category_id) queryParams.append('category_id', category_id);
                if (search) queryParams.append('search', search);
                queryParams.append('page', page);
                queryParams.append('per_page', this.pagination.per_page || 50);

                const response = await api.get(`/admin/products?${queryParams.toString()}`);
                
                // Handle nested API response from ApiResponse trait
                const apiData = response.data?.data || response.data || {};
                // Filter out any null/undefined values to prevent runtime errors
                const rawData = apiData.data ?? apiData ?? [];
                const productsData = Array.isArray(rawData) ? rawData : [];
                this.products = productsData.filter(product => product != null);
                this.pagination = {
                    current_page: apiData.current_page ?? this.pagination.current_page,
                    last_page: apiData.last_page ?? this.pagination.last_page,
                    per_page: apiData.per_page ?? this.pagination.per_page ?? 50,
                    total: apiData.total ?? this.pagination.total
                };
            } catch (err) {
                console.error('Error fetching products:', err);
                this.error = 'Failed to load products';
            } finally {
                this.loading = false;
            }
        },

        addToCart(product, options = {}) {
            const { quantity = 1, modifiers = [], note = '' } = options;
            
            // Calculate unit price with modifiers
            let unitPrice = parseFloat(product.price);
            if (modifiers && modifiers.length > 0) {
                modifiers.forEach(mod => {
                    unitPrice += parseFloat(mod.price) || 0;
                });
            }

            // Create unique ID for cart item
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
                    id: product.id, // Keep original product ID for backend
                    name: product.name,
                    image_url: product.image_url,
                    price: parseFloat(product.price), // Base price
                    unit_price: unitPrice, // Price with modifiers
                    quantity,
                    modifiers, 
                    note
                });
            }
        },

        removeFromCart(cartId) {
            const index = this.cart.findIndex(item => item.cartId === cartId);
            if (index !== -1) {
                this.cart.splice(index, 1);
            }
        },

        updateQuantity(cartId, quantity) {
            const item = this.cart.find(item => item.cartId === cartId);
            if (item) {
                if (quantity <= 0) {
                    this.removeFromCart(cartId);
                } else {
                    item.quantity = quantity;
                }
            }
        },

        async submitOrder(paymentDetails) {
            this.loading = true;
            this.error = null;
            
            try {
                // Prepare Payload
                const payload = {
                    items: this.cart.map(item => ({
                        product_id: item.id,
                        quantity: item.quantity,
                        note: item.note || '',
                        modifiers: item.modifiers || []
                    })),
                    customer_id: this.selectedCustomer?.id || null,
                    customer_name: this.selectedCustomer?.name || null,
                    order_type: this.orderType.toLowerCase().replace(' ', '_'), // 'Dine In' -> 'dine_in'
                    payment_method: paymentDetails.method,
                    payment_status: 'paid', // Assuming immediate payment for POS
                    
                    // Discount Info
                    discount_id: this.activeDiscount?.id || null,
                    discount_amount: this.activeDiscount ? this.discountAmount : 0
                };                let response;
                if (this.pendingOrderId) {
                    // Update existing order
                    response = await api.put(`/orders/${this.pendingOrderId}`, payload);
                } else {
                    // Create new order
                    response = await api.post('/orders', payload);
                }
                
                return response.data?.data || response.data || {};

            } catch (err) {
                console.error('Order submission failed:', err);
                this.error = err.response?.data?.message || 'Failed to process order';
                throw err;
            } finally {
                this.loading = false;
            }
        },
        
        clearCart() {
            this.cart = [];
            this.pendingOrderId = null;
            this.activeDiscount = null;
        },

        setPendingOrder(orderId) {
            this.pendingOrderId = orderId;
        },

        // Shift Management
        async fetchCurrentShift() {
            try {
                const response = await api.get('/admin/shifts/current');
                const raw = response.data;
                // Correctly handle "data: null" vs "no data key"
                const resData = (raw && typeof raw === 'object' && 'data' in raw) ? raw.data : raw;
                
                // Ensure we don't set an empty string or empty object as a shift
                if (!resData || (typeof resData === 'object' && Object.keys(resData).length === 0)) {
                    this.shift = null;
                } else {
                    this.shift = resData;
                }
                return this.shift;
            } catch (err) {
                console.error('Error fetching shift:', err);
                return null;
            }
        },

        async startShift(startingCash) {
            this.loading = true;
            try {
                const response = await api.post('/admin/shifts/start', {
                    starting_cash: startingCash
                });
                const resData = response.data?.data || response.data || {};
                this.shift = resData;
                return resData;
            } catch (err) {
                this.error = err.response?.data?.message || 'Failed to start shift';
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async endShift(endingDetails) {
            this.loading = true;
            try {
                const response = await api.post('/admin/shifts/end', {
                    ending_cash_actual: endingDetails.actual_cash,
                    note: endingDetails.note
                });
                this.shift = null; // Shift ended
                return response.data?.data || response.data || {};
            } catch (err) {
                this.error = err.response?.data?.message || 'Failed to end shift';
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async fetchShifts(params = {}) {
            this.loading = true;
            try {
                const queryParams = new URLSearchParams();
                if (params.user_id) queryParams.append('user_id', params.user_id);
                if (params.page) queryParams.append('page', params.page);
                
                const response = await api.get(`/admin/shifts?${queryParams.toString()}`);
                return response.data?.data || response.data || {}; // Return full paginated object
            } catch (err) {
                console.error('Error fetching shifts:', err);
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async fetchPendingCount() {
            try {
                const response = await api.get('/admin/orders/pending-count');
                const resData = response.data?.data || response.data || {};
                this.pendingOrderCount = resData.count || 0;
            } catch (err) {
                console.error('Error fetching pending count:', err);
            }
        },

        // Discount Actions
        async fetchDiscounts() {
            try {
                // Use public endpoint which returns active promos and is accessible to all
                const response = await api.get('/public/promos'); 
                const rawData = response.data?.data || response.data || [];
                // Public endpoint returns array directly (see Controller), not paginated object
                this.discounts = Array.isArray(rawData) ? rawData : [];
            } catch (err) {
                console.error('Error fetching discounts:', err);
            }
        },

        applyDiscount(discount) {
            this.activeDiscount = discount;
        },

        removeDiscount() {
            this.activeDiscount = null;
        },

        startPollingPendingOrders(interval = 5000) {
            this.stopPollingPendingOrders();
            this.fetchPendingCount(); // Initial fetch
            this.pollingInterval = setInterval(() => {
                this.fetchPendingCount();
            }, interval);
        },

        stopPollingPendingOrders() {
            if (this.pollingInterval) {
                clearInterval(this.pollingInterval);
                this.pollingInterval = null;
            }
        }
    }
});
