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
                <template v-if="timeRemaining > 0">
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
                            <img ref="qrImageRef" src="/images/qris.jpg" class="w-full h-full object-cover" crossorigin="anonymous" />
                            
                            <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
                                 <div class="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-md">
                                     <QrCodeIcon class="w-6 h-6 text-gray-900" />
                                 </div>
                            </div>
                         </div>
                    </div>

                    <!-- Bank Transfer Section -->
                    <div v-else-if="order.payment_method === 'bank_transfer'" class="w-full bg-blue-50 p-6 rounded-3xl border border-blue-100 mb-6">
                        <div class="flex items-center gap-3 mb-4">
                            <img src="/images/bca.png" class="h-8 object-contain" alt="BCA" />
                            <h3 class="font-bold text-gray-900 text-lg">Bank Transfer BCA</h3>
                        </div>
                        <div class="bg-white rounded-xl p-4 border border-blue-100 space-y-3">
                            <div>
                                <p class="text-xs text-gray-500 font-medium">Nomor Rekening</p>
                                <div class="flex items-center gap-2 mt-1">
                                    <p class="text-xl font-bold text-gray-900 tracking-wider">264 4447 111</p>
                                    <button @click="copyText('2644447111', 'Nomor rekening')" class="p-1.5 bg-gray-50 hover:bg-gray-100 rounded-full transition-colors text-gray-500 active:scale-95" title="Salin No. Rekening">
                                        <CopyIcon class="w-3.5 h-3.5" />
                                    </button>
                                </div>
                            </div>
                            <div class="h-px bg-gray-100"></div>
                            <div>
                                <p class="text-xs text-gray-500 font-medium">Atas Nama</p>
                                <p class="text-sm font-bold text-gray-900 mt-1">SULIYANI</p>
                            </div>
                        </div>
                    </div>

                    <!-- Other Payment Method Placeholder -->
                    <div v-else class="w-full bg-blue-50 p-6 rounded-3xl border border-blue-100 mb-6 flex flex-col items-center text-center">
                        <div class="w-16 h-16 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mb-4">
                            <WalletIcon class="w-8 h-8" />
                        </div>
                        <h3 class="font-bold text-gray-900 text-lg mb-2">Metode Pembayaran Lain</h3>
                        <p class="text-sm text-gray-600">Silakan ikuti instruksi pembayaran untuk metode {{ order.payment_method.toUpperCase() }} pada aplikasi terkait.</p>
                    </div>
    
                    <div class="w-full flex justify-between items-end mb-8 px-2">
                        <div class="flex flex-col">
                            <p class="text-sm text-gray-500 font-medium pb-1">Total Pembayaran:</p>
                            <div class="flex items-center gap-2">
                                <p class="text-2xl font-bold text-[#0f4d38]">{{ formatCurrency(order.grand_total) }}</p>
                                <button @click="copyAmount(order.grand_total)" class="p-2 bg-gray-50 hover:bg-gray-100 rounded-full transition-colors text-gray-500 active:scale-95" title="Salin Nominal">
                                    <CopyIcon v-if="!copied" class="w-4 h-4" />
                                    <CheckIcon v-else class="w-4 h-4 text-green-600" />
                                </button>
                            </div>
                        </div>
                        
                        <button v-if="order.payment_method === 'qris'" @click="downloadQR" class="flex items-center gap-2 px-4 py-2 rounded-full border border-gray-300 text-sm font-bold text-gray-700 hover:bg-gray-50 transition active:scale-95">
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
                            <template v-else-if="order.payment_method === 'bank_transfer'">
                                <p>1. Salin nomor rekening BCA <b>264 4447 111</b> a.n. <b>SULIYANI</b>.</p>
                                <p>2. Buka aplikasi Mobile Banking atau ATM BCA terdekat.</p>
                                <p>3. Transfer sesuai nominal <b>{{ formatCurrency(order.grand_total) }}</b>.</p>
                                <p>4. Setelah transfer, tekan tombol <b>Konfirmasi Pembayaran</b> di bawah.</p>
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
                
                <template v-else>
                    <!-- Expired State -->
                    <div class="bg-red-100 py-3 px-4 text-center">
                        <p class="text-sm font-bold text-red-700">Waktu Pembayaran Habis!</p>
                    </div>
                    
                    <div class="flex-1 flex flex-col items-center justify-center px-6 text-center mt-12 pb-32 pt-20">
                        <div class="w-24 h-24 bg-red-50 text-red-500 rounded-full flex items-center justify-center mb-6">
                            <AlertCircleIcon class="w-12 h-12" />
                        </div>
                        <h3 class="font-bold text-gray-900 text-2xl mb-3">Pesanan Kedaluwarsa</h3>
                        <p class="text-gray-500 text-[15px] mb-8 leading-relaxed">Waktu pembayaran untuk pesanan ini telah habis. Silakan kembali ke halaman utama untuk membuat pesanan baru.</p>
                        <button @click="$router.push('/')" class="w-full py-4 bg-gray-100 hover:bg-gray-200 text-gray-900 font-bold rounded-xl transition-colors">
                            Kembali ke Menu Utama
                        </button>
                    </div>
                </template>
            </template>

             <!-- Sticky Footer -->
            <div v-if="timeRemaining > 0 && order" class="fixed bottom-0 left-0 right-0 px-4 pt-4 pb-8 bg-white border-t border-gray-100 max-w-md mx-auto z-20">
                <button 
                    @click="openConfirmationModal"
                    class="w-full bg-primary hover:bg-[#0a3828] text-white font-bold text-lg py-4 rounded-full shadow-lg transition-transform active:scale-[0.98] flex items-center justify-center gap-2"
                >
                    <span>Konfirmasi Pembayaran</span>
                </button>
            </div>

            <!-- Confirmation Modal Overlay -->
            <div v-if="showConfirmationModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
                <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="showConfirmationModal = false"></div>
                <div class="relative bg-white rounded-2xl w-full max-w-sm p-6 shadow-xl animate-in zoom-in-95 duration-200 overflow-y-auto max-h-[90vh]">
                    <div class="flex items-center justify-between mb-5">
                        <h3 class="font-bold text-gray-900 text-lg">Konfirmasi Pembayaran</h3>
                        <button @click="showConfirmationModal = false" class="text-gray-400 hover:text-gray-600 bg-gray-100 rounded-full p-1">
                            <XIcon class="w-5 h-5" />
                        </button>
                    </div>
                    
                    <div class="space-y-4">
                        <!-- Image Upload -->
                        <div>
                            <label class="block text-xs font-bold text-gray-700 mb-2">Bukti Transfer <span class="text-red-500">*</span></label>
                            <label class="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed rounded-xl cursor-pointer"
                                   :class="previewImage ? 'border-primary bg-primary/5' : 'border-gray-300 hover:bg-gray-50'">
                                <div v-if="!previewImage" class="flex flex-col items-center justify-center pt-5 pb-6">
                                    <UploadIcon class="w-8 h-8 text-gray-400 mb-2" />
                                    <p class="text-xs text-gray-500"><span class="font-semibold text-primary">Klik untuk unggah</span> gambar</p>
                                </div>
                                <div v-else class="w-full h-full p-1 relative">
                                    <img :src="previewImage" class="w-full h-full object-contain rounded-lg" />
                                </div>
                                <input type="file" accept="image/*" @change="handleFileUpload" class="hidden" />
                            </label>
                        </div>
                        
                        <!-- Details Form -->
                        <div>
                            <label class="block text-xs font-bold text-gray-700 mb-1">Nominal Transfer (Rp) <span class="text-red-500">*</span></label>
                            <input type="number" v-model="form.amount_paid" class="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-all" placeholder="Contoh: 50000" />
                        </div>
                        
                        <div>
                            <label class="block text-xs font-bold text-gray-700 mb-1">Nama Pengirim <span class="text-red-500">*</span></label>
                            <input type="text" v-model="form.customer_name" class="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-all" placeholder="Nama pemilik rekening asal" />
                        </div>
                        
                        <div>
                            <label class="block text-xs font-bold text-gray-700 mb-1">No. WhatsApp <span class="text-red-500">*</span></label>
                            <input type="tel" v-model="form.whatsapp_number" class="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-all" placeholder="08..." />
                        </div>
                        
                        <button 
                            @click="submitConfirmation" 
                            :disabled="isConfirming || !isFormValid" 
                            class="w-full bg-primary hover:bg-[#0a3828] text-white font-bold py-3.5 rounded-xl mt-6 transition-all disabled:opacity-50 flex items-center justify-center gap-2"
                        >
                            <Loader2Icon v-if="isConfirming" class="w-5 h-5 animate-spin" />
                            <span>Kirim Bukti</span>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ChevronLeftIcon, ChevronDownIcon, QrCodeIcon, DownloadIcon, AlertCircleIcon, WalletIcon, CopyIcon, CheckIcon, Loader2Icon, XIcon, UploadIcon } from 'lucide-vue-next';
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
const copied = ref(false);
const isConfirming = ref(false);
const showConfirmationModal = ref(false);
const qrImageRef = ref(null);
const previewImage = ref(null);

const form = ref({
    proof_image: null,
    amount_paid: '',
    customer_name: '',
    whatsapp_number: ''
});

const isFormValid = computed(() => {
    return form.value.proof_image !== null && 
           form.value.amount_paid !== '' && 
           form.value.customer_name !== '' && 
           form.value.whatsapp_number !== '';
});

const handleFileUpload = (event) => {
    const file = event.target.files[0];
    if (!file) return;
    
    // Validate size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
        toast.error("Ukuran file maksimal 5MB");
        return;
    }
    
    form.value.proof_image = file;
    
    // Create preview URL
    const reader = new FileReader();
    reader.onload = (e) => {
        previewImage.value = e.target.result;
    };
    reader.readAsDataURL(file);
};

const openConfirmationModal = () => {
    // Pre-fill fields if possible
    if (order.value) {
        form.value.amount_paid = order.value.grand_total || '';
        form.value.customer_name = order.value.customer_name || '';
        form.value.whatsapp_number = order.value.customer_phone || '';
    }
    showConfirmationModal.value = true;
};

const copyAmount = async (amount) => {
    try {
        await navigator.clipboard.writeText(amount.toString());
        copied.value = true;
        toast.success("Nominal disalin ke clipboard!", {
            position: "top-left",
            timeout: 2000,
            toastClassName: "customer-toast"
        });
        setTimeout(() => {
            copied.value = false;
        }, 2000);
    } catch (err) {
        toast.error("Gagal menyalin nominal", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
    }
};

const copyText = async (text, label) => {
    try {
        await navigator.clipboard.writeText(text);
        toast.success(`${label} disalin!`, {
            position: "top-left",
            timeout: 2000,
            toastClassName: "customer-toast"
        });
    } catch (err) {
        toast.error("Gagal menyalin", {
            position: "top-left",
            toastClassName: "customer-toast"
        });
    }
};

const downloadQR = () => {
    const link = document.createElement('a');
    link.href = '/images/qris.jpg';
    link.download = 'QRIS-RuangBincang.jpg';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success("QR Code berhasil diunduh!", {
        position: "top-left",
        timeout: 2000,
        toastClassName: "customer-toast"
    });
};

// Timer Logic
const timeRemaining = ref(15 * 60);
let timerInterval = null;

const formattedTime = computed(() => {
    const minutes = Math.floor(timeRemaining.value / 60);
    const seconds = timeRemaining.value % 60;
    return `${minutes} menit : ${seconds.toString().padStart(2, '0')} detik`;
});

const calculateTimeRemaining = () => {
    if (!order.value || !order.value.created_at) return 15 * 60;
    
    // Parse order.created_at assuming ISO format or local string
    const createdAt = new Date(order.value.created_at).getTime();
    const now = new Date().getTime();
    
    const expiryTime = createdAt + (15 * 60 * 1000);
    const diff = Math.floor((expiryTime - now) / 1000);
    
    return diff > 0 ? diff : 0;
};

const pageTitle = computed(() => {
    if (!order.value) return 'Pembayaran';
    const method = order.value.payment_method;
    if (method === 'qris') return 'QR Code';
    if (method === 'bank_transfer') return 'Bank Transfer';
    if (method === 'card') return 'Kartu Kredit/Debit';
    return 'Pembayaran';
});

const fetchOrder = async () => {
    try {
        const response = await api.get(`/public/orders/${orderId}`);
        order.value = response.data?.data || response.data || null;
        
        // Sync timer based on server created_at
        timeRemaining.value = calculateTimeRemaining();
        
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

const submitConfirmation = async () => {
    if (!isFormValid.value) return;
    
    isConfirming.value = true;
    try {
        const formData = new FormData();
        formData.append('proof_image', form.value.proof_image);
        formData.append('amount_paid', form.value.amount_paid);
        formData.append('customer_name', form.value.customer_name);
        formData.append('whatsapp_number', form.value.whatsapp_number);
        
        await api.post(`/public/orders/${orderId}/confirm-payment`, formData, {
            headers: {
                'Content-Type': 'multipart/form-data'
            }
        });
        
        toast.success("Konfirmasi pembayaran berhasil dikirim!", {
            position: "top-left",
            timeout: 3000,
            toastClassName: "customer-toast"
        });
        showConfirmationModal.value = false;
        router.push(`/payment/success/${orderId}`);
    } catch (e) {
        let msg = "Gagal mengkonfirmasi pembayaran.";
        if (e.response?.data?.errors) {
            // Get first error message from validation errors
            const errors = e.response.data.errors;
            msg = Object.values(errors)[0][0];
        } else if (e.response?.data?.message) {
            msg = e.response.data.message;
        }
        
        toast.error(msg, {
            position: "top-left",
            toastClassName: "customer-toast"
        });
    } finally {
        isConfirming.value = false;
    }
};
</script>
