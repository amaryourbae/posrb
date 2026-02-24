<template>
<MobileLayout :showHeader="false" :showFooter="false">
<div class="font-display text-slate-900 pb-6 overflow-x-hidden selection:bg-primary selection:text-white flex flex-col justify-between h-full min-h-[calc(100vh-2rem)]">
    <header class="flex items-center justify-between px-5 py-4 sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-gray-100">
        <button @click="$router.push('/app/login')" class="flex items-center justify-center h-10 w-10 rounded-full hover:bg-gray-100 transition-colors -ml-2 text-slate-900">
            <ChevronLeftIcon class="w-6 h-6" />
        </button>
        <h1 class="text-lg font-bold text-slate-900 absolute left-1/2 -translate-x-1/2">Daftar Member</h1>
        <div class="w-8"></div>
    </header>

    <main class="flex-1 px-5 py-6 flex flex-col w-full max-w-md mx-auto">
        <div class="mb-8">
            <h2 class="text-2xl font-bold text-primary mb-2">Selamat Datang!</h2>
            <p class="text-slate-500 text-sm">Lengkapi data diri Anda untuk bergabung dengan Ruang Bincang.</p>
        </div>

        <form @submit.prevent="handleRegister" class="flex flex-col gap-5">
            <div class="space-y-1.5">
                <label class="text-sm font-semibold text-gray-700 ml-1" for="fullName">Nama Lengkap</label>
                <div class="relative group">
                    <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                        <User class="h-5 w-5 text-gray-400 group-focus-within:text-primary transition-colors" />
                    </div>
                    <input v-model="form.name" required class="block w-full pl-11 pr-4 py-3.5 bg-white border border-gray-300 rounded-xl text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-sm shadow-sm" id="fullName" placeholder="Masukkan nama lengkap" type="text"/>
                </div>
            </div>

            <div class="space-y-1.5">
                <label class="text-sm font-semibold text-gray-700 ml-1" for="whatsapp">
                    Nomor WhatsApp <span class="text-red-500">*</span>
                </label>
                <div class="relative group">
                    <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none z-10">
                        <Phone class="h-5 w-5 text-gray-400 group-focus-within:text-primary transition-colors" />
                    </div>
                    <div class="absolute inset-y-0 left-11 flex items-center pointer-events-none">
                        <span class="text-gray-500 font-medium text-sm pr-2 border-r border-gray-300">+62</span>
                    </div>
                    <input v-model="form.phone" required class="block w-full pl-18 pr-4 py-3.5 bg-white border border-gray-300 rounded-xl text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-sm shadow-sm" id="whatsapp" placeholder="812-3456-7890" type="tel"/>
                </div>
                <p class="text-xs text-gray-400 ml-1">Kode OTP akan dikirim ke nomor ini.</p>
            </div>

            <div class="space-y-1.5">
                <div class="flex justify-between items-center">
                    <label class="text-sm font-semibold text-gray-700 ml-1" for="email">Email</label>
                    <span class="text-xs text-secondary font-medium italic">Opsional</span>
                </div>
                <div class="relative group">
                    <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                        <Mail class="h-5 w-5 text-gray-400 group-focus-within:text-primary transition-colors" />
                    </div>
                    <input v-model="form.email" class="block w-full pl-11 pr-4 py-3.5 bg-white border border-gray-300 rounded-xl text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-sm shadow-sm" id="email" placeholder="nama@email.com" type="email"/>
                </div>
            </div>

            <div class="space-y-1.5">
                <label class="text-sm font-semibold text-gray-700 ml-1" for="birthdate">Tanggal Lahir</label>
                <div class="relative group">
                    <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                        <Calendar class="h-5 w-5 text-gray-400 group-focus-within:text-primary transition-colors" />
                    </div>
                    <input v-model="form.birth_date" class="block w-full pl-11 pr-4 py-3.5 bg-white border border-gray-300 rounded-xl text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-sm shadow-sm" id="birthdate" type="date"/>
                </div>
                <div class="flex items-center gap-1.5 ml-1 mt-0.5">
                    <Gift class="w-3.5 h-3.5 text-primary" />
                    <p class="text-xs text-primary font-medium">Dapatkan hadiah spesial saat ulang tahun!</p>
                </div>
            </div>

            <div class="flex items-start gap-3 mt-2 px-1">
                <div class="flex h-6 items-center">
                    <input v-model="form.terms" required class="h-5 w-5 rounded border-gray-300 text-primary focus:ring-primary bg-white" id="terms" name="terms" type="checkbox"/>
                </div>
                <div class="text-sm leading-6">
                    <label class="text-slate-600" for="terms">
                        Saya menyetujui <a class="font-semibold text-primary hover:underline" href="#">Syarat & Ketentuan</a> serta <a class="font-semibold text-primary hover:underline" href="#">Kebijakan Privasi</a> yang berlaku.
                    </label>
                </div>
            </div>

            <div class="pt-4 pb-8 mt-auto">
                <button 
                    type="submit"
                    :disabled="loading || !form.terms"
                    class="w-full bg-primary hover:bg-primary-dark active:scale-[0.98] transition-all text-white font-bold py-4 rounded-xl shadow-lg shadow-primary/20 flex items-center justify-center gap-2 text-base disabled:opacity-70 disabled:cursor-not-allowed"
                >
                    <span v-if="!loading">Daftar & Kirim OTP</span>
                    <span v-else>Memproses...</span>
                    <ArrowRight v-if="!loading" class="w-5 h-5" />
                </button>
                <p class="text-center mt-4 text-sm text-slate-500">
                    Sudah punya akun? <router-link to="/app/login" class="font-bold text-primary hover:underline">Masuk disini</router-link>
                </p>
            </div>
        </form>
    </main>
</div>
</MobileLayout>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useMemberAuthStore } from '../../stores/memberAuth';
import { ChevronLeftIcon, User, Phone, Mail, Calendar, Gift, ArrowRight } from 'lucide-vue-next';
import MobileLayout from '../../layouts/MobileLayout.vue';

const router = useRouter();
const authStore = useMemberAuthStore();

const form = ref({
    name: '',
    phone: '',
    email: '',
    birth_date: '',
    terms: false
});

const loading = ref(false);

const handleRegister = async () => {
    loading.value = true;
    try {
        await authStore.registerInit(form.value);
        // Navigate to verify with mode=register
        router.push({ name: 'MemberVerify', query: { mode: 'register', phone: form.value.phone } });
    } catch (e) {
        // Handled in store
    } finally {
        loading.value = false;
    }
};
</script>
