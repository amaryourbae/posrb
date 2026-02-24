<template>
<MobileLayout :showHeader="false" :showFooter="false">
    <div class="flex flex-col min-h-screen bg-[#F8F9FA] font-sans text-[#333333] pb-safe">
        <!-- Header -->
        <header class="sticky top-0 z-50 bg-white/95 backdrop-blur-sm px-5 py-4 flex items-center justify-center shadow-[0_1px_2px_rgba(0,0,0,0.03)]">
            <button @click="$router.go(-1)" class="absolute left-5 w-8 h-8 flex items-center justify-center -ml-2 text-slate-900 active:opacity-70">
                <ChevronLeftIcon class="w-6 h-6" />
            </button>
            <h1 class="text-xl font-bold tracking-tight text-slate-900">Detail Pesanan</h1>
        </header>

        <main class="flex-1 w-full overflow-y-auto no-scrollbar pb-32" v-if="order">
            
            <!-- Section: Detail Pesanan -->
            <div class="bg-white p-5 mb-2">
                <div class="flex justify-between items-baseline mb-5">
                    <h2 class="text-[15px] font-bold text-slate-900">Detail Pesanan</h2>
                    <span class="text-xs text-slate-400 font-medium">Total Item: {{ order.items.length }}</span>
                </div>

                <div class="space-y-6">
                    <div v-for="item in order.items" :key="item.id" class="flex gap-4">
                        <!-- Product Image -->
                        <div class="w-[60px] h-[60px] rounded-xl bg-gray-100 overflow-hidden shrink-0">
                            <img :src="item.product?.image_url || '/no-image.jpg'" class="w-full h-full object-cover" />
                        </div>
                        
                        <!-- Middle: Details -->
                        <div class="flex-1 min-w-0 pr-2">
                            <h3 class="text-sm font-bold text-slate-900 leading-tight mb-1">{{ getProductName(item) }}</h3>
                            <!-- Modifiers -->
                            <p v-if="getModifiersText(item)" 
                               class="text-[11px] text-slate-500 leading-relaxed max-w-[90%] transition-all duration-200"
                               :class="{'line-clamp-1': !isItemsExpanded}">
                                {{ getModifiersText(item) }}
                            </p>
                        </div>

                        <!-- Right: Price & Qty -->
                        <div class="text-right shrink-0 flex flex-col items-end">
                            <p class="text-sm font-semibold text-slate-900">{{ formatCurrency(item.total_price) }}</p>
                            <p class="text-xs text-slate-400 mt-1 font-medium">{{ item.quantity }}x</p>
                        </div>
                    </div>
                </div>

                <!-- Toggle Items -->
                <div class="mt-6 flex justify-center">
                    <button @click="isItemsExpanded = !isItemsExpanded" class="flex items-center gap-1 text-[11px] font-bold text-[#007042] bg-transparent active:opacity-70 transition-opacity">
                        {{ isItemsExpanded ? 'Sembunyikan' : 'Tampilkan' }}
                        <component :is="isItemsExpanded ? ChevronUpIcon : ChevronDownIcon" class="w-3 h-3" />
                    </button>
                </div>
            </div>

            <!-- Section: Rincian Pembayaran -->
            <div class="bg-white p-5 mb-2">
                <h2 class="text-[15px] font-bold text-slate-900 mb-4">Rincian Pembayaran</h2>
                
                <!-- Expanded Details -->
                <div v-show="isPaymentExpanded" class="space-y-2 mb-4 border-b border-dashed border-gray-100 pb-4">
                    <div class="flex justify-between items-center text-xs text-slate-500">
                        <span>Subtotal</span>
                        <span>{{ formatCurrency(order.subtotal) }}</span>
                    </div>
                    <div class="flex justify-between items-center text-xs text-primary" v-if="order.discount_amount > 0">
                        <span>Diskon Voucher</span>
                        <span>-{{ formatCurrency(order.discount_amount) }}</span>
                    </div>
                    <div class="flex justify-between items-center text-xs text-slate-500">
                        <span>PB1 ({{ Math.round((order.tax_amount / (order.subtotal - order.discount_amount)) * 100) }}%)</span>
                        <span>{{ formatCurrency(order.tax_amount) }}</span>
                    </div>
                </div>

                <div class="flex justify-between items-baseline mb-2">
                    <span class="text-sm font-semibold text-slate-900">Total Pembayaran</span>
                    <span class="text-[15px] font-bold text-slate-900">{{ formatCurrency(order.grand_total) }}</span>
                </div>
                
                <div class="flex justify-between items-center">
                    <div class="flex items-center gap-2">
                        <!-- Simulated Payment Icon -->
                        <div class="w-6 h-4 border border-gray-200 rounded flex items-center justify-center p-0.5">
                            <span class="text-[8px] font-bold text-slate-600 uppercase">{{ order.payment_method.slice(0,4) }}</span>
                        </div>
                        <span class="text-sm text-slate-500 uppercase font-medium">{{ order.payment_method }}</span>
                    </div>
                    <!-- Points -->
                    <div class="flex items-center gap-1">
                        <span class="text-xs font-bold text-[#007042]">+{{ calculatePoints(order.grand_total) }} Poin</span>
                        <InfoIcon class="w-3 h-3 text-slate-300" />
                    </div>
                </div>

                <!-- Toggle Payment -->
                <div class="mt-5 flex justify-center">
                    <button @click="isPaymentExpanded = !isPaymentExpanded" class="flex items-center gap-1 text-[11px] font-bold text-[#007042] bg-transparent active:opacity-70 transition-opacity">
                        {{ isPaymentExpanded ? 'Sembunyikan' : 'Selengkapnya' }}
                        <component :is="isPaymentExpanded ? ChevronUpIcon : ChevronDownIcon" class="w-3 h-3" />
                    </button>
                </div>
            </div>

            <!-- Section: Order Info -->
            <div class="bg-white p-5 space-y-3">
                <div class="flex justify-between items-start text-[13px]">
                    <span class="text-slate-500">ID Pesanan</span>
                    <div class="flex items-center gap-2 text-slate-900 font-medium">
                        <span>#{{ order.order_number }}</span>
                        <CopyIcon class="w-3.5 h-3.5 text-[#007042] cursor-pointer" @click="copyToClipboard(order.order_number)" />
                    </div>
                </div>
                <div class="flex justify-between items-start text-[13px]">
                    <span class="text-slate-500">Waktu Pembayaran</span>
                    <span class="text-slate-900 font-medium">{{ formatDateFull(order.created_at) }}</span>
                </div>
                <div class="flex justify-between items-start text-[13px]">
                    <span class="text-slate-500">Metode Pemesanan</span>
                    <span class="text-slate-900 font-medium">{{ formatOrderType(order.order_type) }}</span>
                </div>
            </div>

            <!-- E-Receipt Button (Scrollable) -->
            <div class="p-5">
                <button @click="$router.push(`/app/orders/${order.id}/receipt`)" class="w-full h-11 rounded-full border border-primary text-primary font-bold text-[14px] active:bg-[#007042]/5 transition-colors bg-white">
                    Lihat E-Receipt
                </button>
            </div>
        </main>

        <main v-else-if="loading" class="flex-1 w-full overflow-y-auto no-scrollbar pt-4 pb-32 animate-pulse">
            <!-- Skeleton Loader -->
            <div class="bg-white p-5 mb-2 mt-2">
                <div class="h-6 w-32 bg-gray-200 rounded mb-5"></div>
                <div class="space-y-6">
                    <div v-for="i in 2" :key="i" class="flex gap-4">
                        <div class="w-[60px] h-[60px] rounded-xl bg-gray-200 shrink-0"></div>
                        <div class="flex-1 space-y-2">
                            <div class="h-4 w-3/4 bg-gray-200 rounded"></div>
                            <div class="h-3 w-1/2 bg-gray-200 rounded"></div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-white p-5 mb-2 space-y-4">
                <div class="h-5 w-40 bg-gray-200 rounded mb-4"></div>
                <div class="h-20 bg-gray-200 rounded"></div>
                <div class="flex justify-between">
                    <div class="h-5 w-24 bg-gray-200 rounded"></div>
                    <div class="h-6 w-32 bg-gray-200 rounded"></div>
                </div>
            </div>
        </main>

        <!-- Bottom Actions (Sticky 'Beli Lagi' Only) -->
        <div class="fixed bottom-0 left-0 right-0 px-5 py-4 bg-white border-t border-gray-100 flex flex-col gap-3 pb-safe z-40 shadow-[0_-4px_20px_rgba(0,0,0,0.03)] mx-auto max-w-md" v-if="order">
            <button @click="buyAgain" :disabled="reordering" class="w-full h-11 rounded-full bg-primary text-white font-bold text-[14px] shadow-lg shadow-[#007042]/20 hover:bg-[#005c36] transition-colors active:scale-[0.98] disabled:opacity-70 flex justify-center items-center gap-2">
                <span v-if="!reordering">Beli Lagi</span>
                <span v-else class="flex items-center gap-2">
                    <div class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                    Memproses...
                </span>
            </button>
        </div>
    </div>
</MobileLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import MobileLayout from '../../layouts/MobileLayout.vue';
import { ChevronLeftIcon, CopyIcon, ChevronUpIcon, ChevronDownIcon, InfoIcon } from 'lucide-vue-next';
import api from '../../api/axios';
import { useCustomerStore } from '../../stores/customer';
import { useProductDisplay } from '../../composables/useProductDisplay';
import { useToast } from 'vue-toastification';

const route = useRoute();
const router = useRouter();
const customerStore = useCustomerStore();
const toast = useToast();
const { getProductName, getVisibleModifiers, getModifierDisplayName } = useProductDisplay();

const order = ref(null);
const loading = ref(true);
const reordering = ref(false);

// State for Collapsibles
const isItemsExpanded = ref(false);
const isPaymentExpanded = ref(false);

const fetchOrder = async () => {
    loading.value = true;
    try {
        const token = localStorage.getItem('member_token');
        const response = await api.get(`/public/member/orders/${route.params.id}`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        order.value = response.data?.data || response.data || null;
    } catch (e) {
        console.error(e);
        toast.error("Gagal memuat pesanan", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
        router.go(-1);
    } finally {
        loading.value = false;
    }
};

const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(val);

const formatDateFull = (dateString) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false
    }).format(date);
};

const formatOrderType = (type) => {
    if (type === 'dine_in') return 'Dine In';
    if (type === 'pickup_app' || type === 'pickup') return 'Pickup Order';
    return type.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
};

const calculatePoints = (total) => Math.floor(total / 10000);

const getModifiersText = (item) => {
    let parts = [];
    const mods = getVisibleModifiers(item);
    if (mods && Array.isArray(mods)) {
        parts = mods.map(m => getModifierDisplayName(m));
    }
    if (item.note) parts.push(`"${item.note}"`);
    return parts.join(', ');
};

const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    toast.info("Disalin", {
        position: "top-left",
        toastClassName: "customer-toast"
    });
};

const buyAgain = async () => {
    reordering.value = true;
    try {
        let addedCount = 0;
        for (const item of order.value.items) {
            const productPayload = {
                id: item.product_id,
                name: item.product.name,
                price: item.product.price, 
                image_url: item.product?.image_url
            };
            
            if (!item.product) continue; 

            customerStore.addToCart(productPayload, {
                quantity: item.quantity,
                modifiers: item.modifiers || [],
                notes: item.note || ''
            });
            addedCount++;
        }
        
        if (addedCount > 0) {
            await new Promise(resolve => setTimeout(resolve, 500)); 
            toast.success("Masuk Keranjang", {
                position: "top-left",
                toastClassName: "customer-toast"
            });
            router.push('/app/cart');
        } else {
            toast.error("Produk tidak tersedia", {
                position: "top-left",
                toastClassName: "customer-toast"
            });
        }
    } catch (e) {
        console.error(e);
    } finally {
        reordering.value = false;
    }
};

onMounted(() => {
    fetchOrder();
});
</script>
