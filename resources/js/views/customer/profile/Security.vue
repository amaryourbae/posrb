<template>
    <MobileLayout :showHeader="false" :showFooter="true">
        <div class="min-h-screen bg-gray-50 pb-24">
            <!-- Header -->
            <div class="bg-white sticky top-0 z-10 px-4 py-3 flex items-center gap-3 border-b border-gray-100 shadow-sm">
                <button @click="$router.back()" class="w-10 h-10 flex items-center justify-center rounded-full hover:bg-gray-100 transition-colors">
                    <ChevronLeftIcon class="w-6 h-6 text-gray-700" />
                </button>
                <h1 class="text-lg font-bold text-gray-900">Keamanan</h1>
            </div>

            <div class="p-5">
                <form @submit.prevent="changePassword" class="space-y-5 bg-white p-5 rounded-2xl border border-gray-100 shadow-sm">
                    <div>
                        <label class="block text-sm font-bold text-gray-700 mb-1">Kata Sandi Saat Ini</label>
                        <div class="relative">
                            <input 
                                v-model="form.current_password"
                                :type="showCurrent ? 'text' : 'password'"
                                class="w-full rounded-xl border-gray-200 focus:border-primary focus:ring-primary transition-all text-sm font-medium p-3 pr-10"
                                placeholder="Masukkan kata sandi lama"
                            />
                            <button type="button" @click="showCurrent = !showCurrent" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400">
                                <EyeIcon v-if="!showCurrent" class="w-5 h-5" />
                                <EyeOffIcon v-else class="w-5 h-5" />
                            </button>
                        </div>
                    </div>

                    <div>
                        <label class="block text-sm font-bold text-gray-700 mb-1">Kata Sandi Baru</label>
                        <div class="relative">
                            <input 
                                v-model="form.new_password"
                                :type="showNew ? 'text' : 'password'"
                                class="w-full rounded-xl border-gray-200 focus:border-primary focus:ring-primary transition-all text-sm font-medium p-3 pr-10"
                                placeholder="Minimal 6 karakter"
                            />
                             <button type="button" @click="showNew = !showNew" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400">
                                <EyeIcon v-if="!showNew" class="w-5 h-5" />
                                <EyeOffIcon v-else class="w-5 h-5" />
                            </button>
                        </div>
                    </div>

                    <div>
                        <label class="block text-sm font-bold text-gray-700 mb-1">Konfirmasi Kata Sandi Baru</label>
                        <div class="relative">
                            <input 
                                v-model="form.confirm_password"
                                :type="showConfirm ? 'text' : 'password'"
                                class="w-full rounded-xl border-gray-200 focus:border-primary focus:ring-primary transition-all text-sm font-medium p-3 pr-10"
                                placeholder="Ulangi kata sandi baru"
                            />
                             <button type="button" @click="showConfirm = !showConfirm" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400">
                                <EyeIcon v-if="!showConfirm" class="w-5 h-5" />
                                <EyeOffIcon v-else class="w-5 h-5" />
                            </button>
                        </div>
                    </div>

                    <div class="pt-4">
                         <button 
                            type="submit"
                            :disabled="loading"
                            class="w-full bg-primary hover:bg-[#0a3828] text-white font-bold py-3.5 rounded-xl shadow-lg shadow-primary/20 transition-all active:scale-[0.98] disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                        >
                            <Loader2Icon v-if="loading" class="w-5 h-5 animate-spin" />
                            <span>Update Kata Sandi</span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </MobileLayout>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { ChevronLeftIcon, EyeIcon, EyeOffIcon, Loader2Icon } from 'lucide-vue-next';
import { useToast } from 'vue-toastification';
import MobileLayout from '../../../layouts/MobileLayout.vue';

const router = useRouter();
// ... rest of script
const toast = useToast();
const loading = ref(false);

const form = ref({
    current_password: '',
    new_password: '',
    confirm_password: ''
});

const showCurrent = ref(false);
const showNew = ref(false);
const showConfirm = ref(false);

const changePassword = async () => {
    if (!form.value.current_password || !form.value.new_password || !form.value.confirm_password) {
        toast.error("Mohon lengkapi semua kolom", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
        return;
    }

    if (form.value.new_password !== form.value.confirm_password) {
        toast.error("Konfirmasi kata sandi tidak cocok", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
        return;
    }

    loading.value = true;
    try {
        // Mock API call
        setTimeout(() => {
            toast.success("Kata sandi berhasil diperbarui", {
                position: "top-left",
                toastClassName: "customer-toast"
            });
            router.back();
        }, 1000);
    } catch (e) {
        console.error(e);
        toast.error("Gagal memperbarui kata sandi", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
    } finally {
        loading.value = false;
    }
};
</script>
