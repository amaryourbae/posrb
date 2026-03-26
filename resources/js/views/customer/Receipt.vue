<template>
<MobileLayout :showHeader="false" :showFooter="false">
    <div class="flex flex-col min-h-screen bg-white font-sans text-slate-900 pb-safe">
        <!-- Header -->
        <header class="sticky top-0 z-50 bg-white/95 backdrop-blur-sm px-5 py-4 flex items-center justify-between border-b border-gray-50">
            <button @click="$router.go(-1)" class="w-8 h-8 flex items-center justify-center -ml-2 text-slate-900 active:opacity-70">
                <ChevronLeftIcon class="w-6 h-6" />
            </button>
            <h1 class="text-xl font-bold tracking-tight text-slate-900">E-Receipt</h1>
            <button @click="fetchOrder" class="w-8 h-8 flex items-center justify-center -mr-2 text-slate-900 active:rotate-180 transition-transform">
                <RotateCwIcon class="w-5 h-5" />
            </button>
        </header>

        <main id="receipt-content" class="flex-1 w-full px-6 pt-6 pb-32 overflow-y-auto no-scrollbar flex flex-col" v-if="order">
            
            <!-- Store Info -->
            <div class="text-center mb-6 flex flex-col items-center">
                <img v-if="settings?.store_logo" :src="logoBase64 || settings.store_logo" class="h-12 w-auto object-contain mb-2 brightness-0" />
                <h2 class="text-xl font-bold text-slate-900 mb-1">{{ settings?.store_name || 'Ruang Bincang Coffee' }}</h2>
                <div class="text-xs text-slate-500 space-y-0.5 leading-relaxed">
                    <p>{{ settings?.store_address || 'Jl. Kopi No. 1, Srono' }}</p>
                    <p v-if="settings?.store_phone">{{ settings.store_phone }}</p>
                </div>
            </div>

            <!-- Dotted Divider -->
            <div class="border-b-2 border-dashed border-gray-200 mb-6"></div>

            <!-- Large Order Number -->
            <div class="text-center mb-6">
                <h1 class="text-4xl font-extrabold text-slate-900 mb-1">{{ order.order_number.split('-').pop() }}</h1>
                <p class="text-sm font-medium text-slate-600">{{ formatOrderType(order.order_type) }}</p>
            </div>

            <!-- Customer & Order Info -->
            <div class="text-[13px] text-slate-600 space-y-1 mb-6">
                <p class="flex gap-1">
                    <span>Nama Customer:</span>
                    <span class="uppercase font-semibold text-slate-900">{{ order.customer_name }}</span>
                </p>
                <p>{{ formatDateFull(order.created_at) }}</p>
                <p>#{{ order.order_number }}</p>
            </div>

            <div class="border-b-2 border-dashed border-gray-200 mb-4"></div>

            <!-- Items Header -->
            <div class="flex justify-between font-bold text-sm text-slate-900 mb-4">
                <span>Order</span>
                <span>Total Order: {{ order.items.length }}</span>
            </div>

            <!-- Items List -->
            <div class="space-y-4 mb-6">
                <div v-for="item in order.items" :key="item.id">
                    <div class="flex justify-between items-start text-sm">
                        <div class="flex gap-2">
                             <span class="text-slate-900 w-5 shrink-0">{{ item.quantity }} x</span>
                             <span class="text-slate-900 font-medium">{{ getProductName(item) }}</span>
                        </div>
                        <span class="text-slate-900 font-medium shrink-0">{{ formatCurrency(item.unit_price * item.quantity) }}</span>
                    </div>
                </div>
            </div>

            <div class="border-b-2 border-dashed border-gray-200 mb-4"></div>

            <!-- Subtotals -->
            <div class="space-y-2 mb-4 text-[13px]">
                <div class="flex justify-between text-slate-600">
                    <span>Sub Total</span>
                    <span>{{ formatCurrency(order.subtotal) }}</span>
                </div>
                <!-- Voucher if any -->
                <div class="flex justify-between text-primary" v-if="order.discount_amount > 0">
                    <span>Voucher Discount</span>
                    <span>-{{ formatCurrency(order.discount_amount) }}</span>
                </div>
                <div class="flex justify-between font-bold text-slate-900 mt-2 text-sm">
                    <span>SUBTOTAL</span>
                    <span>{{ formatCurrency(order.grand_total - order.tax_amount) }}</span>
                </div>
            </div>

            <div class="border-b-2 border-dashed border-gray-200 mb-4"></div>

            <!-- Tax -->
            <template v-if="order.tax_amount > 0">
                <div class="space-y-2 mb-4 text-[13px] text-slate-600">
                    <div class="flex justify-between">
                        <span>Net sales</span>
                        <span>{{ formatCurrency(order.subtotal - order.discount_amount) }}</span>
                    </div>
                    <div class="flex justify-between">
                        <span>PB1 {{ Math.round((order.tax_amount / (order.grand_total - order.tax_amount)) * 100) || 10 }}%</span>
                        <span>{{ formatCurrency(order.tax_amount) }}</span>
                    </div>
                </div>

                <div class="border-b-2 border-dashed border-gray-200 mb-4"></div>
            </template>

            <!-- Grand Total -->
            <div class="flex justify-between items-center mb-1">
                <span class="font-bold text-slate-900 text-[15px]">Total Pembayaran</span>
                <span class="font-bold text-slate-900 text-[15px]">{{ formatCurrency(order.grand_total) }}</span>
            </div>
            <div class="flex justify-between items-center mb-8">
                <span class="text-xs text-slate-500">Metode Pembayaran</span>
                 <span class="text-xs font-bold text-slate-700 uppercase">{{ order.payment_method }}</span>
            </div>

            <!-- Footer Message -->
            <div class="text-center mb-8 px-8">
                <h3 class="font-medium text-lg text-slate-800 mb-1">Terima Kasih</h3>
                <p class="text-xs text-slate-500 leading-relaxed">
                    {{ settings?.receipt_footer || 'Dapatkan 1 minuman gratis dan berbagai keuntungan dengan mengumpulkan poin.' }}
                </p>
                <p class="text-xs text-slate-500 mt-1" v-if="settings?.store_website">{{ settings.store_website }}</p>
            </div>

        </main>

        <main v-else-if="loading" class="flex-1 flex items-center justify-center">
            <div class="animate-spin rounded-full h-8 w-8 border-2 border-gray-200 border-t-[#007042]"></div>
        </main>

        <!-- Bottom Actions -->
        <div class="px-5 pt-4 pb-safe bg-white border-t border-gray-100 flex gap-3 z-40 fixed bottom-0 left-0 right-0 mx-auto max-w-md shadow-[0_-4px_20px_rgba(0,0,0,0.03)]" v-if="order">
            <button @click="downloadPdf" class="flex-1 h-12 rounded-full border border-gray-200 text-slate-700 font-bold text-[14px] flex items-center justify-center gap-2 active:bg-gray-50 transition-colors">
                <DownloadIcon class="w-4 h-4" />
                Download
            </button>
            <button @click="shareReceipt" class="flex-1 h-12 rounded-full bg-primary text-white font-bold text-[14px] flex items-center justify-center gap-2 active:brightness-90 transition-colors shadow-lg shadow-primary/20">
                <Share2Icon class="w-4 h-4" />
                Bagikan
            </button>
        </div>
    </div>
</MobileLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import MobileLayout from '../../layouts/MobileLayout.vue';
import { ChevronLeftIcon, RotateCwIcon, DownloadIcon, Share2Icon } from 'lucide-vue-next';
import api from '../../api/axios';
import { useCustomerStore } from '../../stores/customer';
import { useProductDisplay } from '../../composables/useProductDisplay';
import { useToast } from 'vue-toastification';

import html2pdf from 'html2pdf.js';

const route = useRoute();
const router = useRouter();
const customerStore = useCustomerStore();
const { getProductName, getVisibleModifiers, getModifierDisplayName } = useProductDisplay();
const toast = useToast();

const order = ref(null);
const loading = ref(true);
const settings = ref(null);
const logoBase64 = ref(null);
const isDownloading = ref(false);

const convertLogoToBase64 = async (url) => {
    if (!url) return;
    try {
        const response = await fetch(url);
        const blob = await response.blob();
        return new Promise((resolve) => {
            const reader = new FileReader();
            reader.onloadend = () => {
                logoBase64.value = reader.result;
                resolve();
            };
            reader.readAsDataURL(blob);
        });
    } catch (e) {
        console.error("Failed to convert logo to base64", e);
    }
};

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
        toast.error("Gagal memuat receipt");
        // router.go(-1);
    } finally {
        loading.value = false;
    }
};

const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(val);

const formatDateFull = (dateString) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('en-US', {
        weekday: 'long', day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false
    }).format(date);
};

const formatOrderType = (type) => {
    if (type === 'dine_in') return 'Dine In';
    if (type === 'pickup_app' || type === 'pickup') return 'Pick up Order';
    return type;
};

const downloadPdf = async () => {
    isDownloading.value = true;
    try {
        const element = document.getElementById('receipt-content');
        const opt = {
            margin: [10, 10, 10, 10],
            filename: `receipt-${order.value.order_number}.pdf`,
            image: { type: 'jpeg', quality: 0.98 },
            html2canvas: { scale: 2, useCORS: true },
            jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
        };

        await html2pdf().set(opt).from(element).save().then(() => {
            toast.success("Receipt downloaded!", {
                position: "top-left",
                toastClassName: "customer-toast"
            });
        });
    } catch (e) {
        toast.error("Gagal download PDF", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
    } finally {
        isDownloading.value = false;
    }
};

const shareReceipt = () => {
    if (navigator.share) {
        navigator.share({
            title: `Receipt #${order.value.order_number}`,
            text: `Receipt from ${settings.value.store_name}`,
            url: window.location.href
        }).catch(console.error);
    } else {
        // Fallback for browsers that do not support Web Share API
        // You might want to offer a download option or copy link to clipboard
    }
};

onMounted(async () => {
    await customerStore.fetchSettings();
    settings.value = customerStore.settings;
    if (settings.value?.store_logo) {
        await convertLogoToBase64(settings.value.store_logo);
    }
    fetchOrder();
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
.pb-safe {
    padding-bottom: env(safe-area-inset-bottom, 5px);
}
@media print {
    header, button, footer, .bottom-actions {
        display: none !important;
    }
    body {
        background: white;
    }
    main {
        overflow: visible !important;
        height: auto !important;
    }
}

/* 
   Safe Color Overrides for html2pdf 
   Tailwind v4 uses oklch which crashes html2canvas.
*/
.text-slate-900 { color: #0f172a !important; }
.text-slate-800 { color: #1e293b !important; }
.text-slate-700 { color: #334155 !important; }
.text-slate-600 { color: #475569 !important; }
.text-slate-500 { color: #64748b !important; }
.border-gray-200 { border-color: #e5e7eb !important; }
.border-gray-100 { border-color: #f3f4f6 !important; }
</style>
