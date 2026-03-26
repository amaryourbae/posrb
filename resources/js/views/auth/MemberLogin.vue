<template>
<MobileLayout :showHeader="false" :showFooter="false">
<div class="font-display text-slate-900 pb-6 overflow-x-hidden selection:bg-primary selection:text-white flex flex-col justify-between h-full min-h-[calc(100vh-2rem)]">
    <header class="flex items-center justify-between p-4 sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-gray-100">
        <button @click="$router.push('/')" class="flex items-center justify-center h-10 w-10 rounded-full hover:bg-gray-100 transition-colors -ml-2 text-slate-800">
            <ChevronLeftIcon class="w-6 h-6" />
        </button>
        <h1 class="text-lg font-bold text-slate-900 absolute left-1/2 -translate-x-1/2">Masuk</h1>
        <div class="w-8"></div>
    </header>
        
    <main class="flex-1 px-6 pt-8 flex flex-col gap-8">
        <div class="space-y-2">
            <img 
                v-if="settings?.store_logo" 
                :src="settings.store_logo" 
                alt="Logo" 
                class="h-16 w-auto object-contain mb-4"
                style="filter: brightness(0) saturate(100%) invert(38%) sepia(20%) saturate(836%) hue-rotate(45deg) brightness(96%) contrast(89%)"
            />
            <h1 v-else class="text-[32px] font-bold tracking-tight text-primary leading-tight">
                {{ settings?.store_name || 'Ruang Bincang' }}
            </h1>
            <p class="text-2xl font-semibold text-slate-900 mt-2">Selamat Datang Kembali!</p>
            <p class="text-slate-500 text-sm">Masuk untuk menikmati kopi terbaik kami.</p>
        </div>

        <form @submit.prevent="handleLogin" class="space-y-6">
            <div class="space-y-2">
                <label class="block text-sm font-medium text-gray-700 ml-1" for="whatsapp">
                    Nomor WhatsApp
                </label>
                <div class="relative flex items-center">
                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none gap-2">
                        <div class="w-5 h-3.5 bg-gray-200 rounded-sm overflow-hidden flex flex-col shadow-sm border border-gray-200">
                            <div class="h-1/2 w-full bg-[#FF0000]"></div>
                            <div class="h-1/2 w-full bg-white"></div>
                        </div>
                        <span class="text-gray-500 font-medium text-base border-r border-gray-300 pr-2 pl-1">+62</span>
                    </div>
                    <input 
                        v-model="phone"
                        class="block w-full pl-18 pr-10 py-4 bg-white border-gray-300 rounded-xl text-lg focus:ring-primary focus:border-primary placeholder:text-gray-400 transition-shadow text-gray-900" 
                        id="whatsapp" 
                        name="whatsapp" 
                        placeholder="812-3456-7890" 
                        type="tel"
                        required
                    />
                    <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                        <Phone class="h-5 w-5 text-gray-400" />
                    </div>
                </div>
            </div>

            <button 
                type="submit"
                :disabled="loading"
                class="w-full bg-primary hover:bg-primary-dark text-white font-bold py-4 px-6 rounded-xl shadow-lg shadow-primary/20 transition-all active:scale-[0.98] flex items-center justify-center gap-2 group disabled:opacity-70 disabled:cursor-not-allowed"
            >
                <span v-if="!loading">Kirim Kode OTP</span>
                <span v-else>Mengirim...</span>
                <ArrowRight v-if="!loading" class="w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </button>
        </form>
    </main>

    <div class="px-6 pb-10 text-center space-y-6">
        <div class="relative">
            <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-gray-200"></div>
            </div>
            <div class="relative flex justify-center text-sm">
                <span class="px-2 bg-white text-slate-500">atau masuk dengan</span>
            </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
            <GoogleLogin custom :callback="handleGoogleLogin">
                <template #default="{ disabled, login }">
                <button type="button" @click="login" :disabled="disabled" class="w-full h-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl border border-gray-200 hover:bg-gray-50 transition-colors">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"></path>
                        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"></path>
                        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"></path>
                        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"></path>
                    </svg>
                    <span class="font-medium text-slate-700">Google</span>
                </button>
                </template>
            </GoogleLogin>
            <AppleLogin 
                :clientId="'dummy.apple.client.id'"
                redirectURI="https://yourdomain.com/login"
                @success="handleAppleLogin" 
                @error="handleAppleError">
                <button class="w-full h-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl border border-gray-200 hover:bg-gray-50 transition-colors">
                    <svg class="w-5 h-5 text-black" fill="currentColor" viewBox="0 0 24 24">
                         <path d="M17.05 20.28c-.98.95-2.05.88-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.78.79-.04 2.1-.71 3.48-.59 2.1.18 3.53 1.1 4.17 2.05-3.63 1.95-2.98 6.45.61 7.94-.65 1.74-1.63 3.43-3.34 2.79zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"></path>
                    </svg>
                    <span class="font-medium text-slate-700">Apple</span>
                </button>
            </AppleLogin>
        </div>

        <p class="text-sm text-slate-500">
            Belum punya akun? 
            <router-link to="/member/register" class="font-bold text-primary hover:text-primary-dark underline decoration-2 decoration-transparent hover:decoration-primary transition-all">
                Daftar Sekarang
            </router-link>
        </p>
    </div>
</div>
</MobileLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useMemberAuthStore } from '../../stores/memberAuth';
import { useCustomerStore } from '../../stores/customer';
import { ChevronLeftIcon, Phone, ArrowRight } from 'lucide-vue-next';
import MobileLayout from '../../layouts/MobileLayout.vue';
import { GoogleLogin } from 'vue3-google-login';
import AppleLogin from '../../components/AppleLogin.vue';

const router = useRouter();
const authStore = useMemberAuthStore();
const customerStore = useCustomerStore();

const settings = computed(() => customerStore.settings);

onMounted(() => {
    customerStore.fetchSettings();
});

const phone = ref('');
const loading = ref(false);

const handleLogin = async () => {
    if (!phone.value) return;
    
    loading.value = true;
    try {
        await authStore.sendOtp(phone.value);
        router.push({ name: 'MemberVerify', query: { mode: 'login', phone: phone.value } });
    } catch (e) {
        // Error handling in store
    } finally {
        loading.value = false;
    }
};

const handleGoogleLogin = async (response) => {
    try {
        await authStore.loginWithProvider({
            provider: 'google',
            token: response.credential
        });
        router.push('/member/dashboard');
    } catch (error) {
        // Error already handled by toast in store
    }
};

const handleAppleLogin = async (response) => {
    try {
        // Apple provider returns user object only on first login attempt
        const nameObj = response.user?.name;
        const fullName = nameObj ? `${nameObj.firstName} ${nameObj.lastName}`.trim() : null;
        
        await authStore.loginWithProvider({
            provider: 'apple',
            token: response.authorization.id_token,
            email: response.user?.email || null,
            name: fullName
        });
        router.push('/member/dashboard');
    } catch (error) {
        console.error(error);
    }
};

const handleAppleError = (error) => {
    console.error('Apple Login Error:', error);
};
</script>
