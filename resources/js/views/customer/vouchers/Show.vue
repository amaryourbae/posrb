<template>
    <div class="fixed inset-0 w-full flex justify-center bg-gray-100 overflow-hidden font-sans">
        <div class="w-full max-w-md h-full flex flex-col relative">
         <!-- Sticky Header -->
        <div class="absolute top-0 left-0 right-0 z-50 w-full pointer-events-none transition-all duration-300">
             <div class="absolute inset-0 bg-white shadow-sm transition-opacity duration-300" :style="{ opacity: headerOpacity }"></div>
             
             <div class="relative z-10 px-4 py-3 flex justify-between items-center">
                 <button @click="$router.back()" 
                    class="flex w-10 h-10 items-center justify-center rounded-full transition-all active:scale-95 pointer-events-auto"
                    :class="headerOpacity > 0.8 ? 'bg-gray-100 text-gray-900 border-gray-200' : 'bg-black/20 backdrop-blur-md text-white border-white/10 hover:bg-black/30'">
                    <ChevronLeftIcon class="w-6 h-6" />
                </button>

                <span class="font-bold text-lg text-gray-900 absolute left-1/2 -translate-x-1/2 transition-all duration-300 transform translate-y-4 opacity-0 truncate max-w-[50%]"
                      :class="{ 'translate-y-0! opacity-100!': headerOpacity > 0.8 }">
                    Voucher Detail
                </span>
             </div>
        </div>

        <!-- Scroll Container -->
        <div ref="scrollContainer" @scroll="handleScroll" class="flex-1 overflow-y-auto relative bg-gray-100 scroll-smooth shadow-2xl [&::-webkit-scrollbar]:hidden">
             <!-- Sticky Hero Image (Parallax) -->
            <div class="sticky top-0 w-full h-96 z-0 shrink-0 overflow-hidden">
                <div v-if="voucher" class="absolute inset-0 bg-cover bg-center transition-transform duration-75 ease-out" 
                     :style="`background-image: url('${voucher.reward?.image_url || '/no-image.jpg'}'); transform: scale(${1 + scrollProgress * 0.1}) translateY(${scrollProgress * 30}px);`"></div>
                <div v-else class="absolute inset-0 bg-gray-200 animate-pulse"></div>
                <div class="absolute inset-0 bg-linear-to-b from-black/30 via-transparent to-black/10" :style="{ opacity: 1 - headerOpacity }"></div>
            </div>

            <!-- Content Sheet -->
            <div v-if="voucher" class="relative z-10 bg-white rounded-t-[2.5rem] min-h-screen -mt-20 shadow-[0_-10px_40px_rgba(0,0,0,0.1)] flex flex-col overflow-hidden pb-32">
                 <!-- Drag Handle -->
                <div class="flex justify-center pt-3 pb-1 opacity-50">
                    <div class="w-12 h-1.5 bg-gray-300 rounded-full"></div>
                </div>

                <div class="px-6 py-6 flex-1 flex flex-col">
                    <!-- Header Info -->
                    <div class="flex items-center justify-between mb-4">
                        <span class="text-xs font-bold px-3 py-1 rounded-full uppercase border"
                            :class="{
                                'bg-emerald-50 text-emerald-600 border-emerald-100': voucher.status === 'active',
                                'bg-gray-100 text-gray-500 border-gray-200': voucher.status !== 'active'
                            }">
                            {{ voucher.status }}
                        </span>
                    </div>

                    <h1 class="text-2xl font-bold tracking-tight text-gray-900 leading-tight mb-2">{{ voucher.reward?.name }}</h1>
                    
                    <div class="flex items-center gap-2 text-sm text-gray-500 mb-6">
                        <ClockIcon class="w-4 h-4" />
                        <span>Valid until <span class="font-bold text-gray-900">{{ formatDate(voucher.expires_at) }}</span></span>
                    </div>

                    <p class="text-sm text-gray-600 leading-relaxed mb-6">
                        {{ voucher.reward?.description || 'Gunakan voucher ini untuk mendapatkan produk gratis sesuai ketentuan yang berlaku.' }}
                    </p>

                    <div class="border-t border-b border-gray-100 py-4 mb-6 space-y-3">
                         <div class="flex justify-between items-center text-sm">
                             <span class="text-gray-500">Kode Voucher</span>
                             <span class="font-mono font-bold text-gray-900">{{ voucher.code }}</span>
                         </div>
                         <div class="flex justify-between items-center text-sm">
                             <span class="text-gray-500">Min. Transaksi</span>
                             <span class="font-bold text-gray-900">RP 0</span>
                         </div>
                    </div>

                    <!-- Accordions -->
                    <div class="space-y-4">
                        <div class="bg-gray-50 rounded-xl p-4">
                            <h3 class="font-bold text-gray-900 text-sm mb-2 flex items-center gap-2">
                                <InfoIcon class="w-4 h-4 text-primary" />
                                Syarat & Ketentuan
                            </h3>
                            <ul class="list-disc pl-5 space-y-1 text-xs text-gray-500">
                                <li>Voucher hanya berlaku untuk transaksi di aplikasi.</li>
                                <li>Tidak dapat digabungkan dengan promo lain.</li>
                                <li>Penggunaan voucher bersifat sekali pakai.</li>
                            </ul>
                        </div>

                         <div class="bg-gray-50 rounded-xl p-4">
                            <h3 class="font-bold text-gray-900 text-sm mb-2 flex items-center gap-2">
                                <ShoppingBagIcon class="w-4 h-4 text-primary" />
                                Cara Penggunaan
                            </h3>
                            <ul class="list-disc pl-5 space-y-1 text-xs text-gray-500">
                                <li>Pilih produk yang sesuai di menu.</li>
                                <li>Masuk ke halaman Checkout.</li>
                                <li>Pilih voucher ini di bagian "Voucher & Rewards".</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Sticky Bottom -->
        <div class="flex-none w-full z-50 bg-white border-t border-gray-100 p-4 pb-safe shadow-[0_-5px_20px_rgba(0,0,0,0.05)]">
            <button 
                @click="useVoucher"
                :disabled="voucher?.status !== 'active'"
                class="w-full h-12 rounded-full font-bold text-white shadow-lg transition-all active:scale-[0.98] flex justify-center items-center gap-2 text-base"
                :class="voucher?.status === 'active' ? 'bg-[#5a6c37] hover:bg-[#4a5c2e] shadow-[#5a6c37]/30' : 'bg-gray-300 cursor-not-allowed shadow-none'"
            >
                {{ voucher?.status === 'active' ? 'Gunakan Sekarang' : 'Tidak Tersedia' }}
            </button>
        </div>
        </div>
    </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useCustomerStore } from '../../../stores/customer';
import { useToast } from 'vue-toastification';
import { ChevronLeftIcon, ClockIcon, InfoIcon, ShoppingBagIcon } from 'lucide-vue-next';

const route = useRoute();
const router = useRouter();
const store = useCustomerStore();
const toast = useToast();

const voucher = ref(null);
const scrollContainer = ref(null);
const scrollProgress = ref(0);
const headerOpacity = ref(0);

const handleScroll = (e) => {
    const scrollTop = e.target.scrollTop;
    scrollProgress.value = Math.min(scrollTop / 300, 1);
    headerOpacity.value = Math.min(scrollTop / 200, 1);
};

onMounted(async () => {
    const id = route.params.id;
    voucher.value = store.myVouchers.find(v => v.id === id);
    if (!voucher.value) {
        voucher.value = await store.fetchMyVoucher(id);
    }
});

const formatDate = (dateString) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'short',
        year: 'numeric'
    }).format(date);
};

const useVoucher = () => {
    if (voucher.value.status !== 'active') return;
    
    // Set as selected voucher
    store.applyVoucher(voucher.value);
    
    // Redirect to Menu? Or Checkout?
    if (store.cart.length > 0) {
        router.push('/menu'); 
        toast.info("Voucher terpasang! Silakan pilih produknya.", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
    } else {
        router.push('/menu');
        toast.info("Voucher terpasang! Silakan pilih produknya.", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
    }
};
</script>
