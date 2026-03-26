<template>
    <MobileLayout :show-header="false" :show-footer="false">
        <template #header-custom>
            <!-- Top App Bar -->
            <header class="flex-none bg-white px-4 py-3 flex items-center justify-between border-b border-gray-100 shadow-sm z-40 sticky top-0">
                <button @click="$router.push('/order')" class="size-10 flex items-center justify-center rounded-full hover:bg-gray-50 transition-colors text-slate-900">
                     <ChevronLeftIcon class="w-6 h-6" />
                </button>
                <h2 class="text-lg font-bold tracking-tight text-slate-900 absolute left-1/2 -translate-x-1/2">Checkout</h2>
                <div class="size-10"></div>
            </header>
        </template>

        <div v-if="pageLoading" class="flex flex-col px-4 pb-32 space-y-6 animate-pulse mt-4">
             <!-- Skeleton -->
            <div class="flex flex-col gap-3">
                <div class="h-4 w-24 bg-gray-200 rounded"></div>
                 <div class="h-24 bg-gray-200 rounded-xl"></div>
            </div>
             <div class="h-12 bg-gray-200 rounded-xl"></div>
             <div class="h-32 bg-gray-200 rounded-xl"></div>
        </div>

        <div v-else class="pb-28">
            
            <!-- Order Mode Banner -->
            <div class="bg-gray-50 px-5 py-4 flex items-center justify-between mb-2">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                        <ShoppingBagIcon v-if="orderType === 'pickup'" class="w-5 h-5 text-primary" />
                        <UtensilsIcon v-else class="w-5 h-5 text-primary" />
                    </div>
                    <div>
                        <h3 class="font-bold text-slate-900 text-[15px]">{{ orderType === 'pickup' ? 'Pick Up' : 'Dine In' }}</h3>
                        <p class="text-xs text-slate-500">{{ orderType === 'pickup' ? 'Ambil di store tanpa antri' : 'Makan ditempat lebih santai' }}</p>
                    </div>
                </div>
                <button @click="toggleOrderType" class="px-3 py-1 bg-white border border-primary rounded-full text-[12px] font-bold text-primary active:scale-95 transition-transform">
                    Ubah
                </button>
            </div>

            <div class="px-5 space-y-6">
                <!-- Location Section -->
                <div>
                    <h3 class="font-bold text-[15px] mb-3 text-slate-900">
                        {{ orderType === 'pickup' ? 'Ambil pesananmu di' : 'Ajak #TemanBincangmu kesini' }}
                    </h3>
                    <!-- Location Card -->
                    <div class="bg-primary rounded-xl p-5 flex items-center justify-between text-white relative overflow-hidden shadow-lg shadow-primary/20 mb-3">
                         <!-- Decorative circles -->
                         <div class="absolute -right-4 -top-4 w-20 h-20 bg-white/10 rounded-full"></div>
                         <div class="absolute right-10 -bottom-10 w-24 h-24 bg-white/5 rounded-full"></div>

                         <div class="z-10 flex-1 pr-4">
                             <h3 class="font-bold text-base leading-tight">{{ settings.store_name || 'Ruang Bincang' }}</h3>
                             <p class="text-xs text-white/90 mt-1 flex items-center gap-1 font-medium">
                                <MapPinIcon class="w-3 h-3" />
                                {{ settings.store_address ? settings.store_address.substring(0, 30) + '...' : 'Location' }}
                             </p>
                         </div>
                         <a 
                            v-if="settings.store_maps_link"
                            :href="settings.store_maps_link" 
                            target="_blank"
                            class="z-10 bg-white/20 backdrop-blur-sm text-white border border-white/30 text-[10px] font-bold px-3 py-2 rounded-xl flex items-center gap-1 hover:bg-white/30 transition-colors shadow-sm"
                         >
                            View Maps
                            <MapPinIcon class="w-3 h-3" />
                         </a>
                    </div>

                    <!-- Estimation -->
                    <div v-if="orderType === 'pickup'" class="bg-gray-50 rounded-lg px-4 py-3 flex items-center gap-3">
                        <ClockIcon class="w-4 h-4 text-primary" />
                        <span class="text-xs font-bold text-slate-800">Estimasi siap diambil dalam 15 menit</span>
                    </div>

                    <!-- Customer Info -->
                    <div v-if="!store.member" class="mt-4">
                        <h3 class="font-bold text-[15px] mb-3 text-slate-900">Isi dulu ya</h3>
                        <div class="bg-gray-50 border border-gray-100 rounded-xl p-3 space-y-3">
                            <input v-model="customerName" placeholder="Nama Pemesan" class="w-full bg-transparent border-b border-gray-200 py-2 text-sm font-bold outline-none placeholder:font-normal focus:border-primary" />
                            <div v-if="orderType === 'pickup'">
                                <input 
                                    v-model="customerPhone" 
                                    @blur="validatePhone" 
                                    placeholder="Nomor WhatsApp" 
                                    type="tel" 
                                    class="w-full bg-transparent border-b border-gray-200 py-2 text-sm font-bold outline-none placeholder:font-normal focus:border-primary transition-colors"
                                    :class="{'border-red-500 text-red-500': phoneValidation === 'invalid', 'border-primary text-primary': phoneValidation === 'valid'}"
                                />
                                 <p v-if="phoneValidation === 'valid'" class="text-[11px] text-primary font-bold mt-1 flex items-center gap-1">
                                    <CheckCircleIcon class="w-3 h-3" /> Valid - Nomor Whatsapp terdaftar
                                </p>
                                <p v-if="phoneValidation === 'invalid'" class="text-[11px] text-red-500 font-bold mt-1 flex items-center gap-1">
                                    <XCircleIcon class="w-3 h-3" /> Invalid - Nomor tidak terdaftar di Whatsapp
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="h-px bg-gray-100"></div>

                <!-- Detail Pesanan -->
                <div>
                    <h3 class="font-bold text-[15px] mb-4 text-slate-900">Detail Pesanan</h3>
                    <div class="space-y-6">
                        <div v-for="(item, index) in cart" :key="item.cartId" class="relative">
                            <div class="flex gap-4">
                                <div class="flex-1 min-w-0">
                                    <h4 class="font-bold text-slate-900 text-sm mb-1 leading-tight">{{ getProductName(item) }}</h4>
                                    <!-- Modifiers -->
                                    <p class="text-[11px] text-slate-500 leading-relaxed mb-3">
                                        {{ getVisibleModifiers(item).map(m => getModifierDisplayName(m)).join(', ') || 'Regular' }}
                                    </p>
                                    
                                    <div class="flex items-center justify-between mt-auto">
                                        <span class="font-bold text-slate-900 text-sm">Rp {{ formatNumber(item.unit_price * item.quantity) }}</span>
                                        <button class="text-[12px] font-bold text-primary px-2 py-1 -ml-2" @click="editItem(item)">
                                            Ubah
                                        </button>
                                    </div>
                                </div>
                                
                                <div class="flex flex-col items-end gap-3 shrink-0">
                                    <!-- Image -->
                                    <div class="w-[70px] h-[70px] rounded-xl bg-gray-100 overflow-hidden border border-gray-50">
                                        <img :src="item.image_url || '/no-image.jpg'" class="w-full h-full object-cover" />
                                    </div>
                                    <!-- Stepper -->
                                    <div class="flex items-center border border-gray-200 rounded-full h-8 px-1 shadow-sm">
                                        <button @click="updateQuantity(item.cartId, -1)" class="w-7 h-full flex items-center justify-center text-slate-500 hover:text-slate-900 active:scale-90 transition-transform">
                                            <MinusIcon class="w-3.5 h-3.5" />
                                        </button>
                                        <span class="text-[13px] font-bold text-slate-900 min-w-[20px] text-center">{{ item.quantity }}</span>
                                        <button @click="updateQuantity(item.cartId, 1)" class="w-7 h-full flex items-center justify-center text-slate-500 hover:text-slate-900 active:scale-90 transition-transform">
                                            <PlusIcon class="w-3.5 h-3.5" />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="h-px bg-gray-100"></div>

                <!-- Upsell -->
                <div v-if="upsellProducts.length > 0" class="bg-linear-to-br from-primary/10 to-[#F9F5EC] -mx-5 py-5 mb-4">
                     <h3 class="font-bold text-[15px] mb-3 text-slate-900 flex items-center gap-1 px-5">
                        Menu <span class="text-primary">#TemanBincangmu</span> hari ini!
                     </h3>
                     <div class="flex overflow-x-auto gap-3 px-5 pb-2 no-scrollbar">
                        <div v-for="product in upsellProducts" :key="product.id" class="min-w-[260px] p-3 rounded-xl border border-gray-100 shadow-sm flex items-center gap-3 bg-white">
                            <div class="w-16 h-16 rounded-lg bg-gray-100 overflow-hidden shrink-0 border border-gray-50">
                                <img :src="product.image_url || '/no-image.jpg'" class="w-full h-full object-cover" />
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="font-bold text-sm truncate text-slate-900">{{ product.name }}</p>
                                <div class="flex items-center justify-between mt-2">
                                    <span class="text-xs font-semibold text-slate-900">Rp {{ formatNumber(store.resolveProductPrice(product)) }}</span>
                                    <button 
                                        @click="quickAddUpsell(product)"
                                        class="w-6 h-6 rounded-full bg-primary text-white flex items-center justify-center shadow-md active:scale-90 transition-transform hover:bg-[#142118]"
                                    >
                                        <PlusIcon class="w-4 h-4" />
                                    </button>
                                </div>
                            </div>
                        </div>
                     </div>
                </div>

                <!-- Add More -->
                <div class="flex items-center justify-between py-1">
                    <div>
                        <h4 class="font-bold text-sm text-slate-900">Ada tambahan lagi?</h4>
                        <p class="text-xs text-slate-500">Kamu masih bisa tambahin menu lain, ya.</p>
                    </div>
                    <button @click="$router.push('/order')" class="px-4 py-1.5 rounded-full border border-slate-300 text-[12px] font-bold text-slate-700 hover:border-primary hover:text-primary transition-colors">
                        Tambah
                    </button>
                </div>

                <div class="h-2 bg-gray-50 -mx-5"></div>

                <div>
                    <h3 class="font-bold text-[15px] mb-3 text-slate-900">Voucher & Rewards</h3>
                    <div 
                        @click="$router.push('/vouchers')"
                        class="border border-[#CFD9C8] bg-[#EFF4EA] rounded-xl p-4 flex items-center justify-between cursor-pointer active:scale-[0.99] transition-transform relative overflow-hidden"
                    >
                        <div class="flex items-center gap-3 z-10">
                            <div class="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm text-primary">
                                <TicketIcon class="w-4 h-4" />
                            </div>
                            <div v-if="store.selectedVoucher">
                                <p class="font-bold text-sm text-slate-900">Voucher Terpakai!</p>
                                <p class="text-xs text-primary font-semibold truncate max-w-[150px]">
                                    {{ store.selectedVoucher.reward ? store.selectedVoucher.reward.name : store.selectedVoucher.name }}
                                </p>
                            </div>
                            <div v-else>
                                <p class="font-bold text-sm text-slate-900">
                                    {{ myVouchers.length > 0 ? `${myVouchers.length} Voucher Saya` : 'Punya Voucher?' }}
                                </p>
                                <p class="text-xs text-primary font-semibold">
                                    Cek voucher dan rewards kamu
                                </p>
                            </div>
                        </div>
                        <button class="px-4 py-1.5 bg-white rounded-full text-[11px] font-bold text-slate-800 shadow-sm border border-gray-100 z-10">
                            {{ store.selectedVoucher ? 'Ganti' : 'Pilih' }}
                        </button>
                        
                        <!-- Decorative BG -->
                        <div class="absolute right-0 top-0 bottom-0 w-24 bg-linear-to-l from-[#E1E8D9] to-transparent opacity-50"></div>
                    </div>
                    
                    <button v-if="store.selectedVoucher" @click="store.removeVoucher()" class="w-full text-center mt-2 text-xs text-red-500 font-bold">
                        Hapus Voucher
                    </button>
                </div>

                <div class="h-2 bg-gray-50 -mx-5"></div>
                
                <!-- Payment Method -->
                <div>
                    <h3 class="font-bold text-[15px] mb-3 text-slate-900">Metode Pembayaran</h3>
                    <div @click="openPaymentModal" class="flex items-center justify-between py-1 cursor-pointer">
                        <div class="flex items-center gap-3">
                            <div class="min-w-[32px] h-5 border border-gray-200 rounded px-1 flex items-center justify-center">
                                <span class="text-[10px] font-bold uppercase">
                                    {{ paymentMethod === 'bank_transfer' ? 'TF' : paymentMethod === 'cashier' ? 'CASH' : paymentMethod }}
                                </span>
                            </div>
                            <span class="font-bold text-sm text-slate-900 uppercase">
                                {{ paymentMethod === 'qris' ? 'QRIS' : paymentMethod === 'bank_transfer' ? 'Bank Transfer' : paymentMethod === 'cashier' ? 'Bayar di Kasir' : paymentMethod }}
                            </span>
                        </div>
                        <ChevronRightIcon class="w-5 h-5 text-slate-400" />
                    </div>
                </div>

                <div class="h-2 bg-gray-50 -mx-5"></div>

                <!-- Payment Summary -->
                <div class="pb-2">
                    <h3 class="font-bold text-[15px] mb-1 text-slate-900">Rincian Pembayaran</h3>
                    <div class="space-y-2 text-sm">
                        <div class="flex justify-between text-slate-600">
                            <span>Harga ({{ cart.length }} Item)</span>
                            <span>Rp {{ formatNumber(cartTotal) }}</span>
                        </div>
                        <div v-if="store.discountAmount > 0" class="flex justify-between text-primary">
                            <span>Diskon Voucher</span>
                            <span>- Rp {{ formatNumber(store.discountAmount) }}</span>
                        </div>
                        <div class="flex justify-between text-slate-600">
                            <span>Pajak ({{ store.taxRate }}%)</span>
                            <span>Rp {{ formatNumber(taxAmount) }}</span>
                        </div>
                        <div class="flex justify-between font-bold text-slate-900 pt-2 text-[15px]">
                            <span>Total Pembayaran</span>
                            <span>Rp {{ formatNumber(finalTotal) }}</span>
                        </div>
                    </div>
                </div>
                
                <div class="h-px bg-gray-200 mb-4"></div>

                <!-- Cancellation Policy -->
                 <div class="pb-4">
                    <h4 class="font-bold text-[13px] text-slate-900 mb-1">Kebijakan Pembatalan</h4>
                    <p class="text-[11px] text-slate-500 leading-relaxed">
                        Kamu tidak dapat melakukan pembatalan atau perubahan apapun pada pesanan setelah melakukan pembayaran. Pastikan pesananmu sudah sesuai ya!
                    </p>
                 </div>
            </div>
        </div>

        <div class="fixed bottom-0 w-full max-w-md bg-white border-t border-gray-100 z-30 pb-8 shadow-[0_-5px_20px_rgba(0,0,0,0.05)]">
            <!-- Points Banner -->
             <div class="bg-gray-50 py-2 px-5 flex items-center gap-2 justify-center">
                 <img src="/point.png" class="w-4 h-4 object-contain" />
                 <span class="text-xs font-medium text-slate-700">Kamu berpotensi mendapatkan <span class="font-bold text-primary">{{ Math.floor(finalTotal / 10000) }} Poin</span></span>
             </div>

             <div class="p-4">
                 <button 
                    @click="handlePayClick"
                    :disabled="isSubmitting || cart.length === 0"
                    class="w-full bg-primary hover:bg-[#142118] text-white font-bold text-[15px] py-3.5 rounded-full shadow-lg active:scale-[0.98] transition-all disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                    <span v-if="!isSubmitting">Pesan Sekarang</span>
                    <Loader2Icon v-else class="w-5 h-5 animate-spin" />
                 </button>
             </div>
        </div>

         <!-- Payment Method Selector Modal -->
        <div v-if="showPaymentModal" class="fixed inset-0 z-50 flex items-end justify-center bg-black/50 backdrop-blur-sm" @click="showPaymentModal = false">
            <div class="bg-white w-full max-w-md rounded-t-3xl p-5 space-y-4 animate-in slide-in-from-bottom-10" @click.stop>
                <div class="w-12 h-1 bg-gray-200 rounded-full mx-auto mb-2"></div>
                <h3 class="font-bold text-lg text-slate-900 mb-4">Pilih Metode Pembayaran</h3>
                
                <div class="space-y-3">
                    <button 
                        v-for="method in ['qris', 'bank_transfer', 'card', 'cashier']" 
                        :key="method"
                        @click="paymentMethod = method; showPaymentModal = false"
                        class="w-full flex items-center justify-between p-4 rounded-xl border transition-all"
                        :class="paymentMethod === method ? 'border-primary bg-gray-50' : 'border-gray-200 hover:border-gray-300'"
                    >
                        <span class="font-bold text-slate-900 uppercase">{{ method === 'cashier' ? 'Bayar di Kasir' : method === 'bank_transfer' ? 'Bank Transfer' : method }}</span>
                        <div class="w-5 h-5 rounded-full border border-gray-300 flex items-center justify-center" :class="{'border-primary bg-primary': paymentMethod === method}">
                             <CheckIcon v-if="paymentMethod === method" class="w-3 h-3 text-white" />
                        </div>
                    </button>
                </div>
            </div>
        </div>

        <!-- Delete Confirmation Modal -->
        <div v-if="showDeleteConfirm" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-6" @click="showDeleteConfirm = false">
            <div class="bg-white w-full max-w-[320px] rounded-2xl p-6 space-y-4 animate-in zoom-in-95" @click.stop>
                <div class="flex flex-col items-center text-center space-y-3">
                    <div class="w-16 h-16 rounded-full bg-red-50 flex items-center justify-center text-red-500">
                        <AlertTriangleIcon class="w-8 h-8" />
                    </div>
                    <div class="space-y-1">
                        <h3 class="text-lg font-bold text-slate-900">Hapus Item?</h3>
                        <p class="text-sm text-slate-500">Kamu yakin ingin menghapus <b>{{ itemToDelete?.name }}</b> dari pesanan?</p>
                    </div>
                </div>
                
                <div class="flex gap-3">
                    <button 
                        @click="showDeleteConfirm = false" 
                        class="flex-1 py-3 rounded-xl border border-gray-200 text-sm font-bold text-slate-600 active:scale-95 transition-transform"
                    >
                        Batal
                    </button>
                    <button 
                        @click="confirmDelete" 
                        class="flex-1 py-3 rounded-xl bg-red-500 text-white text-sm font-bold shadow-lg shadow-red-500/20 active:scale-95 transition-transform"
                    >
                        Ya, Hapus
                    </button>
                </div>
            </div>
        </div>

    </MobileLayout>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import MobileLayout from '../../layouts/MobileLayout.vue';
import { useRouter } from 'vue-router';
import { 
    ChevronLeftIcon, StoreIcon, ClockIcon, MinusIcon, PlusIcon,
    TicketIcon, ChevronRightIcon, CheckIcon, Loader2Icon, ShoppingBagIcon, UtensilsIcon, CheckCircleIcon, XCircleIcon, MapPinIcon, AlertTriangleIcon
} from 'lucide-vue-next';
import api from '../../api/axios';
import { useCustomerStore } from '../../stores/customer';
import { useProductDisplay } from '../../composables/useProductDisplay';

import { useMemberAuthStore } from '../../stores/memberAuth';

const router = useRouter();
const store = useCustomerStore();
const authStore = useMemberAuthStore();
const { getProductName, getVisibleModifiers, getModifierDisplayName } = useProductDisplay();

const cart = computed(() => store.cart);
const cartTotal = computed(() => store.cartTotal);
const taxAmount = computed(() => store.taxAmount);
const finalTotal = computed(() => store.finalTotal);
const settings = computed(() => store.settings || {});
const orderType = computed(() => store.orderType || 'pickup');
const member = computed(() => authStore.currentUser);
const myVouchers = computed(() => store.myVouchers);
const availableVouchers = computed(() => {
    return store.promos.filter(p => store.cartTotal >= Number(p.min_purchase || 0)).length;
});

const getPotentialDiscount = (promo) => {
    if (!promo) return 0;
    if (promo.type === 'fixed') return parseFloat(promo.value);
    return Math.round(store.cartTotal * (parseFloat(promo.value) / 100));
};

const suggestedVoucher = computed(() => {
    const usable = store.promos.filter(p => store.cartTotal >= Number(p.min_purchase || 0));
    if (usable.length === 0) return null;
    return usable.sort((a, b) => getPotentialDiscount(b) - getPotentialDiscount(a))[0];
});

const customerName = ref('');
const customerPhone = ref('');
const paymentMethod = ref('qris'); 
const isSubmitting = ref(false); 
const pageLoading = ref(true); 
const showPaymentModal = ref(false);
const phoneValidation = ref(null);
const showDeleteConfirm = ref(false);
const itemToDelete = ref(null);



const upsellProducts = ref([]);
const { toast } = useToast();

onMounted(async () => {
    setTimeout(() => { pageLoading.value = false; }, 300);
    if (!store.settings) store.fetchSettings();
    
    if (authStore.token && !authStore.currentUser) {
        await authStore.fetchMe();
    }
    
    if (store.promos.length === 0) store.fetchPromos();
    
    // Fetch Upsells
    upsellProducts.value = await store.fetchUpsellProducts();
});

watch(member, (newMember) => {
    if (newMember) {
        store.loginAsMember(newMember);
        customerName.value = newMember.name;
    }
}, { immediate: true });

const toggleOrderType = () => {
    store.setOrderType(orderType.value === 'pickup' ? 'dine_in' : 'pickup');
};

const updateQuantity = (cartId, delta) => {
    const item = store.cart.find(i => i.cartId === cartId);
    if (!item) return;

    if (item.quantity === 1 && delta === -1) {
        itemToDelete.value = item;
        showDeleteConfirm.value = true;
        return;
    }
    store.updateQuantity(cartId, delta);
};

const handlePayClick = async () => {
    if (!customerName.value) return alert("Mohon isi Nama Pemesan");
    if (!store.member && orderType.value === 'pickup') {
        if (!customerPhone.value) return alert("Mohon isi Nomor WhatsApp");
        if (!phoneValidation.value) await validatePhone();
        if (phoneValidation.value === 'invalid') return alert("Nomor WhatsApp tidak valid");
    }

    isSubmitting.value = true;
    try {
        const result = await store.submitOrder({
            orderType: orderType.value,
            method: paymentMethod.value,
            note: orderType.value === 'dine_in' ? 'Dine In' : 'Pickup',
            customerName: customerName.value,
            customerPhone: customerPhone.value
        });

        if (result) {
            router.push(`/payment/${result.id || result}`);
        }
    } catch(e) {
        alert("Terjadi kesalahan");
    } finally {
        isSubmitting.value = false;
    }
};

const validatePhone = async () => {
    if (!customerPhone.value) { phoneValidation.value = null; return; }
    try {
        const response = await api.post('/public/orders/validate-phone', { phone: customerPhone.value });
        const resData = response.data?.data || response.data || {};
        phoneValidation.value = resData.valid ? 'valid' : 'invalid';
    } catch { phoneValidation.value = 'invalid'; }
};

const formatNumber = (n) => new Intl.NumberFormat('id-ID').format(n);
const editItem = (item) => {
    router.push({
        path: `/product/${item.slug || item.id}`,
        query: { cartId: item.cartId }
    });
};
import { useToast } from "vue-toastification";

const quickAddUpsell = (product) => {
    store.addToCart(product, { quantity: 1 });
    // toast.success("Ditambahkan ke pesanan!"); // Optional feedback
};

const openPaymentModal = () => showPaymentModal.value = true;

const confirmDelete = () => {
    if (itemToDelete.value) {
        store.removeFromCart(itemToDelete.value.cartId);
    }
    showDeleteConfirm.value = false;
    itemToDelete.value = null;
};
</script>

<style scoped>
.pb-safe { padding-bottom: max(env(safe-area-inset-bottom), 5px); }
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
