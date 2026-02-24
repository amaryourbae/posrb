import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import api from '../api/axios';
import { useToast } from 'vue-toastification';

export const useMemberAuthStore = defineStore('memberAuth', () => {
    // State
    const user = ref(null);
    const token = ref(localStorage.getItem('member_token') || null);
    const tempPhone = ref(null);
    const tempRegisterData = ref(null);
    const loading = ref(false);

    // Getters
    const isAuthenticated = computed(() => !!token.value);
    const currentUser = computed(() => user.value);

    // Actions
    const toast = useToast(); 

    function setSession(data) {
        token.value = data.token;
        user.value = data.user;
        localStorage.setItem('member_token', data.token);
    }

    async function registerInit(formData) {
        loading.value = true;
        try {
            const response = await api.post('/public/member/check-phone', {
                phone: formData.phone
            });
            const resData = response.data?.data || response.data || {};
            tempPhone.value = resData.phone;
            tempRegisterData.value = formData;
            toast.success('OTP sent to WhatsApp!');
            return true;
        } catch (err) {
            toast.error(err.response?.data?.message || 'Registration failed');
            throw err;
        } finally {
            loading.value = false;
        }
    }

    async function sendOtp(phone) {
        loading.value = true;
        try {
            const response = await api.post('/public/member/send-otp', { phone });
            const resData = response.data?.data || response.data || {};
            tempPhone.value = resData.phone;
            toast.success('OTP sent to WhatsApp!');
            return true;
        } catch (err) {
            toast.error(err.response?.data?.message || 'Failed to send OTP');
            throw err;
        } finally {
            loading.value = false;
        }
    }

    async function verifyLogin(otp) {
        loading.value = true;
        try {
            const response = await api.post('/public/member/login', {
                phone: tempPhone.value,
                otp
            });
            const resData = response.data?.data || response.data || {};
            setSession(resData);
            toast.success('Welcome back!');
            return resData;
        } catch (err) {
            if (err.response?.status === 404) {
                toast.error('Number not registered. Please register first.');
            } else {
                toast.error(err.response?.data?.message || 'Invalid OTP');
            }
            throw err;
        } finally {
            loading.value = false;
        }
    }

    async function verifyRegister(otp) {
        loading.value = true;
        try {
            if (!tempRegisterData.value) {
                throw new Error("Registration data missing");
            }

            const response = await api.post('/public/member/register', {
                ...tempRegisterData.value,
                otp,
                phone: tempPhone.value
            });
            const resData = response.data?.data || response.data || {};
            setSession(resData);
            tempRegisterData.value = null;
            toast.success('Registration successful!');
            return resData;
        } catch (err) {
            toast.error(err.response?.data?.message || 'Verification failed');
            throw err;
        } finally {
            loading.value = false;
        }
    }

    async function logout() {
        try {
            await api.post('/public/member/logout');
        } catch (e) {
            // Ignore
        }
        token.value = null;
        user.value = null;
        localStorage.removeItem('member_token');
    }

    async function fetchMe() {
        if (!token.value) return;
        try {
            const response = await api.get('/public/member/me', {
                 headers: { Authorization: `Bearer ${token.value}` }
            });
            const raw = response.data;
            user.value = (raw && typeof raw === 'object' && 'data' in raw) ? raw.data : raw;
        } catch (err) {
            logout();
        }
    }

    async function updateProfile(data) {
        loading.value = true;
        try {
            const response = await api.post('/public/member/profile', {
                name: data.name,
                email: data.email
            });
            const resData = response.data?.data || response.data || {};
            user.value = { ...user.value, ...resData };
            toast.success('Profile updated successfully', {
                position: "top-left",
                toastClassName: "customer-toast"
            });
            return resData;
        } catch (err) {
            toast.error(err.response?.data?.message || 'Failed to update profile', {
                position: "top-left",
                toastClassName: "customer-toast"
            });
            throw err;
        } finally {
            loading.value = false;
        }
    }




    return {
        user,
        token,
        tempPhone,
        tempRegisterData,
        loading,
        isAuthenticated,
        currentUser,
        registerInit,
        sendOtp,
        verifyLogin,
        verifyOtp: verifyLogin, 
        verifyRegister,
        logout,
        fetchMe,
        updateProfile
    };
});
