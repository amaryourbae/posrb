<template>
    <div class="min-h-screen flex items-center justify-center bg-gray-100 px-4">
        <div class="bg-white p-8 rounded-2xl shadow-xl w-full max-w-md border border-gray-100">
            <!-- Header -->
            <div class="text-center mb-8">
                <div v-if="settings?.store_logo" class="flex justify-center mb-6">
                    <div class="bg-primary p-4 rounded-2xl shadow-lg shadow-primary/20">
                        <img :src="settings.store_logo" alt="App Logo" class="h-10 w-auto object-contain brightness-0 invert" />
                    </div>
                </div>
                <!-- Fallback Text -->
                <h1 v-else class="text-2xl font-bold bg-clip-text text-transparent bg-linear-to-r from-primary to-[#4a5930]">
                    POS Ruang Bincang
                </h1>
                <p class="text-gray-500 text-sm mt-2">Sign in to your account</p>
            </div>

            <!-- Error Alert -->
            <div v-if="error" class="mb-6 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-xl flex items-center text-sm">
                <AlertCircleIcon class="w-5 h-5 mr-3 shrink-0" />
                <span>{{ error }}</span>
            </div>

            <!-- Form -->
            <!-- Login Type Toggle -->
            <div class="flex p-1 bg-gray-100 rounded-xl mb-6">
                <button 
                    type="button"
                    @click="loginType = 'email'"
                    class="flex-1 py-2 text-sm font-bold rounded-lg transition-all"
                    :class="loginType === 'email' ? 'bg-white text-primary shadow-sm' : 'text-gray-500 hover:text-gray-700'"
                >
                    Email
                </button>
                <button 
                    type="button"
                    @click="loginType = 'whatsapp'"
                    class="flex-1 py-2 text-sm font-bold rounded-lg transition-all"
                    :class="loginType === 'whatsapp' ? 'bg-white text-primary shadow-sm' : 'text-gray-500 hover:text-gray-700'"
                >
                    WhatsApp
                </button>
            </div>

            <!-- Form -->
            <form @submit.prevent="handleLogin" class="space-y-6">
                <!-- Email Login -->
                <div v-if="loginType === 'email'" class="space-y-6">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
                        <div class="relative">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <UserIcon class="h-5 w-5 text-gray-400" />
                            </div>
                            <input 
                                v-model="email" 
                                type="email" 
                                :required="loginType === 'email'"
                                class="block w-full pl-10 pr-3 py-2.5 border border-gray-300 rounded-xl focus:ring-primary focus:border-primary transition-colors text-sm"
                                placeholder="mail@ruangbincang.coffee"
                            >
                        </div>
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                        <div class="relative">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <LockIcon class="h-5 w-5 text-gray-400" />
                            </div>
                            <input 
                                v-model="password" 
                                type="password" 
                                :required="loginType === 'email'"
                                class="block w-full pl-10 pr-3 py-2.5 border border-gray-300 rounded-xl focus:ring-primary focus:border-primary transition-colors text-sm"
                                placeholder="••••••••"
                            >
                        </div>
                    </div>
                </div>

                <!-- WhatsApp Login -->
                <div v-if="loginType === 'whatsapp'" class="space-y-6">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">WhatsApp Number</label>
                        <div class="relative">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <span class="text-gray-500 font-bold text-sm pt-0.5">+62</span>
                            </div>
                            <input 
                                v-model="whatsapp" 
                                type="tel" 
                                :disabled="otpSent"
                                :required="loginType === 'whatsapp'"
                                class="block w-full pl-12 pr-3 py-2.5 border border-gray-300 rounded-xl focus:ring-primary focus:border-primary transition-colors text-sm font-medium disabled:bg-gray-100 disabled:text-gray-500"
                                placeholder="812-3456-7890"
                            >
                        </div>
                        <p v-if="!otpSent" class="text-xs text-gray-500 mt-2">We will send an OTP code to your registered WhatsApp number.</p>
                        <button v-else @click="otpSent = false" type="button" class="text-xs text-primary mt-2 hover:underline">Change Number</button>
                    </div>

                    <!-- OTP Input -->
                    <div v-if="otpSent">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Enter OTP Code</label>
                        <div class="relative">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <LockIcon class="h-5 w-5 text-gray-400" />
                            </div>
                            <input 
                                v-model="otpCode" 
                                type="text" 
                                required
                                class="block w-full pl-10 pr-3 py-2.5 border border-gray-300 rounded-xl focus:ring-primary focus:border-primary transition-colors text-sm letter-spacing-2"
                                placeholder="123456"
                                maxlength="6"
                            >
                        </div>
                    </div>
                </div>

                <div class="flex items-center justify-between text-sm" v-if="loginType === 'email'">
                    <div class="flex items-center">
                        <input id="remember-me" type="checkbox" class="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded">
                        <label for="remember-me" class="ml-2 block text-gray-700">Remember me</label>
                    </div>
                    <a href="#" class="font-medium text-primary hover:text-[#425026]">Forgot password?</a>
                </div>

                <button 
                    type="submit" 
                    :disabled="loading"
                    class="w-full flex justify-center py-3 px-4 border border-transparent rounded-xl shadow-sm text-sm font-bold text-white bg-primary hover:bg-[#4a5c2e] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-all disabled:opacity-70 disabled:cursor-not-allowed"
                >
                    <Loader2Icon v-if="loading" class="animate-spin -ml-1 mr-2 h-5 w-5" />
                    <span v-else>
                        {{ loginType === 'email' ? 'Sign In' : (otpSent ? 'Verify OTP & Login' : 'Send OTP Code') }}
                    </span>
                </button>
            </form>
            
            <div class="mt-6 text-center text-xs text-gray-400">
                &copy; {{ new Date().getFullYear() }} Ruang Bincang Coffee &bull; Powered by @amaryourbae
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../../stores/auth';
import { UserIcon, LockIcon, AlertCircleIcon, Loader2Icon, PhoneIcon } from 'lucide-vue-next';
import api from '../../api/axios';

const router = useRouter();
const authStore = useAuthStore();
const settings = ref(null);

onMounted(async () => {
    try {
        const response = await api.get('/public/settings');
        settings.value = response.data?.data || response.data || {};
    } catch (e) {
        console.error("Failed to fetch settings", e);
    }
});

const email = ref('');
const password = ref('');
const whatsapp = ref('');
const otpCode = ref('');
const otpSent = ref(false);
const loginType = ref('email');
const loading = ref(false);
const error = ref('');

const handleLogin = async () => {
    loading.value = true;
    error.value = '';

    try {
        if (loginType.value === 'email') {
            await authStore.login({
                email: email.value,
                password: password.value
            });
        } else {
            // WhatsApp Login Flow
            const payload = {
                phone: whatsapp.value,
                is_otp: true
            };
            
            if (otpSent.value) {
                // Step 2: Verify OTP
                payload.otp = otpCode.value;
                await authStore.login(payload);
            } else {
                // Step 1: Send OTP
                // We call the login endpoint, but expecting a specific response to prompt OTP
                // Since authStore.login expects successful login, we might need to handle this manually or update store.
                // For simplicity, let's call API directly for step 1, or update store to return response.
                // Or, authStore.login throws if not token? 
                // Let's call API directly for Step 1 to avoid store confusion
                
                const response = await api.post('/login', payload);
                const responseData = response.data?.data || response.data || {};
                
                if (responseData.is_otp_sent) {
                    otpSent.value = true;
                    loading.value = false;
                    return; // Stop here, wait for user input
                }
            }
        }
        
        // Role based redirection
        const user = authStore.user;
        
        // Handle case where user is not set properly
        if (!user) {
            console.error('User not set after login');
            router.push('/');
            return;
        }
        
        const roles = user.roles || []; // Assuming backend returns roles relation, e.g. [{name: 'super_admin'}]
        
        // Helper to check role
        const hasRole = (roleName) => roles.some(r => r.name === roleName);

        if (hasRole('super_admin') || hasRole('store_manager')) {
            router.push('/admin');
        } else if (hasRole('cashier')) {
            router.push('/pos');
        } else {
            // Default fallback
            router.push('/');
        }

    } catch (err) {
        console.error(err);
        error.value = err.response?.data?.message || 'Invalid email or password.';
    } finally {
        loading.value = false;
    }
};
</script>
