<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-end sm:items-center justify-center sm:p-4">
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity" @click="$emit('close')"></div>

        <!-- Sheet/Modal -->
        <div class="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl shadow-xl relative z-10 flex flex-col animate-in slide-in-from-bottom-10 fade-in duration-300">
            
            <!-- Handle (Mobile) -->
            <div class="w-full flex justify-center pt-3 pb-1 sm:hidden">
                <div class="w-12 h-1.5 bg-gray-300 rounded-full"></div>
            </div>

            <div class="p-6">
                <h2 class="text-xl font-bold text-center text-[#0f4d38] mb-6">Konfirmasi Pemesanan</h2>
                
                <!-- Order Type Badge -->
                <div class="bg-[#f8f9f5] rounded-2xl p-4 flex items-center gap-4 mb-6">
                    <div class="w-12 h-12 rounded-full bg-[#dbead5] flex items-center justify-center shrink-0">
                         <!-- Pickup Icon -->
                         <ShoppingBagIcon v-if="orderType === 'pickup'" class="w-6 h-6 text-[#0f4d38]" />
                         <!-- Dine In Icon/Utensils -->
                         <UtensilsIcon v-else class="w-6 h-6 text-[#0f4d38]" />
                    </div>
                    <span class="text-lg font-bold text-gray-900">
                        {{ orderType === 'pickup' ? 'Pick Up' : 'Dine In' }}
                    </span>
                </div>

                <!-- Conditional Instruction -->
                <div class="mb-6">
                    <!-- Label -->
                    <h3 class="text-base font-bold text-gray-900 mb-3">
                        {{ orderType === 'pickup' ? 'Ambil pesananmu di' : 'Informasi Pesanan' }}
                    </h3>

                    <!-- Pickup Cards -->
                    <div v-if="orderType === 'pickup'" class="bg-primary rounded-2xl p-5 flex items-center justify-between text-white relative overflow-hidden shadow-lg shadow-primary/20">
                         <!-- Decorative circles -->
                         <div class="absolute -right-4 -top-4 w-20 h-20 bg-white/10 rounded-full"></div>
                         <div class="absolute right-10 -bottom-10 w-24 h-24 bg-white/5 rounded-full"></div>

                         <div class="z-10 flex-1 pr-4">
                             <h3 class="font-bold text-base leading-tight">{{ settings.store_name || 'Store' }}</h3>

                         </div>
                         
                         <a 
                            v-if="settings.store_maps_link"
                            :href="settings.store_maps_link" 
                            target="_blank"
                            class="z-10 bg-white/20 backdrop-blur-sm text-white border border-white/30 text-[10px] font-bold px-2.5 py-1.5 rounded-lg flex items-center gap-1 hover:bg-white/30 transition-colors shadow-sm shrink-0"
                         >
                            View Maps
                            <MapPinIcon class="w-3 h-3" />
                         </a>
                    </div>

                    <!-- Dine In Instruction -->
                    <div v-else class="border border-gray-100 rounded-2xl p-4 flex items-center gap-4 shadow-sm bg-blue-50/50">
                        <div class="w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center shrink-0 text-blue-600">
                            <ArmchairIcon class="w-6 h-6" />
                        </div>
                        <div>
                            <p class="font-bold text-gray-900">Mohon menunggu di meja</p>
                            <p class="text-sm text-gray-500 mt-0.5">Server / Kasir akan memanggil nama Anda saat pesanan siap.</p>
                        </div>
                    </div>
                </div>

                <!-- Estimation -->
                <div class="bg-[#eef5f2] rounded-xl p-4 mb-8" :class="orderType === 'pickup' ? 'space-y-3' : 'flex items-center gap-3'">
                    <div class="flex items-center gap-3">
                        <div class="w-6 h-6 rounded-full bg-primary flex items-center justify-center shrink-0 text-white">
                            <ClockIcon class="w-3.5 h-3.5" />
                        </div>
                         <p class="text-sm font-bold text-gray-800">
                            Estimasi siap {{ orderType === 'pickup' ? 'diambil' : 'disajikan' }} dalam 10 menit
                        </p>
                    </div>

                    <div v-if="orderType === 'pickup'" class="flex items-center gap-3">
                        <div class="w-6 h-6 rounded-full bg-primary flex items-center justify-center shrink-0 text-white">
                            <MessageCircleIcon class="w-3.5 h-3.5" />
                        </div>
                        <p class="text-sm font-medium text-gray-700">
                            Kamu akan menerima notifikasi WhatsApp saat pesanan siap
                        </p>
                    </div>
                </div>

                <!-- Action Button -->
                <button 
                    @click="onConfirm"
                    class="w-full bg-primary hover:bg-[#0a3828] text-white font-bold text-lg py-4 rounded-full shadow-lg transition-transform active:scale-[0.98]"
                >
                    Pesan Sekarang
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ShoppingBagIcon, UtensilsIcon, StoreIcon, ClockIcon, ArmchairIcon, MapPinIcon, MessageCircleIcon } from 'lucide-vue-next';

defineProps({
    isOpen: Boolean,
    orderType: String, // 'pickup' | 'dine_in'
    settings: {
        type: Object,
        default: () => ({})
    }
});

const emit = defineEmits(['close', 'confirm']);

const onConfirm = () => {
    emit('confirm');
};
</script>
