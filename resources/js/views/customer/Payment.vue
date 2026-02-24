<template>
    <div class="min-h-screen bg-white font-sans text-gray-900 flex justify-center">
        <div class="w-full max-w-md bg-white min-h-screen relative flex flex-col">
            <!-- Header -->
            <div class="sticky top-0 z-10 flex items-center bg-white border-b border-gray-100 px-4 py-3">
                <button @click="$router.back()" class="text-gray-900 flex w-10 h-10 shrink-0 items-center justify-center rounded-full hover:bg-gray-100 transition-colors">
                     <ChevronLeftIcon class="w-6 h-6" />
                </button>
                <h2 class="text-gray-900 text-lg font-bold leading-tight tracking-tight flex-1 text-center pr-10">{{ pageTitle }}</h2>
            </div>
            
            <!-- Loading Skeleton -->
            <div v-if="loading" class="flex-1 flex flex-col items-center px-6 pt-8 pb-32 animate-pulse">
                <div class="w-full h-10 bg-gray-200 rounded mb-6"></div>
                <div class="w-64 h-64 bg-gray-200 rounded-3xl mb-8"></div>
                <div class="w-full flex justify-between items-end mb-8">
                     <div class="space-y-2">
                         <div class="h-4 w-32 bg-gray-200 rounded"></div>
                         <div class="h-8 w-40 bg-gray-200 rounded"></div>
                     </div>
                </div>
            </div>

            <template v-else-if="order">
                <!-- Timer -->
                <div class="bg-red-50 py-2 px-4 text-center">
                    <p class="text-xs font-medium text-red-600">
                        Selesaikan pembayaran dalam <span class="font-bold text-red-700">{{ formattedTime }}</span>
                    </p>
                </div>
    
                <!-- Content -->
                <div class="flex-1 flex flex-col items-center px-6 pt-8 pb-32">
                    
                    <!-- QR Wrapper (Only for QRIS) -->
                    <div v-if="order.payment_method === 'qris'" class="bg-white p-4 rounded-3xl shadow-lg border border-gray-100 mb-6">
                         <div class="w-64 h-64 bg-gray-900 rounded-xl overflow-hidden relative group">
                            <img src="https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=StandardQRISPaymentTest" class="w-full h-full object-cover" />
                            
                            <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
                                 <div class="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-md">
                                     <QrCodeIcon class="w-6 h-6 text-gray-900" />
                                 </div>
                            </div>
                         </div>
                    </div>

                    <!-- E-Wallet / Other Placeholder -->
                    <div v-else class="w-full bg-blue-50 p-6 rounded-3xl border border-blue-100 mb-6 flex flex-col items-center text-center">
                        <div class="w-16 h-16 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mb-4">
                            <WalletIcon class="w-8 h-8" />
                        </div>
                        <h3 class="font-bold text-gray-900 text-lg mb-2">Metode Pembayaran Lain</h3>
                        <p class="text-sm text-gray-600">Silakan ikuti instruksi pembayaran untuk metode {{ order.payment_method.toUpperCase() }} pada aplikasi terkait.</p>
                    </div>
    
                    <div class="w-full flex justify-between items-end mb-8 px-2">
                        <div class="flex flex-col">
                            <p class="text-sm text-gray-500 font-medium">Total Pembayaran:</p>
                            <p class="text-2xl font-bold text-[#0f4d38]">{{ formatCurrency(order.grand_total) }}</p>
                        </div>
                        
                        <button v-if="order.payment_method === 'qris'" class="flex items-center gap-2 px-4 py-2 rounded-full border border-gray-300 text-sm font-bold text-gray-700 hover:bg-gray-50 transition active:scale-95">
                            <DownloadIcon class="w-4 h-4" />
                            <span>Unduh QR</span>
                        </button>
                    </div>
    
                    <!-- Tata Cara (Accordion) -->
                    <div class="w-full border-t border-gray-100 pt-6">
                        <button @click="isInstructionsOpen = !isInstructionsOpen" class="w-full flex justify-between items-center mb-4 cursor-pointer">
                            <h3 class="text-sm font-bold text-gray-900">Tata Cara Pembayaran</h3>
                            <ChevronDownIcon :class="{ 'rotate-180': isInstructionsOpen }" class="w-5 h-5 text-gray-400 transition-transform" />
                        </button>
                        
                        <div v-show="isInstructionsOpen" class="space-y-3 text-sm text-gray-600 leading-relaxed pl-1 animate-in slide-in-from-top-2 duration-200">
                            <template v-if="order.payment_method === 'qris'">
                                <p>1. Tekan Unduh QR atau screenshot layar ini untuk menyimpan QR Code-nya sebagai gambar.</p>
                                <p>2. Buka aplikasi dompet elektronik atau mobile banking yang memiliki fitur pembayaran QRIS.</p>
                                <p>3. Pilih menu QRIS pada aplikasi tersebut dan masukkan gambar QR Code yang sebelumnya sudah tersimpan di device Anda.</p>
                                <p>4. Periksa kembali detail pembayaran Anda dan selesaikan pembayarannya.</p>
                            </template>
                            <template v-else>
                                <p>1. Salin nomor Virtual Account atau Kode Pembayaran yang tertera (jika ada).</p>
                                <p>2. Buka aplikasi pembayaran pilihan Anda.</p>
                                <p>3. Ikuti instruksi pada aplikasi untuk menyelesaikan transaksi.</p>
                            </template>
                            <p>5. Buka kembali Aplikasi POS/Web ini dan cek kembali status pembelian Anda.</p>
                            <p>6. Jika belum terkonfirmasi, Anda bisa menekan tombol Konfirmasi Pembayaran.</p>
                        </div>
                    </div>
    
                </div>
            </template>

             <!-- Sticky Footer -->
            <div class="fixed bottom-0 left-0 right-0 px-4 pt-4 pb-4 bg-white border-t border-gray-100 max-w-md mx-auto z-20">
                <button 
                    @click="confirmPayment"
                    class="w-full bg-primary hover:bg-[#0a3828] text-white font-bold text-lg py-4 rounded-full shadow-lg transition-transform active:scale-[0.98]"
                >
                    Konfirmasi Pembayaran
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ChevronLeftIcon, ChevronDownIcon, QrCodeIcon, DownloadIcon, AlertCircleIcon, WalletIcon } from 'lucide-vue-next';
import { formatCurrency } from '../../utils/format';
import api from '../../api/axios';
import { useToast } from 'vue-toastification';

const route = useRoute();
const router = useRouter();
const toast = useToast();

const orderId = route.params.id;
const order = ref(null);
const loading = ref(true);
const isInstructionsOpen = ref(true);

// Timer Logic
const timeRemaining = ref(15 * 60);
let timerInterval = null;

const formattedTime = computed(() => {
    const minutes = Math.floor(timeRemaining.value / 60);
    const seconds = timeRemaining.value % 60;
    return `${minutes} menit : ${seconds.toString().padStart(2, '0')} detik`;
});

const pageTitle = computed(() => {
    if (!order.value) return 'Pembayaran';
    const method = order.value.payment_method;
    if (method === 'qris') return 'QR Code';
    if (method === 'ewallet') return 'E-Wallet';
    if (method === 'card') return 'Kartu Kredit/Debit';
    return 'Pembayaran';
});

const fetchOrder = async () => {
    try {
        const response = await api.get(`/public/orders/${orderId}`);
        order.value = response.data?.data || response.data || null;
        
    } catch (e) {
        console.error("Failed to fetch order", e);
        toast.error("Gagal memuat data pesanan", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
    } finally {
        loading.value = false;
    }
};

onMounted(() => {
    fetchOrder();
    
    timerInterval = setInterval(() => {
        if (timeRemaining.value > 0) {
            timeRemaining.value--;
        } else {
            clearInterval(timerInterval);
        }
    }, 1000);
});

onUnmounted(() => {
    if (timerInterval) clearInterval(timerInterval);
});

const confirmPayment = () => {
    router.push(`/app/payment/success/${orderId}`);
};
</script>
```
