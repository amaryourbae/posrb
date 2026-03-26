<template>
<MobileLayout :showHeader="false" :showFooter="false">
<div class="flex flex-col font-display antialiased selection:bg-primary/20 selection:text-primary overflow-x-hidden text-slate-900 min-h-full">
    <header class="flex items-center justify-between px-5 py-4 sticky top-0 z-50 bg-white/90 backdrop-blur-sm border-b border-transparent">
        <button @click="$router.go(-1)" aria-label="Go back" class="flex items-center justify-center w-10 h-10 rounded-full hover:bg-gray-100 transition-colors text-slate-900 -ml-2">
            <ChevronLeft class="w-6 h-6" />
        </button>
        <h1 class="text-lg font-bold text-slate-900 absolute left-1/2 -translate-x-1/2">
            Verifikasi Kode
        </h1>
        <div class="w-8"></div>
    </header>

    <main class="flex-1 flex flex-col w-full max-w-md mx-auto px-6 py-4">
        <div class="mt-4 mb-10 text-center">
            <p class="text-slate-500 text-base font-normal leading-relaxed">
                Masukkan 6 digit kode yang dikirim ke
            </p>
            <p class="text-slate-900 text-lg font-bold mt-1 tracking-tight">
                {{ formattedPhone }}
            </p>
        </div>

        <div class="mb-10 w-full">
            <div class="flex justify-between gap-2 sm:gap-3">
                <input 
                    v-for="(digit, index) in digits" 
                    :key="index"
                    :ref="el => otpInputs[index] = el"
                    v-model="digits[index]"
                    type="number" 
                    maxlength="1"
                    @input="handleInput($event, index)"
                    @keydown.delete="handleDelete($event, index)"
                    @keydown.left="focusPrev(index)"
                    @keydown.right="focusNext(index)"
                    class="w-12 h-14 sm:w-14 sm:h-16 flex-1 text-center text-2xl sm:text-3xl font-bold bg-white border rounded-2xl focus:outline-none focus:ring-4 focus:ring-primary/20 transition-all focus:-translate-y-1 focus:shadow-soft"
                    :class="[
                        digits[index] ? 'border-primary text-gray-900 shadow-glow z-10' : 'border-gray-300 text-gray-900'
                    ]"
                />
            </div>
        </div>

        <div class="flex flex-col items-center justify-center gap-2 mb-auto">
            <p class="text-sm text-slate-500">Tidak terima kode?</p>
            <button 
                @click="resendOtp"
                :disabled="countdown > 0 || loading"
                class="text-primary hover:text-primary-dark font-bold text-sm transition-colors flex items-center gap-1.5 py-1 px-3 rounded-lg hover:bg-primary/5 disabled:opacity-50 disabled:cursor-not-allowed"
            >
                <RefreshCw class="w-[18px] h-[18px]" :class="{'animate-spin': loading}" />
                <span v-if="countdown > 0">Kirim Ulang (00:{{ countdown.toString().padStart(2, '0') }})</span>
                <span v-else>Kirim Ulang</span>
            </button>
        </div>
    </main>
</div>
</MobileLayout>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue';
import { useMemberAuthStore } from '../../stores/memberAuth';
import { useRoute, useRouter } from 'vue-router';
import { ChevronLeft, RefreshCw } from 'lucide-vue-next';
import MobileLayout from '../../layouts/MobileLayout.vue';
import { useToast } from 'vue-toastification';

const route = useRoute();
const router = useRouter();
const authStore = useMemberAuthStore();
const toast = useToast();

const digits = ref(['', '', '', '', '', '']);
const otpInputs = ref([]);
const loading = ref(false);
const countdown = ref(0);
let timerInterval = null;

// Get phone from store or query
const phone = computed(() => {
    // If we came from register/login flow, it might be in store
    // Or passed as query param (less secure but common)
    return authStore.tempPhone || route.query.phone || '';
});

const formattedPhone = computed(() => {
    // Basic formatting
    return phone.value.replace(/^(\d{3})(\d{4})(\d+)$/, '$1-$2-$3');
});

const otpCode = computed(() => digits.value.join(''));

const handleInput = (event, index) => {
    const value = event.target.value;
    
    // Allow only numbers
    if (!/^\d*$/.test(value)) {
        digits.value[index] = '';
        return;
    }

    // Handle paste or multiple chars
    if (value.length > 1) {
        const chars = value.split('').slice(0, 6 - index);
        chars.forEach((char, i) => {
            if (index + i < 6) digits.value[index + i] = char;
        });
        focusNext(index + chars.length - 1);
        return;
    }

    digits.value[index] = value;
    
    if (value) {
        focusNext(index);
    }
    
    if (otpCode.value.length === 6) {
        submitOtp();
    }
};

const handleDelete = (event, index) => {
    if (!digits.value[index] && index > 0) {
        focusPrev(index);
    }
};

const focusNext = (index) => {
    if (index < 5) {
        nextTick(() => {
            otpInputs.value[index + 1]?.focus();
        });
    }
};

const focusPrev = (index) => {
    if (index > 0) {
        nextTick(() => {
            otpInputs.value[index - 1]?.focus();
        });
    }
};

const submitOtp = async () => {
    loading.value = true;
    try {
        const mode = route.query.mode || 'login'; // 'login' or 'register'
        
        // If register mode, we call verifyRegister
        // If login mode, we call verifyOtp (login)
        
        let result;
        if (mode === 'register') {
            result = await authStore.verifyRegister(otpCode.value);
        } else {
            result = await authStore.verifyOtp(otpCode.value);
        }
        
        toast.success(result.message || 'Verifikasi berhasil!', {
            position: "top-left",
            toastClassName: "customer-toast"
        });
        router.push('/'); 
    } catch (e) {
        console.error("OTP Verification Error:", e);

        toast.error("Gagal Verifikasi: " + (e.response?.data?.message || e.message), {
            position: "top-left",
            toastClassName: "customer-toast"
        });
        
        // Reset OTP on failure
        digits.value = ['', '', '', '', '', ''];
        otpInputs.value[0]?.focus();
    } finally {
        loading.value = false;
    }
};

const resendOtp = async () => {
    if (countdown.value > 0) return;
    
    loading.value = true;
    try {
        await authStore.sendOtp(phone.value); 
        toast.info('Kode OTP baru telah dikirim', {
            position: "top-left",
            toastClassName: "customer-toast"
        });
        startCountdown();
    } catch (e) {
        // Error
    } finally {
        loading.value = false;
    }
};

const startCountdown = () => {
    countdown.value = 60;
    if (timerInterval) clearInterval(timerInterval);
    
    timerInterval = setInterval(() => {
        countdown.value--;
        if (countdown.value <= 0) {
            clearInterval(timerInterval);
        }
    }, 1000);
};

onMounted(() => {
    startCountdown(); 
    nextTick(() => {
        otpInputs.value[0]?.focus();
    });
});

onUnmounted(() => {
    if (timerInterval) clearInterval(timerInterval);
});
</script>
