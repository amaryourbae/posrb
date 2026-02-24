<template>
    <PosLayout>
        <div class="flex flex-col lg:flex-row h-full overflow-hidden relative">
            <!-- Main Content (Transaction List) -->
            <div 
                class="flex-1 flex flex-col h-full relative overflow-hidden transition-all duration-300 ease-in-out"
                :class="{ 'lg:mr-[400px]': selectedOrder }"
            >
                <!-- Page Header (Search & Filter) -->
                <div class="px-6 py-4 shrink-0 space-y-4 bg-white border-b border-gray-100 relative z-30">
                    <div class="flex items-center justify-between">
                        <h2 class="text-2xl font-bold text-gray-900">Transaction History</h2>
                        
                        <!-- Date Range (Moved Here) -->
                        <div class="relative">
                            <button 
                                @click="showDateFilter = !showDateFilter"
                                class="p-2 rounded-xl border transition flex items-center gap-2 text-sm font-medium hover:bg-gray-50 bg-white"
                                :class="{ 'border-primary text-primary bg-primary/5': startDate || endDate, 'border-gray-200 text-gray-600': !startDate && !endDate }"
                            >
                                <CalendarIcon class="w-5 h-5" /> 
                                <span v-if="startDate && endDate" class="hidden sm:inline">{{ formatDateShort(startDate) }} - {{ formatDateShort(endDate) }}</span>
                            </button>

                             <!-- Backdrop -->
                            <div 
                                v-if="showDateFilter" 
                                class="fixed inset-0 z-20 cursor-default" 
                                @click="showDateFilter = false"
                            ></div>

                            <!-- Date Filter Popover -->
                            <div 
                                v-if="showDateFilter" 
                                class="absolute top-full right-0 mt-2 p-4 bg-white rounded-2xl shadow-xl border border-gray-100 z-30 w-72 animate-in fade-in zoom-in-95 duration-200"
                            >
                                <div class="space-y-3">
                                    <div>
                                        <label class="text-xs font-bold text-gray-500 uppercase">From</label>
                                        <input 
                                            v-model="startDate" 
                                            type="date" 
                                            class="w-full mt-1 px-3 py-2 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-primary outline-none"
                                            @click.stop
                                        >
                                    </div>
                                    <div>
                                        <label class="text-xs font-bold text-gray-500 uppercase">To</label>
                                        <input 
                                            v-model="endDate" 
                                            type="date" 
                                            class="w-full mt-1 px-3 py-2 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-primary outline-none"
                                            @click.stop
                                        >
                                    </div>
                                    <div class="flex gap-2 pt-2">
                                        <button @click="clearDateFilter" class="flex-1 py-2 text-xs font-bold text-gray-500 hover:bg-gray-100 rounded-lg">Clear</button>
                                        <button @click="applyDateFilter" class="flex-1 py-2 text-xs font-bold text-white bg-primary hover:bg-[#004d34] rounded-lg shadow-lg shadow-primary/20">Apply</button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="relative">
                        <SearchIcon class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                        <input 
                            v-model="searchQuery" 
                            type="text"
                            class="w-full pl-12 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none shadow-sm text-sm transition-colors" 
                            placeholder="Search by Order ID, Customer..." 
                        />
                    </div>
                </div>

                <!-- Filters -->
                <div class="px-6 py-2 shrink-0 overflow-x-auto no-scrollbar bg-white/50 border-b border-gray-50">
                    <div class="flex space-x-3 py-2">
                        <button 
                            v-for="filter in filters" 
                            :key="filter.value"
                            @click="activeFilter = filter.value"
                            class="px-5 py-2 rounded-full text-sm font-medium whitespace-nowrap transition border"
                            :class="activeFilter === filter.value 
                                ? 'bg-primary text-white shadow-md shadow-primary/20 border-transparent' 
                                : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'"
                        >
                            {{ filter.label }}
                        </button>
                        
                    </div>
                </div>

                <!-- Transaction List -->
                <div class="flex-1 overflow-y-auto px-6 py-4 pb-24 lg:pb-6 space-y-3 bg-gray-50">
                    <div v-if="loading" class="space-y-3">
                         <div v-for="i in 8" :key="i" class="bg-white p-4 rounded-2xl shadow-sm border border-transparent flex items-center justify-between animate-pulse">
                            <div class="flex items-center gap-4">
                                <div class="w-12 h-12 rounded-2xl bg-gray-200 shrink-0"></div>
                                <div class="space-y-2">
                                    <div class="h-4 w-24 bg-gray-200 rounded"></div>
                                    <div class="h-3 w-48 bg-gray-200 rounded"></div>
                                </div>
                            </div>
                            <div class="space-y-2 flex flex-col items-end">
                                <div class="h-5 w-20 bg-gray-200 rounded"></div>
                                <div class="h-4 w-16 bg-gray-200 rounded"></div>
                            </div>
                        </div>
                    </div>
                    <!-- Today Section -->
                    <div v-else-if="orders.length > 0">
                        <div class="text-xs font-bold text-gray-400 uppercase tracking-wider py-2">Transactions</div>
                        
                        <div 
                            v-for="order in orders" 
                            :key="order.id"
                            @click="selectOrder(order)"
                            class="bg-white p-4 rounded-2xl shadow-sm border cursor-pointer flex items-center justify-between group transition mb-3"
                            :class="selectedOrder?.id === order.id ? 'border-primary ring-1 ring-primary/10' : 'border-transparent hover:border-gray-200'"
                        >
                            <div class="flex items-center gap-4">
                                <div 
                                    class="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0"
                                    :class="getStatusColor(order.payment_status).bg"
                                >
                                    <component :is="getStatusIcon(order.payment_status)" class="w-6 h-6" :class="getStatusColor(order.payment_status).text" />
                                </div>
                                <div>
                                    <div class="flex items-center gap-2 mb-0.5">
                                        <h3 class="font-bold text-gray-900 text-sm">{{ order.order_number }}</h3>
                                    </div>
                                    <p class="text-xs text-gray-500">{{ formatDate(order.created_at) }} • {{ order.order_type || 'Dine In' }} • {{ order.customer_name || order.customer?.name || 'Walk-in Customer' }}</p>
                                </div>
                            </div>
                            <div class="text-right">
                                <p class="font-bold text-base" :class="order.payment_status === 'cancelled' ? 'text-gray-500 line-through' : 'text-primary'">
                                    {{ formatCurrency(order.grand_total) }}
                                </p>
                                <span 
                                    class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold mt-1"
                                    :class="getStatusBadge(order.payment_status)"
                                >
                                    <span v-if="order.payment_status === 'paid'" class="w-1.5 h-1.5 rounded-full bg-green-500"></span> 
                                    {{ capitalize(order.payment_status) }}
                                </span>
                            </div>
                        </div>
                    </div>
                     <div v-else class="flex flex-col items-center justify-center h-64 text-gray-400">
                        <p>No transactions found</p>
                    </div>
                </div>
            </div>

            <!-- Detail Sidebar (Right) -->
             <aside 
                v-if="selectedOrder"
                class="absolute inset-y-0 right-0 w-full lg:w-[400px] bg-white shadow-2xl z-20 flex flex-col border-l border-gray-100 shrink-0 transform transition-transform duration-300"
            >
                <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-white">
                    <div>
                        <h2 class="text-lg font-bold text-gray-900">Order Details</h2>
                        <p class="text-xs text-gray-500">{{ selectedOrder.order_number }}</p>
                    </div>
                    <div class="flex items-center gap-3">
                        <div 
                            class="px-2.5 py-1 rounded-lg text-xs font-bold hidden lg:block"
                            :class="getStatusBadge(selectedOrder.payment_status)"
                        >
                            {{ capitalize(selectedOrder.payment_status) }}
                        </div>
                        <button @click="selectedOrder = null" class="p-1 rounded-full hover:bg-gray-100 text-gray-500">
                            <XIcon class="w-5 h-5" />
                        </button>
                    </div>
                </div>

                <div class="px-6 py-4 flex-1 overflow-y-auto">
                    <!-- Customer Card -->
                    <div class="bg-gray-50 rounded-xl p-4 flex items-center gap-3 mb-4">
                        <div class="w-10 h-10 rounded-full bg-gray-200 overflow-hidden shrink-0">
                            <img :src="`https://ui-avatars.com/api/?name=${selectedOrder.customer_name || selectedOrder.customer?.name || 'Guest'}&background=random`" class="w-full h-full object-cover" />
                        </div>
                        <div class="flex-1 min-w-0">
                            <h4 class="text-sm font-bold text-gray-900">{{ selectedOrder.customer_name || selectedOrder.customer?.name || 'Walk-in Customer' }}</h4>
                            <p class="text-xs text-gray-500 truncate">{{ (selectedOrder.customer && selectedOrder.customer.phone) || (selectedOrder.customer_phone) || 'No phone number provided' }}</p>
                        </div>
                        <div v-if="(selectedOrder.customer && selectedOrder.customer.phone) || selectedOrder.customer_phone" class="text-right">
                            <PhoneIcon class="w-5 h-5 text-gray-400 hover:text-primary cursor-pointer transition" />
                        </div>
                    </div>

                    <!-- Meta Grid -->
                    <div class="grid grid-cols-2 gap-3 mb-6">
                        <div class="bg-gray-50 rounded-xl p-3">
                            <p class="text-[10px] text-gray-500 uppercase font-bold tracking-wider mb-1">Order Type</p>
                            <div class="flex items-center gap-1.5">
                                <ArmchairIcon class="w-3.5 h-3.5 text-primary" />
                                <span class="text-sm font-semibold text-gray-800 uppercase">{{ selectedOrder.order_type ? selectedOrder.order_type.replace('_', ' ') : 'Dine In' }}</span>
                            </div>
                        </div>
                        <div class="bg-gray-50 rounded-xl p-3">
                            <p class="text-[10px] text-gray-500 uppercase font-bold tracking-wider mb-1">Payment</p>
                            <div class="flex items-center gap-1.5">
                                <CreditCardIcon class="w-3.5 h-3.5 text-primary" />
                                <span class="text-sm font-semibold text-gray-800 uppercase">{{ selectedOrder.payment_method ? selectedOrder.payment_method.replace('_', ' ') : 'Cash' }}</span>
                            </div>
                        </div>
                    </div>

                    <!-- Items -->
                    <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">Items Ordered ({{ selectedOrder.items ? selectedOrder.items.length : 0 }})</h3>
                    <div class="space-y-4">
                        <div v-for="item in selectedOrder.items" :key="item.id" class="flex justify-between items-start">
                            <div class="flex gap-3">
                                <div class="w-12 h-12 rounded-lg overflow-hidden bg-gray-100 shrink-0">
                                    <img 
                                        :src="(item.product && item.product.image_url) ? item.product.image_url : '/no-image.jpg'" 
                                        class="w-full h-full object-cover" 
                                        alt="Product"
                                        @error="$event.target.src = '/no-image.jpg'"
                                    />
                                </div>
                                <div>
                                    <h4 class="text-sm font-bold text-gray-800">{{ getProductName(item) }}</h4>
                                    <div class="text-xs text-gray-500 mt-1 space-y-0.5">
                                        <p>{{ item.quantity }}x {{ formatCurrency(item.unit_price) }}</p>
                                        <div v-if="getVisibleModifiers(item) && getVisibleModifiers(item).length">
                                            <p v-for="(mod, mIdx) in getVisibleModifiers(item)" :key="mIdx">
                                                + {{ getModifierDisplayName(mod) }}
                                            </p>
                                        </div> 
                                    </div>
                                </div>
                            </div>
                            <div class="text-right">
                                <span class="text-sm font-semibold text-gray-900">{{ formatCurrency(item.total_price || (item.unit_price * item.quantity)) }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Footer Summary inside sidebar -->
                <div class="px-6 py-6 bg-white border-t border-gray-100 mt-auto shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]">
                    <div class="space-y-2 mb-6">
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-500">Sub Total</span>
                            <span class="font-medium text-gray-900">{{ formatCurrency(selectedOrder.subtotal) }}</span>
                        </div>
                        <div v-if="selectedOrder.discount_amount > 0" class="flex justify-between text-sm text-green-600">
                             <span class="font-medium">Discount</span>
                             <span class="font-bold">-{{ formatCurrency(selectedOrder.discount_amount) }}</span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-500">Tax</span>
                            <span class="font-medium text-gray-900">{{ formatCurrency(selectedOrder.tax_amount) }}</span>
                        </div>
                         <div class="pt-3 border-t border-dashed border-gray-200 flex justify-between items-end mt-2">
                            <span class="text-base font-bold text-gray-900">Total Paid</span>
                            <span class="text-2xl font-bold text-primary">{{ formatCurrency(selectedOrder.grand_total) }}</span>
                        </div>
                    </div>
                    
                    <!-- For Pending Orders (Open Bills) -->
                    <div v-if="selectedOrder.payment_status === 'pending'" class="space-y-3">
                        <button 
                            @click="resumePayment(selectedOrder)"
                            class="w-full bg-primary hover:bg-[#004d34] text-white font-bold py-3.5 rounded-xl shadow-lg shadow-primary/20 transition transform active:scale-[0.98] flex items-center justify-center gap-2"
                        >
                            <CreditCardIcon class="w-5 h-5" />
                            <span>Resume Payment</span>
                        </button>
                        <button 
                            @click="requestCancel(selectedOrder)"
                            class="w-full bg-red-50 hover:bg-red-100 text-red-600 font-bold py-2.5 rounded-xl transition flex items-center justify-center gap-2 text-sm"
                        >
                            <XCircleIcon class="w-4 h-4" />
                            <span>Cancel Order</span>
                        </button>
                    </div>
                    
                    <!-- For Paid/Completed Orders -->
                    <div v-else class="space-y-3">
                        <div class="grid grid-cols-2 gap-3">
                            <button 
                                @click="handlePrint"
                                class="w-full bg-white border border-gray-200 hover:bg-gray-50 text-gray-700 font-bold py-3 rounded-xl transition flex items-center justify-center gap-2"
                            >
                                <PrinterIcon class="w-4 h-4" />
                                <span>Print</span>
                            </button>
                            <button 
                                @click="toggleWaInput"
                                class="w-full bg-primary hover:bg-[#004d34] text-white font-bold py-3 rounded-xl shadow-lg shadow-primary/20 transition transform active:scale-[0.98] flex items-center justify-center gap-2"
                            >
                                <SendIcon class="w-4 h-4" />
                                <span>Receipt</span>
                            </button>
                        </div>
                        
                         <!-- WhatsApp Input Slide Down -->
                        <div v-if="showWaInput" class="pt-2 animate-in slide-in-from-top-2 fade-in duration-300">
                             <label class="block text-[10px] font-bold text-gray-400 mb-1.5 ml-1 uppercase tracking-wider">WhatsApp Number</label>
                            <div class="flex gap-2">
                                <div class="relative flex-1">
                                    <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-bold">+62</span>
                                    <input 
                                        v-model="waNumber" 
                                        type="tel" 
                                        placeholder="812345678" 
                                        class="w-full pl-12 pr-4 py-3 bg-gray-50 border border-gray-100 rounded-xl text-sm font-bold text-gray-900 focus:ring-0 focus:border-primary outline-none transition-colors"
                                        @keyup.enter="sendToWa"
                                    />
                                </div>
                                <button 
                                    @click="sendToWa"
                                    class="bg-primary hover:bg-[#004d34] text-white px-3.5 rounded-xl shadow-lg shadow-primary/25 transition transform active:scale-95 flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed"
                                    :disabled="!waNumber || sending"
                                >
                                    <LoaderIcon v-if="sending" class="w-5 h-5 animate-spin" />
                                    <SendIcon v-else class="w-5 h-5" />
                                </button>
                            </div>
                        </div>
                        <button 
                            v-if="selectedOrder.payment_status === 'paid'" 
                            @click="requestRefund(selectedOrder)"
                            class="w-full text-red-500 hover:text-red-700 text-xs font-semibold py-2 transition"
                        >
                            Request Refund
                        </button>
                    </div>

                </div>
            </aside>
        </div>
    </PosLayout>
    <ManagerPinModal 
        :is-open="isPinModalOpen"
        :message="pinModalMessage"
        :loading="pinLoading"
        @close="isPinModalOpen = false"
        @submit="handlePinSubmit"
    />
    <Receipt :order="selectedOrder" />
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import PosLayout from '../../components/layout/PosLayout.vue';
import ManagerPinModal from '../../components/pos/ManagerPinModal.vue';
import Receipt from '../../components/pos/Receipt.vue';
import { 
    XIcon, LoaderIcon, ReceiptIcon, XCircleIcon, PrinterIcon, Share2Icon, SendIcon, MessageCircleIcon,
    SearchIcon, CalendarIcon, CoffeeIcon, ClockIcon, ShoppingBagIcon, PhoneIcon, ArmchairIcon, CreditCardIcon 
} from 'lucide-vue-next';
import { useProductDisplay } from '../../composables/useProductDisplay';
const { getProductName, getVisibleModifiers, getModifierDisplayName } = useProductDisplay();
import api from '../../api/axios';
import { formatCurrency } from '../../utils/format';
import { usePosStore } from '../../stores/pos';
import { useToast } from 'vue-toastification';

const router = useRouter();
const posStore = usePosStore();
const toast = useToast();

const searchQuery = ref('');
const activeFilter = ref('all');
const orders = ref([]);
const selectedOrder = ref(null);
const loading = ref(false);

// Pin Modal State
const isPinModalOpen = ref(false);
const pinModalMessage = ref('');
const pinLoading = ref(false);
const pendingAction = ref(null); 
const settings = computed(() => posStore.settings || {}); 

const filters = [
    { label: 'All', value: 'all' },
    { label: 'Paid', value: 'paid' },
    { label: 'Open Bills', value: 'pending' },
    { label: 'Cancelled', value: 'cancelled' }
];

const fetchOrders = async () => {
    loading.value = true;
    try {
        let url = '/admin/orders?per_page=50';
        if (activeFilter.value !== 'all') {
            url += `&payment_status=${activeFilter.value}`;
        }
        if (startDate.value && endDate.value) {
            url += `&start_date=${startDate.value}&end_date=${endDate.value}`;
        }
        const response = await api.get(url);
        const rawData = response.data?.data || response.data || {};
        // Handle nested orders structure
        const ordersData = rawData.orders?.data || rawData.data || rawData.orders || [];
        orders.value = Array.isArray(ordersData) ? ordersData.filter(o => o != null) : [];
    } catch (e) {
        console.error("Failed to load orders", e);
    } finally {
        loading.value = false;
    }
};

// Date Filter State
const showDateFilter = ref(false);
const startDate = ref('');
const endDate = ref('');

const formatDateShort = (dateStr) => {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return `${d.getDate()}/${d.getMonth()+1}`;
};

const applyDateFilter = () => {
    showDateFilter.value = false;
    fetchOrders();
};

const clearDateFilter = () => {
    startDate.value = '';
    endDate.value = '';
    showDateFilter.value = false;
    fetchOrders();
};

const selectOrder = (order) => {
    selectedOrder.value = order;
};

// Helpers
const formatDate = (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
};

const capitalize = (s) => s ? s.charAt(0).toUpperCase() + s.slice(1) : '';

const getStatusIcon = (status) => {
    switch(status) {
        case 'completed': return CoffeeIcon; 
        case 'pending': return ClockIcon;
        case 'cancelled': return XCircleIcon;
        default: return ShoppingBagIcon;
    }
};

const getStatusColor = (status) => {
    switch(status) {
        case 'completed': 
        case 'paid':
            return { bg: 'bg-green-100', text: 'text-green-600' };
        case 'pending': 
        case 'unpaid':
            return { bg: 'bg-orange-100', text: 'text-orange-600' };
        case 'cancelled': 
            return { bg: 'bg-red-100', text: 'text-red-600' };
        default: return { bg: 'bg-gray-100', text: 'text-gray-500' };
    }
};

const getStatusBadge = (status) => {
    switch(status) {
        case 'completed': 
        case 'paid':
            return 'bg-green-100 text-green-700';
        case 'pending': 
        case 'unpaid':
            return 'bg-orange-100 text-orange-700';
        case 'cancelled': return 'bg-red-100 text-red-700';
        default: return 'bg-gray-100 text-gray-700';
    }
};

watch(activeFilter, () => {
    selectedOrder.value = null;
    fetchOrders();
});

// Resume Payment - Load order to cart and navigate to Cashier
const resumePayment = (order) => {
    posStore.clearCart();
    
    order.items.forEach(item => {
        const product = {
            id: item.product_id,
            name: item.product_name || item.product?.name || 'Unknown',
            price: parseFloat(item.unit_price),
            image_url: item.product?.image_url,
            note: item.note
        };
        for (let i = 0; i < item.quantity; i++) {
            posStore.addToCart(product);
        }
    });
    
    if (order.customer) {
        posStore.selectCustomer(order.customer);
    }
    
    toast.info(`Loaded order: ${order.order_number}`);
    router.push('/pos');
};

// Request Cancel - Requires manager PIN
const requestCancel = (order) => {
    pendingAction.value = { type: 'cancel', order };
    pinModalMessage.value = 'Enter Manager PIN to cancel this order';
    isPinModalOpen.value = true;
};

// Request Refund - Requires manager PIN
const requestRefund = (order) => {
    pendingAction.value = { type: 'refund', order };
    pinModalMessage.value = 'Enter Manager PIN to refund this order';
    isPinModalOpen.value = true;
};

const handlePinSubmit = async (pin) => {
    if (!pendingAction.value) return;
    
    const { type, order } = pendingAction.value;
    pinLoading.value = true;

    try {
        if (type === 'cancel') {
            await api.post(`/admin/orders/${order.id}/cancel`, { manager_pin: pin });
            toast.success('Order cancelled successfully');
        } else if (type === 'refund') {
            await api.post(`/admin/orders/${order.id}/refund`, { manager_pin: pin });
            toast.success('Order refunded successfully');
        }
        
        isPinModalOpen.value = false;
        selectedOrder.value = null;
        fetchOrders();
    } catch (e) {
        toast.error(e.response?.data?.message || 'Failed to process request');
    } finally {
        pinLoading.value = false;
    }
};

// WhatsApp Logic
const sending = ref(false);
const showWaInput = ref(false);
const waNumber = ref('');

const toggleWaInput = () => {
    showWaInput.value = !showWaInput.value;
    if (showWaInput.value) {
        // Auto-fill phone
        let phone = '';
        if (selectedOrder.value.customer && selectedOrder.value.customer.phone) {
             phone = selectedOrder.value.customer.phone;
        } else if (selectedOrder.value.customer_phone) {
             phone = selectedOrder.value.customer_phone;
        }
        
        if (phone) {
            // Remove non-digits
            phone = phone.replace(/\D/g, '');
            // Strip 62 or 0 prefix for display if desired, or keep generic
            // Let's just strip leading 62 or 0 for cleaner input if it's Indonesian
             if (phone.startsWith('62')) phone = phone.substring(2);
             else if (phone.startsWith('0')) phone = phone.substring(1);
             waNumber.value = phone;
        } else {
             waNumber.value = '';
        }
    }
};

const sendToWa = async () => {
    if (!waNumber.value) return;
    
    const order = selectedOrder.value;
    if (!order) return;

    let phone = waNumber.value.replace(/\D/g, '');
    if (phone.startsWith('0')) {
        phone = '62' + phone.substring(1);
    } else if (!phone.startsWith('62')) {
        phone = '62' + phone;
    }
    
    sending.value = true;
    try {
        await api.post(`/orders/${order.id}/whatsapp-receipt`, {
            phone: phone
        });
        toast.success(`Receipt sent to +${phone}`);
        showWaInput.value = false;
    } catch (e) {
        console.error(e);
        toast.error(e.response?.data?.message || "Failed to send receipt");
    } finally {
        sending.value = false;
    }
};

const handlePrint = () => {
    window.print();
};

onMounted(() => {
    fetchOrders();
});
</script>
