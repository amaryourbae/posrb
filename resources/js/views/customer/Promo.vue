<template>
    <MobileLayout :showHeader="false">
        <template #header-custom>
            <div class="bg-white/95 backdrop-blur-md border-b border-gray-100 shadow-sm z-20">
                <!-- Title -->
                <div class="px-4 py-3 flex items-center relative">
                    <button @click="router.back()" class="absolute left-4 z-10 p-1 -ml-1 text-gray-600 hover:text-gray-900">
                        <ChevronLeftIcon class="w-6 h-6" />
                    </button>
                    <h1 class="text-xl font-bold tracking-tight text-gray-900 w-full text-center">Voucher</h1>
                </div>
                <!-- Search Input -->
                <div class="px-4 pb-3">
                    <div class="flex items-center bg-gray-50 border border-gray-200 rounded-full px-4 py-2.5 shadow-sm focus-within:border-primary focus-within:ring-1 focus-within:ring-primary/20 transition-all">
                         <TagIcon class="w-5 h-5 text-primary fill-current rotate-90" />
                         <input 
                            v-model="promoCodeInput"
                            type="text" 
                            placeholder="Punya kode promo? Masukkan disini" 
                            class="bg-transparent border-none focus:ring-0 text-sm ml-2 w-full text-gray-700 placeholder:text-gray-400 outline-none"
                        />
                    </div>
                </div>
            </div>
        </template>

        <div class="min-h-full bg-white">

            <!-- Content -->
            <div class="p-4 flex flex-col gap-6 pt-6">
                <!-- Banner -->
                <div class="bg-primary rounded-xl p-5 flex items-center justify-between text-white relative overflow-hidden shadow-lg shadow-primary/20 cursor-pointer hover:scale-[1.01] transition-transform">
                     <!-- Decorative circles -->
                     <div class="absolute -right-4 -top-4 w-20 h-20 bg-white/10 rounded-full"></div>
                     <div class="absolute right-10 -bottom-10 w-24 h-24 bg-white/5 rounded-full"></div>

                    <div class="z-10 flex-1 pr-4">
                        <div class="flex items-center gap-2 mb-2">
                             <div class="w-6 h-6 rounded-full bg-white/20 flex items-center justify-center border border-white/30">
                                <PercentIcon class="w-3 h-3 text-white" />
                             </div>
                             <span class="text-[10px] font-bold uppercase tracking-wider opacity-90">Special Offer</span>
                        </div>
                        <h3 class="font-bold text-sm leading-tight">Mau lebih banyak diskon tiap hari? <br>Yuk jadi bagian dari Ruang Bincang!</h3>
                    </div>
                    <ChevronRightIcon class="w-5 h-5 text-white z-10" />
                </div>

                <!-- Voucher List -->
                <div>
                    <div class="flex justify-between items-center mb-4">
                        <h2 class="text-lg font-bold text-slate-900">Voucher Belanja</h2>
                        <span class="text-xs text-gray-400 font-medium">{{ promos.length }} voucher</span>
                    </div>

                    <div v-if="loading" class="space-y-4">
                         <div v-for="i in 3" :key="i" class="h-40 bg-gray-100 rounded-xl animate-pulse"></div>
                    </div>

                    <div v-else-if="promos.length === 0" class="flex flex-col items-center justify-center py-20 text-center">
                        <TicketIcon class="w-16 h-16 text-gray-300 mb-4" />
                        <h3 class="text-lg font-bold text-gray-900">No Active Promos</h3>
                        <p class="text-gray-500 text-sm mt-1">Check back later for exciting offers!</p>
                    </div>

                    <div v-else class="space-y-4">
                        <!-- Voucher Card -->
                        <div 
                            v-for="promo in promos" 
                            :key="promo.id" 
                            class="bg-[#fafaf9] rounded-2xl border border-gray-200 p-4 relative overflow-hidden flex flex-col transition-all"
                            :class="{'opacity-60 grayscale': !isUsable(promo)}"
                        >
                             <!-- Cutouts for visual ticket effect -->
                             <div class="absolute top-[60%] -left-2 w-4 h-4 bg-white rounded-full border-r border-[#e5e5e5]"></div>
                             <div class="absolute top-[60%] -right-2 w-4 h-4 bg-white rounded-full border-l border-[#e5e5e5]"></div>
                             
                            <div class="flex items-start gap-4 mb-3 flex-1">
                                <!-- Icon/Image -->
                                <div class="w-12 h-12 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center shrink-0">
                                     <TicketIcon class="w-6 h-6 text-primary" />
                                </div>
                                <div>
                                    <h3 class="font-bold text-slate-900 text-sm leading-snug mb-1">{{ promo.name }}</h3>
                                    <p class="text-xs text-gray-400 line-clamp-2">-</p> 
                                </div>
                            </div>
                            
                            <!-- Dashed Line -->
                            <div class="border-t border-dashed border-gray-300 my-3 relative -mx-4 px-4"></div>

                            <div class="flex items-end justify-between pl-1">
                                <div class="flex gap-6">
                                    <div>
                                        <p class="text-[10px] text-gray-400 mb-0.5">Berlaku Hingga</p>
                                        <p class="text-xs font-bold text-slate-700">{{ formatDate(promo.end_date) }}</p>
                                    </div>
                                    <div>
                                        <p class="text-[10px] text-gray-400 mb-0.5">Min Transaksi</p>
                                        <p class="text-xs font-bold text-slate-700">{{ promo.min_purchase > 0 ? formatCurrency(promo.min_purchase) : '-' }}</p>
                                    </div>
                                </div>
                                <button 
                                    @click="selectPromo(promo)"
                                    :disabled="!isUsable(promo)"
                                    class="text-xs font-bold px-6 py-2 rounded-full transition-colors shadow-sm active:scale-95 disabled:cursor-not-allowed disabled:bg-gray-300 disabled:text-gray-500 disabled:shadow-none"
                                    :class="isUsable(promo) ? 'bg-primary text-white hover:bg-primary/90' : ''"
                                >
                                    {{ isUsable(promo) ? 'Pakai' : 'Tidak Berlaku' }}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </MobileLayout>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { TicketIcon, ClockIcon, TagIcon, PercentIcon, ChevronRightIcon, ChevronLeftIcon } from 'lucide-vue-next';
import { useCustomerStore } from '../../stores/customer';
import MobileLayout from '../../layouts/MobileLayout.vue';

import { useRouter } from 'vue-router';
import { useToast } from "vue-toastification";

const store = useCustomerStore();
const router = useRouter();
const toast = useToast();

const promos = computed(() => store.promos);
const loading = ref(true);
const promoCodeInput = ref('');

const formatNumber = (num) => new Intl.NumberFormat('id-ID').format(num);
const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val);
const formatDate = (date) => new Date(date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });

const isUsable = (promo) => {
    return store.cartTotal >= Number(promo.min_purchase || 0);
};

const selectPromo = (promo) => {
    if (!isUsable(promo)) {
        toast.warning(`Min. transaksi ${formatCurrency(promo.min_purchase)} untuk menggunakan voucher ini.`, {
            position: "top-left",
            toastClassName: "customer-toast"
        });
        return;
    }
    store.applyVoucher(promo);
    toast.success('Voucher berhasil digunakan!', {
        position: "top-left",
        toastClassName: "customer-toast"
    });
    router.back();
};

onMounted(async () => {
    if (store.promos.length === 0) {
        await store.fetchPromos();
    }
    loading.value = false;
});
</script>
