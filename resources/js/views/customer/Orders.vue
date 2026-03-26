<template>
<MobileLayout :showHeader="false" :showFooter="true">
        <!-- Header -->
        <header class="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100 flex items-center gap-3 px-5 py-4">
            <button @click="$router.go(-1)" class="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100 -ml-2">
                <ChevronLeftIcon class="w-5 h-5 text-slate-700" />
            </button>
            <h1 class="text-xl font-bold tracking-tight text-slate-900">Pesanan Saya</h1>
        </header>

        <main class="flex-1 w-full px-5 pb-5 pt-4 space-y-4 overflow-y-auto no-scrollbar">
            <div v-if="loading" class="space-y-4">
                <div v-for="i in 3" :key="i" class="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 h-32 animate-pulse">
                    <div class="h-4 bg-gray-200 rounded w-1/3 mb-4"></div>
                    <div class="h-3 bg-gray-100 rounded w-2/3 mb-2"></div>
                    <div class="h-3 bg-gray-100 rounded w-1/2"></div>
                </div>
            </div>

            <div v-else-if="orders.length === 0" class="flex flex-col items-center justify-center py-20 text-center">
                <div class="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mb-4 text-gray-400">
                    <ShoppingBagIcon class="w-10 h-10" />
                </div>
                <h3 class="text-lg font-bold text-slate-900">Belum ada pesanan</h3>
                <p class="text-slate-500 text-sm mt-1">Yuk pesan kopi favoritmu sekarang!</p>
                <button @click="$router.push('/order')" class="mt-6 bg-primary text-white font-bold py-3 px-6 rounded-xl shadow-lg shadow-primary/20">
                    Pesan Sekarang
                </button>
            </div>

            <div v-else class="space-y-4">
                <div v-for="order in orders" :key="order.id" @click="$router.push(`/orders/${order.id}`)" class="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 active:scale-[0.99] transition-transform cursor-pointer">
                    <!-- Header & Status -->
                    <div class="flex justify-between items-start mb-3 pb-3 border-b border-dashed border-gray-100">
                        <div>
                            <div class="flex items-center gap-1.5 mb-1.5">
                                <span class="text-[10px] font-bold bg-blue-50 text-blue-600 px-2 py-0.5 rounded border border-blue-100">
                                    Pemesanan via Aplikasi
                                </span>
                            </div>
                            <p class="text-[11px] font-medium text-slate-400">
                                #{{ order.order_number.split('-').pop() }} • {{ formatDate(order.created_at) }}
                            </p>
                        </div>
                        <span 
                            class="text-[10px] font-bold px-2.5 py-1 rounded-full border uppercase"
                            :class="getStatusClass(order.payment_status)"
                        >
                            {{ order.payment_status }}
                        </span>
                    </div>

                    <!-- Product Summary -->
                    <div class="mb-3">
                         <h3 class="text-sm font-bold text-slate-900 line-clamp-1 leading-relaxed">
                            {{ order.items.map(item => `${item.quantity}x ${getProductName(item)}`).join(', ') }}
                        </h3>
                    </div>

                    <!-- Footer -->
                    <div class="flex justify-between items-center">
                        <span class="text-[11px] font-medium text-slate-500">Total Pembayaran</span>
                        <span class="text-sm font-bold text-primary">{{ formatCurrency(order.grand_total) }}</span>
                    </div>
                </div>
            </div>
        </main>

</MobileLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import MobileLayout from '../../layouts/MobileLayout.vue';
import { ChevronLeftIcon, ShoppingBagIcon } from 'lucide-vue-next'; 
import api from '../../api/axios';
import { useMemberAuthStore } from '../../stores/memberAuth';
import { useProductDisplay } from '../../composables/useProductDisplay';
import { useToast } from 'vue-toastification';

const { getProductName, getVisibleModifiers } = useProductDisplay();

const orders = ref([]);
const loading = ref(true);
const authStore = useMemberAuthStore();
const toast = useToast();

const fetchOrders = async () => {
    loading.value = true;
    try {
        const token = localStorage.getItem('member_token');
        const response = await api.get('/public/member/orders', {
            headers: { Authorization: `Bearer ${token}` }
        });
        const rawData = response.data?.data || response.data || [];
        orders.value = Array.isArray(rawData) ? rawData : [];
    } catch (e) {
        console.error(e);
        toast.error("Gagal memuat riwayat pesanan", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
    } finally {
        loading.value = false;
    }
};

const formatDate = (dateString) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('id-ID', {
        day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit'
    }).format(date);
};

const formatCurrency = (val) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(val);
};

const getStatusClass = (status) => {
    switch(status) {
        case 'paid': return 'bg-emerald-50 text-emerald-600 border-emerald-100';
        case 'pending': return 'bg-yellow-50 text-yellow-600 border-yellow-100';
        case 'failed': 
        case 'cancelled': return 'bg-red-50 text-red-600 border-red-100';
        default: return 'bg-gray-50 text-gray-600 border-gray-100';
    }
};

onMounted(() => {
    fetchOrders();
});
</script>

<style scoped>
.no-scrollbar::-webkit-scrollbar {
    display: none;
}
.no-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
}
</style>
