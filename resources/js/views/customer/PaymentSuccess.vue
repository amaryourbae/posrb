<template>
    <div class="min-h-screen bg-white font-sans text-gray-900 flex justify-center items-center">
        <div class="w-full max-w-md bg-white min-h-screen flex flex-col items-center justify-center p-8 text-center relative overflow-hidden">
            
            <!-- Confetti / Decoration (Optional CSS or static) -->
            <div class="absolute top-0 left-0 w-full h-full pointer-events-none overflow-hidden">
                <div class="absolute top-10 left-10 w-32 h-32 bg-primary/5 rounded-full blur-3xl"></div>
                <div class="absolute bottom-10 right-10 w-40 h-40 bg-green-100 rounded-full blur-3xl"></div>
            </div>

            <!-- Content -->
            <div class="relative z-10 flex flex-col items-center animate-in zoom-in-95 fade-in duration-500">
                <!-- Success Icon -->
                <div class="w-24 h-24 bg-green-50 rounded-full flex items-center justify-center mb-6 shadow-lg shadow-green-100 ring-8 ring-green-50/50 animate-bounce">
                    <CircleCheckBigIcon class="w-12 h-12 text-primary" />
                </div>
                
                <h1 class="text-2xl font-bold text-gray-900 mb-2">Pembayaran Berhasil!</h1>
                <p class="text-gray-500 text-sm mb-8 leading-relaxed max-w-xs mx-auto">
                    Terima kasih! Pesanan kamu telah kami terima dan akan segera diproses.
                </p>

                <!-- Order Detail Card -->
                <div class="w-full bg-gray-50 rounded-2xl p-5 border border-gray-100 mb-8 max-w-sm">
                    <p class="text-xs text-gray-400 font-bold uppercase tracking-wider mb-1">Order ID</p>
                    <p class="text-xl font-bold text-gray-900 tracking-tight">{{ orderNumber }}</p>
                    
                    <div class="w-full h-px bg-gray-200 my-4 border-dashed"></div>
                    
                    <div class="flex justify-between items-center text-sm">
                        <span class="text-gray-500">Estimasi Selesai</span>
                        <span class="font-bold text-primary">~15 Menit</span>
                    </div>
                </div>

                <!-- Actions -->
                <div class="w-full space-y-3 max-w-sm">
                    <button 
                        @click="router.push('/')" 
                        class="w-full bg-primary hover:bg-[#0a3828] text-white font-bold py-4 rounded-xl shadow-lg shadow-primary/20 transition-transform active:scale-[0.98]"
                    >
                        Kembali ke Menu
                    </button>
                    <!-- Optional: View Order Status link -->
                    <!-- 
                    <button 
                        @click="router.push(`/orders/${orderId}`)"
                        class="w-full bg-white border border-gray-200 text-gray-700 font-bold py-3.5 rounded-xl hover:bg-gray-50 transition"
                    >
                        Lihat Status Pesanan
                    </button>
                    -->
                </div>
            </div>

        </div>
    </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { CircleCheckBigIcon } from 'lucide-vue-next';
import api from '../../api/axios';

const router = useRouter();
const route = useRoute();

const orderId = computed(() => route.params.id);
const order = ref(null);

onMounted(async () => {
    if (orderId.value) {
        try {
            const res = await api.get(`/public/orders/${orderId.value}`);
            order.value = res.data?.data || res.data || {};
        } catch (e) {
            console.error("Failed to fetch order", e);
        }
    }
});

const orderNumber = computed(() => {
    if (order.value?.order_number) return order.value.order_number;
    if (orderId.value && !String(orderId.value).includes('object')) {
        return `#${String(orderId.value).padStart(6, '0')}`;
    }
    return '...';
});

</script>
