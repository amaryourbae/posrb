import { defineStore } from 'pinia';
import api from '../api/axios';

// Safe JSON parse helper to handle corrupted localStorage data
const safeJsonParse = (value) => {
    if (!value || value === 'undefined' || value === 'null') {
        return null;
    }
    try {
        return JSON.parse(value);
    } catch (e) {
        console.warn('Failed to parse stored user data, clearing...', e);
        localStorage.removeItem('user');
        return null;
    }
};

export const useAuthStore = defineStore('auth', {
    state: () => ({
        user: safeJsonParse(localStorage.getItem('user')),
        token: localStorage.getItem('token') || null,
        isAuthenticated: !!localStorage.getItem('token'),
        loading: false,
        error: null,
    }),

    actions: {
        async login(credentials) {
            this.loading = true;
            this.error = null;
            try {
                // Sanctum requires CSRF cookie first for SPA (if using cookies) or just token for API
                // For Token Auth (Pin Login usually implies token response directly):
                const response = await api.post('/login', credentials); // Assuming endpoint exists or will exist
                
                // API returns: { success: true, message: '...', data: { token, user }, errors: null }
                // So we need to access response.data.data for the actual payload
                const payload = response.data.data || response.data;
                const { token, user } = payload;

                this.token = token;
                this.user = user;
                this.isAuthenticated = true;

                localStorage.setItem('token', token);
                localStorage.setItem('user', JSON.stringify(user));


                api.defaults.headers.common['Authorization'] = `Bearer ${token}`;

            } catch (err) {
                this.error = err.response?.data?.message || 'Login failed';
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async logout() {
            try {
                await api.post('/logout');
            } catch (err) {
                console.error('Logout failed on server', err);
            } finally {
                this.clearState();
            }
        },

        async fetchUser() {
            try {
                const response = await api.get('/user');
                this.user = response.data;
                localStorage.setItem('user', JSON.stringify(this.user));
            } catch (err) {
                this.clearState();
            }
        },

        hasRole(roleName) {
            return this.user?.roles?.some(r => r.name === roleName) ?? false;
        },

        clearState() {
            this.user = null;
            this.token = null;
            this.isAuthenticated = false;
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            delete api.defaults.headers.common['Authorization'];
        },
    },
});
