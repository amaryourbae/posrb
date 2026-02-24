<template>
    <MobileLayout :showHeader="false">
        <template #header-custom>
            <div class="bg-white/95 backdrop-blur-md border-b border-gray-100 shadow-sm z-20">
                <!-- Title -->
                <div class="px-4 py-3 flex items-center justify-between relative">
                    <button @click="$router.back()" class="text-gray-900 flex w-10 h-10 shrink-0 items-center justify-center rounded-full hover:bg-gray-100 transition-colors">
                        <ChevronLeftIcon class="w-6 h-6" />
                    </button>
                    <h1 class="text-lg font-bold tracking-tight text-gray-900 absolute left-1/2 -translate-x-1/2">My Vouchers</h1>
                    <button @click="$router.push('/app/rewards')" class="text-xs font-bold text-primary h-10 flex items-center px-2 hover:bg-gray-50 rounded-lg transition-colors">
                        Tukar Poin
                    </button>
                </div>
            </div>
        </template>

        <div class="min-h-full bg-white pb-24">
            <div class="p-4 flex flex-col gap-4 pt-6">
                
                <!-- Loading State -->
                <div v-if="loading" class="space-y-4">
                     <div v-for="i in 3" :key="i" class="h-32 bg-gray-100 rounded-2xl animate-pulse"></div>
                </div>

                <!-- Empty State -->
                <div v-else-if="myVouchers.length === 0" class="flex flex-col items-center justify-center py-20 text-center">
                    <TicketIcon class="w-16 h-16 text-gray-200 mb-4" />
                    <h3 class="text-lg font-bold text-slate-900">Belum ada Voucher</h3>
                    <p class="text-gray-500 text-sm mt-1 max-w-[200px]">Tukarkan poin kamu dengan voucher menarik sekarang!</p>
                    <button @click="$router.push('/app/rewards')" class="mt-6 px-6 py-2.5 bg-primary text-white rounded-full font-bold text-sm shadow-md shadow-primary/20 active:scale-95 transition-transform">
                        Tukar Poin Sekarang
                    </button>
                </div>

                <!-- Voucher List -->
                <div v-else class="space-y-4">
                    <div 
                        v-for="voucher in myVouchers" 
                        :key="voucher.id" 
                        @click="viewVoucher(voucher)"
                        class="bg-[#fafaf9] rounded-2xl border border-gray-200 p-4 relative overflow-hidden flex flex-col transition-all cursor-pointer hover:border-gray-300 shadow-sm"
                        :class="{'opacity-60 grayscale bg-gray-100': voucher.status !== 'active'}"
                    >
                         <!-- Cutouts for ticket effect -->
                         <div class="absolute top-[65%] -left-2 w-4 h-4 bg-white rounded-full border-r border-[#e5e5e5]"></div>
                         <div class="absolute top-[65%] -right-2 w-4 h-4 bg-white rounded-full border-l border-[#e5e5e5]"></div>
                         
                        <div class="flex items-start gap-4 mb-3 flex-1">
                            <!-- Image -->
                            <div class="w-14 h-14 rounded-xl bg-gray-100 overflow-hidden shrink-0 border border-gray-100">
                                <img :src="voucher.reward?.image_url || '/no-image.jpg'" class="w-full h-full object-cover">
                            </div>
                            
                            <div class="flex-1 min-w-0">
                                <div class="flex justify-between items-start">
                                    <h3 class="font-bold text-slate-900 text-sm leading-snug mb-1 line-clamp-2">{{ voucher.reward?.name }}</h3>
                                    <span class="text-[10px] font-bold px-2 py-0.5 rounded-full uppercase ml-2 shrink-0 border"
                                        :class="{
                                            'bg-emerald-50 text-emerald-600 border-emerald-100': voucher.status === 'active',
                                            'bg-gray-100 text-gray-500 border-gray-200': voucher.status !== 'active'
                                        }"
                                    >
                                        {{ voucher.status }}
                                    </span>
                                </div>
                                <p class="text-xs text-gray-500 line-clamp-1">Valid until {{ formatDate(voucher.expires_at) }}</p>
                            </div>
                        </div>
                        
                        <!-- Dashed Line -->
                        <div class="border-t border-dashed border-gray-300 my-3 relative -mx-4 px-4"></div>

                        <div class="flex items-center justify-between pl-1">
                            <div class="flex items-center gap-1.5 text-xs text-gray-500">
                                <ClockIcon class="w-3.5 h-3.5" />
                                <span>Berlaku hingga <span class="font-bold text-slate-700">{{ formatDate(voucher.expires_at) }}</span></span>
                            </div>
                            <button class="text-xs font-bold text-primary flex items-center gap-1 group">
                                Detail
                                <ChevronRightIcon class="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </MobileLayout>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import { useCustomerStore } from '../../../stores/customer';
import { useRouter } from 'vue-router';
import { storeToRefs } from 'pinia';
import { ChevronLeftIcon, TicketIcon, ClockIcon, ChevronRightIcon } from 'lucide-vue-next';
import MobileLayout from '../../../layouts/MobileLayout.vue';

const router = useRouter();
const store = useCustomerStore();
const { myVouchers } = storeToRefs(store);
const loading = ref(false);

onMounted(async () => {
    loading.value = true;
    await store.fetchMyVouchers();
    loading.value = false;
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

const viewVoucher = (voucher) => {
    router.push(`/app/vouchers/${voucher.id}`);
};
</script>
