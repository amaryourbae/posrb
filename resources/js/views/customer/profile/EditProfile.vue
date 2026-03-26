<template>
<MobileLayout :showHeader="false" :showFooter="false">
    <div class="flex flex-col min-h-screen bg-white font-sans text-slate-900 pb-safe">
        <!-- Header -->
        <header class="sticky top-0 z-50 bg-white/95 backdrop-blur-sm px-5 py-4 flex items-center justify-between border-b border-gray-50 shadow-sm">
             <button @click="$router.back()" class="w-8 h-8 flex items-center justify-center -ml-2 text-slate-900 active:opacity-70">
                <ChevronLeftIcon class="w-6 h-6" />
            </button>
            <h1 class="text-lg font-bold tracking-tight text-slate-900">Edit Profil</h1>
             <div class="w-8"></div> 
        </header>

        <main class="flex-1 w-full px-5 pt-6 pb-32 overflow-y-auto no-scrollbar flex flex-col">
            <!-- Avatar Upload -->
            <div class="flex flex-col items-center mb-8">
                <div class="relative group cursor-pointer active:scale-95 transition-transform">
                    <img 
                        :src="form.avatar_url || 'https://ui-avatars.com/api/?name=' + (form.name || 'User') + '&background=random'" 
                        class="w-24 h-24 rounded-full object-cover border-4 border-white shadow-md ring-1 ring-gray-100"
                    />
                    <div class="absolute bottom-0 right-0 bg-primary p-2 rounded-full text-white shadow-sm ring-2 ring-white">
                        <CameraIcon class="w-4 h-4" />
                    </div>
                    <input type="file" class="hidden" accept="image/*" @change="handleFileChange">
                </div>
                <p class="text-xs text-slate-400 mt-3 font-medium">Ketuk untuk ubah foto</p>
            </div>

            <!-- Form -->
            <form @submit.prevent="saveProfile" class="space-y-5">
                <div>
                    <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Nama Lengkap</label>
                    <input 
                        v-model="form.name"
                        type="text" 
                        class="w-full h-12 rounded-xl bg-gray-50 border-transparent focus:bg-white focus:border-primary focus:ring-primary transition-all text-sm font-semibold text-slate-900 px-4 placeholder:text-gray-400"
                        placeholder="Masukkan nama lengkap"
                    />
                </div>

                <div>
                    <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Email</label>
                    <input 
                        v-model="form.email"
                        type="email" 
                        class="w-full h-12 rounded-xl bg-gray-50 border-transparent focus:bg-white focus:border-primary focus:ring-primary transition-all text-sm font-semibold text-slate-900 px-4 placeholder:text-gray-400"
                        placeholder="contoh@email.com"
                    />
                </div>

                <div>
                    <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Nomor Telepon</label>
                    <input 
                        v-model="form.phone"
                        type="tel" 
                        disabled
                        class="w-full h-12 rounded-xl bg-gray-100 border-transparent text-gray-500 text-sm font-medium px-4 cursor-not-allowed opacity-70"
                    />
                    <p class="text-[10px] text-gray-400 mt-1.5 ml-1">Nomor telepon tidak dapat diubah</p>
                </div>
            </form>
        </main>

        <!-- Sticky Bottom Button -->
        <div class="fixed bottom-0 left-0 right-0 px-5 py-4 pb-safe bg-white border-t border-gray-100 max-w-md mx-auto z-40">
            <button 
                @click="saveProfile" 
                :disabled="loading"
                class="w-full h-12 bg-primary hover:bg-[#0a3828] text-white font-bold rounded-full shadow-lg shadow-primary/20 transition-all active:scale-[0.98] disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
                <Loader2Icon v-if="loading" class="w-5 h-5 animate-spin" />
                <span v-else>Simpan Perubahan</span>
            </button>
        </div>
    </div>
</MobileLayout>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import MobileLayout from '../../../layouts/MobileLayout.vue';
import { ChevronLeftIcon, CameraIcon, Loader2Icon } from 'lucide-vue-next';
import { useMemberAuthStore } from '../../../stores/memberAuth';

const router = useRouter();
const authStore = useMemberAuthStore();

const member = computed(() => authStore.currentUser);
const loading = ref(false);

const form = ref({
    name: '',
    email: '',
    phone: '',
    avatar_url: ''
});

onMounted(() => {
    if (!member.value) {
        authStore.fetchMe();
    }
});

watch(member, (newVal) => {
    if (newVal) {
        form.value = {
            name: newVal.name,
            email: newVal.email,
            phone: newVal.phone,
            avatar_url: newVal.avatar_url
        };
    }
}, { immediate: true });

const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
        form.value.avatar_url = URL.createObjectURL(file);
    }
};

const saveProfile = async () => {
    loading.value = true;
    try {
        await authStore.updateProfile(form.value);
        router.back();
    } catch (e) {
        console.error(e);
    } finally {
        loading.value = false;
    }
};
</script>

<style scoped>
.pb-safe {
    padding-bottom: env(safe-area-inset-bottom, 5px);
}
.no-scrollbar::-webkit-scrollbar {
    display: none;
}
.no-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
}
</style>
