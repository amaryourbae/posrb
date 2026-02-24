import { defineStore } from 'pinia';

export const useCartStore = defineStore('cart', {
    state: () => ({
        items: [], // { product, quantity, note }
        customer: null,
    }),

    getters: {
        subtotal: (state) => {
            return state.items.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
        },
        tax: (state) => {
             // Assuming 11% based on Seeder, dynamic would be better but simple for now
            return state.subtotal * 0.11;
        },
        totalAmount: (state) => {
            return state.getters.subtotal + state.getters.tax; // Accessing other getters via state.getters usually creates issue in Pinia Options API? 
            // Correct approach: use 'this' in getters
            // But let's simplify:
            const sub = state.items.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
            return sub * 1.11; 
        },
        totalItems: (state) => {
            return state.items.reduce((sum, item) => sum + item.quantity, 0);
        }
    },

    actions: {
        addItem(product, quantity = 1, note = '') {
            const existingItem = this.items.find(item => item.product.id === product.id && item.note === note);
            
            if (existingItem) {
                existingItem.quantity += quantity;
            } else {
                this.items.push({
                    product,
                    quantity,
                    note,
                    // Store localized price/cost if needed for stability
                });
            }
        },

        removeItem(productId) {
            this.items = this.items.filter(item => item.product.id !== productId);
        },
        
        updateQuantity(productId, quantity) {
             const item = this.items.find(item => item.product.id === productId);
             if (item) {
                 item.quantity = quantity;
                 if (item.quantity <= 0) this.removeItem(productId);
             }
        },

        setCustomer(customer) {
            this.customer = customer;
        },

        clearCart() {
            this.items = [];
            this.customer = null;
        }
    }
});
