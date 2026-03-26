<template>
    <div class="fixed inset-0 w-full flex justify-center bg-gray-100 overflow-hidden font-sans">
        <div class="w-full max-w-md h-full flex flex-col relative">
        <!-- Sticky Header -->
        <div class="absolute top-0 z-50 w-full pointer-events-none transition-all duration-300">
             <div class="absolute inset-0 bg-white shadow-sm transition-opacity duration-300" :style="{ opacity: headerOpacity }"></div>
             
             <div class="relative z-10 p-4 flex justify-between items-center">
                 <button @click="$router.back()" 
                    class="flex w-10 h-10 items-center justify-center rounded-full transition-all active:scale-95 pointer-events-auto"
                    :class="headerOpacity > 0.8 ? 'bg-gray-100 text-gray-900 border-gray-200' : 'bg-black/20 backdrop-blur-md text-white border-white/10 hover:bg-black/30'">
                    <ChevronLeftIcon class="w-6 h-6" />
                </button>

                <span class="font-bold text-lg text-gray-900 absolute left-1/2 -translate-x-1/2 transition-all duration-300 transform translate-y-4 opacity-0 truncate max-w-[50%]"
                      :class="{ 'translate-y-0! opacity-100!': headerOpacity > 0.8 }">
                    {{ reward?.name }}
                </span>
             </div>
        </div>

        <!-- Scroll Container -->
        <div ref="scrollContainer" @scroll="handleScroll" class="flex-1 overflow-y-auto relative bg-gray-100 scroll-smooth shadow-2xl [&::-webkit-scrollbar]:hidden">
            
            <!-- Sticky Hero Image (Parallax) -->
            <div class="sticky top-0 w-full h-96 z-0 shrink-0 overflow-hidden">
                <div v-if="reward" class="absolute inset-0 bg-cover bg-center transition-transform duration-75 ease-out" 
                     :style="`background-image: url('${reward.image_url || '/no-image.jpg'}'); transform: scale(${1 + scrollProgress * 0.1}) translateY(${scrollProgress * 30}px);`"></div>
                <div v-else class="absolute inset-0 bg-gray-200 animate-pulse"></div>
                <!-- Gradient Overlay -->
                <div class="absolute inset-0 bg-linear-to-b from-black/30 via-transparent to-black/10" :style="{ opacity: 1 - headerOpacity }"></div>
            </div>

            <!-- Content Sheet -->
            <div v-if="reward" class="relative z-10 bg-white rounded-t-[2.5rem] min-h-screen -mt-20 shadow-[0_-10px_40px_rgba(0,0,0,0.1)] flex flex-col overflow-hidden">
                 <!-- Drag Handle -->
                <div class="flex justify-center pt-3 pb-1 opacity-50">
                    <div class="w-12 h-1.5 bg-gray-300 rounded-full"></div>
                </div>

                <div class="px-6 py-6 flex-1 flex flex-col pb-32">
                    <!-- Title & Cost -->
                    <div class="flex flex-col gap-2 pb-6">
                        <h1 class="text-2xl font-bold tracking-tight text-gray-900 leading-tight">{{ reward.name }}</h1>
                        <div class="flex items-center gap-2">
                             <CoinsIcon class="w-5 h-5 text-[#5a6c37]" />
                             <span class="text-2xl font-bold text-[#5a6c37]">{{ reward.point_cost }} Poin</span>
                        </div>
                        <p class="text-sm text-gray-500 font-medium leading-relaxed mt-1">
                            {{ reward.description || 'Tukarkan poinmu untuk dapetin voucher GRATIS ' + reward.name }}
                        </p>
                    </div>

                    <div class="h-2 bg-gray-100 -mx-6 mb-6"></div>

                    <!-- Instructions -->
                     <div class="space-y-6">
                        <div>
                            <h3 class="font-bold text-gray-900 text-lg mb-4">Cara Penukaran</h3>
                            <div class="space-y-4">
                                <div class="flex gap-4 items-start">
                                     <div class="flex flex-col items-center gap-1 shrink-0">
                                         <div class="w-8 h-8 rounded-full bg-[#5a6c37]/10 text-[#5a6c37] flex items-center justify-center font-bold text-sm">1</div>
                                         <div class="w-0.5 h-full bg-gray-100 min-h-[20px]"></div>
                                     </div>
                                     <div class="pb-1">
                                         <h4 class="font-bold text-slate-800 text-sm">Cek Poin Kamu</h4>
                                         <p class="text-xs text-gray-500 mt-1">Pastikan saldo poin kamu mencukupi untuk menukar reward ini.</p>
                                     </div>
                                </div>
                                <div class="flex gap-4 items-start">
                                     <div class="flex flex-col items-center gap-1 shrink-0">
                                         <div class="w-8 h-8 rounded-full bg-[#5a6c37]/10 text-[#5a6c37] flex items-center justify-center font-bold text-sm">2</div>
                                         <div class="w-0.5 h-full bg-gray-100 min-h-[20px]"></div>
                                     </div>
                                     <div class="pb-1">
                                         <h4 class="font-bold text-slate-800 text-sm">Tukarkan Reward</h4>
                                         <p class="text-xs text-gray-500 mt-1">Klik tombol "Tukar" di bawah. Poin akan otomatis terpotong.</p>
                                     </div>
                                </div>
                                <div class="flex gap-4 items-start">
                                     <div class="flex flex-col items-center gap-1 shrink-0">
                                         <div class="w-8 h-8 rounded-full bg-[#5a6c37]/10 text-[#5a6c37] flex items-center justify-center font-bold text-sm">3</div>
                                         <div class="w-0.5 h-full bg-gray-100 min-h-[20px]"></div>
                                     </div>
                                     <div class="pb-1">
                                         <h4 class="font-bold text-slate-800 text-sm">Dapatkan Voucher</h4>
                                         <p class="text-xs text-gray-500 mt-1">Voucher akan masuk ke halaman "My Vouchers" setelah penukaran berhasil.</p>
                                     </div>
                                </div>
                                <div class="flex gap-4 items-start">
                                     <div class="flex flex-col items-center gap-1 shrink-0">
                                         <div class="w-8 h-8 rounded-full bg-[#5a6c37]/10 text-[#5a6c37] flex items-center justify-center font-bold text-sm">4</div>
                                     </div>
                                     <div>
                                         <h4 class="font-bold text-slate-800 text-sm">Gunakan Saat Checkout</h4>
                                         <p class="text-xs text-gray-500 mt-1">Pilih voucher kamu di halaman Checkout untuk menikmati promonya.</p>
                                     </div>
                                </div>
                            </div>
                        </div>

                        <div class="border-t border-gray-100 pt-6">
                            <h3 class="font-bold text-gray-900 text-lg mb-3">Syarat & Ketentuan</h3>
                            <ul class="list-disc pl-5 space-y-2 text-xs text-gray-500 leading-relaxed marker:text-[#5a6c37]">
                                <li>Poin yang sudah ditukarkan tidak dapat dikembalikan.</li>
                                <li>Voucher berlaku selama 3 bulan sejak tanggal penukaran.</li>
                                <li>Voucher tidak dapat digabungkan dengan promo lainnya dalam satu transaksi.</li>
                                <li>Setiap transaksi hanya dapat menggunakan satu jenis voucher.</li>
                                <li>Manajemen berhak mengubah syarat dan ketentuan sewaktu-waktu tanpa pemberitahuan sebelumnya.</li>
                            </ul>
                        </div>
                     </div>
                </div>
            </div>
        </div>

        <!-- Sticky Bottom Action Bar -->
        <div class="flex-none w-full z-50 bg-white border-t border-gray-100 p-4 pb-safe shadow-[0_-5px_20px_rgba(0,0,0,0.05)]">
             <div class="flex items-center gap-4">
                  <!-- Qty Stepper -->
                  <div class="flex items-center border border-gray-200 rounded-full h-12 px-2 shrink-0">
                        <button @click="qty > 1 ? qty-- : null" class="w-8 h-full flex items-center justify-center text-slate-500 hover:text-slate-900 active:scale-90 transition-transform disabled:opacity-30" :disabled="qty <= 1">
                            <MinusIcon class="w-4 h-4" />
                        </button>
                        <span class="text-sm font-bold text-slate-900 min-w-[24px] text-center">{{ qty }}</span>
                        <button @click="qty++" class="w-8 h-full flex items-center justify-center text-slate-500 hover:text-slate-900 active:scale-90 transition-transform disabled:opacity-30" :disabled="pointsMissing() > 0">
                            <PlusIcon class="w-4 h-4" />
                        </button>
                  </div>

                  <!-- Redeem Button -->
                  <button 
                        @click="confirmRedeem"
                        :disabled="pointsMissing() > 0 || loading"
                        class="flex-1 h-12 rounded-full font-bold text-white shadow-lg shadow-[#5a6c37]/30 transition-all active:scale-[0.98] flex justify-center items-center gap-2"
                        :class="pointsMissing() > 0 ? 'bg-gray-300 cursor-not-allowed shadow-none text-gray-500' : 'bg-[#5a6c37] hover:bg-[#4a5c2e]'"
                    >
                        <Loader2Icon v-if="loading" class="w-5 h-5 animate-spin" />
                        <span v-else>Tukar {{ totalCost }} Poin</span>
                    </button>
             </div>
             
             <p v-if="pointsMissing() > 0" class="text-center text-xs text-red-500 mt-3 font-bold bg-red-50 py-1.5 rounded-lg">
                 Poin tidak cukup (Kurang {{ pointsMissing() }})
             </p>
        </div>
        </div>
    </div>
</template>

<script setup>
import { onMounted, ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useCustomerStore } from '../../../stores/customer';
import { useMemberAuthStore } from '../../../stores/memberAuth';
import { useToast } from 'vue-toastification';
import { ChevronLeftIcon, CoinsIcon, MinusIcon, PlusIcon, Loader2Icon } from 'lucide-vue-next';

const route = useRoute();
const router = useRouter();
const store = useCustomerStore();
const authStore = useMemberAuthStore();
const toast = useToast();

const reward = ref(null);
const qty = ref(1);
const loading = ref(false);
const scrollContainer = ref(null);
const scrollProgress = ref(0);
const headerOpacity = ref(0);

const member = computed(() => authStore.currentUser);

const handleScroll = (e) => {
    const scrollTop = e.target.scrollTop;
    scrollProgress.value = Math.min(scrollTop / 300, 1);
    headerOpacity.value = Math.min(scrollTop / 200, 1);
};

onMounted(async () => {
    const id = route.params.id;
    if (store.rewards.length === 0) {
        await store.fetchRewards();
    }
    reward.value = store.rewards.find(r => r.id === id);
    if (!reward.value) {
         router.replace('/rewards');
    }
    if (authStore.isAuthenticated) {
        authStore.fetchMe();
    }
});

const totalCost = computed(() => (reward.value ? reward.value.point_cost * qty.value : 0));

const pointsMissing = () => {
    const current = member.value?.points_balance || 0;
    return Math.max(0, totalCost.value - current);
};

const confirmRedeem = async () => {
     if (pointsMissing() > 0) return;
     
     if (!confirm(`Tukarkan ${totalCost.value} poin untuk ${qty.value}x ${reward.value.name}?`)) return;

     loading.value = true;
     try {
         let successCount = 0;
         for (let i = 0; i < qty.value; i++) {
             const success = await store.redeemReward(reward.value.id);
             if (success) successCount++;
             else break; 
         }
         
         if (successCount > 0) {
             await authStore.fetchMe(); // Refresh points
             toast.success(`Berhasil menukarkan ${successCount} voucher!`, {
                position: "top-left",
                toastClassName: "customer-toast"
            });
             router.push('/vouchers');
         }
     } finally {
         loading.value = false;
     }
};
</script>
