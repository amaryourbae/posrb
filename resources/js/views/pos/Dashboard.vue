<template>
    <PosLayout>
        <div class="px-6 py-8 h-full overflow-y-auto bg-gray-50">
            <!-- Header -->
            <div class="mb-8 flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
                <div>
                    <h1 class="text-2xl font-bold text-gray-900 tracking-tight">
                        Hello, {{ authStore.user?.name || 'Cashier' }}
                    </h1>
                    <p class="text-gray-500 mt-1">
                        {{ currentDate }}
                    </p>
                </div>
                <div class="flex gap-3">
                     <button class="bg-white border border-gray-200 text-gray-700 px-4 py-2 rounded-xl font-bold text-sm hover:bg-gray-50 transition shadow-sm flex items-center gap-2">
                        <PrinterIcon class="w-4 h-4" />
                        Print Report
                    </button>
                    <router-link 
                        to="/pos"
                        class="bg-primary hover:bg-[#004d34] text-white px-6 py-2 rounded-xl font-bold text-sm transition shadow-lg shadow-primary/30 flex items-center gap-2"
                    >
                        <MonitorIcon class="w-4 h-4" />
                        Open Shift
                    </router-link>
                </div>
            </div>

            <!-- Stats Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-8">
                <StatsCard
                    title="Total Sales (Today)"
                    :value="formatCurrency(stats.today_sales || 0)"
                    :icon="DollarSignIcon"
                    iconBgClass="bg-green-100"
                    iconColorClass="text-green-600"
                    :trend="0"
                />
                <StatsCard
                    title="Transactions"
                    :value="stats.transaction_count || 0"
                    :icon="ShoppingBagIcon"
                    iconBgClass="bg-blue-100"
                    iconColorClass="text-blue-600"
                    :trend="0"
                />
                 <StatsCard
                    title="Cash in Drawer"
                    :value="formatCurrency(stats.cash_in_drawer || 1500000)"
                    :icon="WalletIcon"
                    iconBgClass="bg-purple-100"
                    iconColorClass="text-purple-600"
                    :trend="0"
                />
                <StatsCard
                    title="Pending Orders"
                    :value="stats.pending_count"
                    :icon="ClockIcon"
                    iconBgClass="bg-orange-100"
                    iconColorClass="text-orange-600"
                    :trend="0"
                />
            </div>

            <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <!-- Recent Orders -->
                <div class="lg:col-span-2 bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
                    <div class="p-6 border-b border-gray-100 flex justify-between items-center bg-white">
                        <h3 class="font-bold text-lg text-gray-900">Recent Transactions</h3>
                        <router-link to="/pos/history" class="text-sm font-bold text-primary hover:underline">View All</router-link>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="w-full text-left">
                            <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider">
                                <tr>
                                    <th class="px-6 py-4 font-semibold">Order ID</th>
                                    <th class="px-6 py-4 font-semibold">Customer</th>
                                    <th class="px-6 py-4 font-semibold">Amount</th>
                                    <th class="px-6 py-4 font-semibold">Status</th>
                                    <th class="px-6 py-4 font-semibold">Time</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-100 text-sm">
                                <tr v-if="orders.length === 0">
                                    <td colspan="5" class="px-6 py-8 text-center text-gray-400">No transactions today</td>
                                </tr>
                                <tr v-for="order in orders" :key="order.id" class="hover:bg-gray-50 transition-colors">
                                    <td class="px-6 py-4 font-medium text-gray-900 font-mono">{{ order.order_number }}</td>
                                    <td class="px-6 py-4 text-gray-600">{{ order.customer_name || 'Guest' }}</td>
                                    <td class="px-6 py-4 font-bold text-gray-900">{{ formatCurrency(order.grand_total) }}</td>
                                    <td class="px-6 py-4">
                                        <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-md text-xs font-bold" :class="getStatusBadge(order.payment_status)">
                                            {{ capitalize(order.payment_status) }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 text-gray-400 text-xs">{{ formatTime(order.created_at) }}</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Shift Status & Alerts Column -->
                <div class="space-y-6">
                    <!-- Shift Status Card -->
                    <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
                        <h3 class="font-bold text-lg text-gray-900 mb-4">Shift Status</h3>
                        
                        <div v-if="posStore.shift && posStore.shift.id">
                            <div class="flex items-center gap-4 mb-6">
                                <div class="w-12 h-12 rounded-full bg-green-100 flex items-center justify-center text-green-600 shrink-0">
                                    <ClockIcon class="w-6 h-6" />
                                </div>
                                <div>
                                    <p class="text-sm text-gray-500 font-medium">Clocked In At</p>
                                    <p class="text-lg font-bold text-gray-900">{{ startTime }}</p>
                                </div>
                            </div>

                            <div class="space-y-3">
                                 <div class="flex justify-between text-sm py-2 border-b border-gray-50">
                                    <span class="text-gray-500">Duration</span>
                                    <span class="font-bold text-gray-900">{{ shiftDuration }}</span>
                                </div>
                                <div class="flex justify-between text-sm py-2 border-b border-gray-50">
                                    <span class="text-gray-500">Starting Cash</span>
                                    <span class="font-bold text-gray-900">{{ formatCurrency(posStore.shift.starting_cash) }}</span>
                                </div>
                                <div class="flex justify-between text-sm py-2 border-b border-gray-50">
                                    <span class="text-gray-500">Cash Sales</span>
                                    <span class="font-bold text-green-600">+ {{ formatCurrency(posStore.shift.current_cash_sales || 0) }}</span>
                                </div>
                                <div class="flex justify-between text-sm py-2 border-b border-gray-50" v-if="posStore.shift.current_cash_refunds > 0">
                                    <span class="text-gray-500">Refunds</span>
                                    <span class="font-bold text-red-600">- {{ formatCurrency(posStore.shift.current_cash_refunds) }}</span>
                                </div>
                                 <div class="flex justify-between text-sm py-2 bg-gray-50 px-2 -mx-2 rounded-lg">
                                    <span class="text-gray-500 font-bold">Expected Cash</span>
                                    <span class="font-bold text-gray-900">{{ formatCurrency(posStore.shift.expected_cash || posStore.shift.starting_cash) }}</span>
                                </div>
                                <div class="text-xs text-gray-400 text-right mt-1">
                                    (Start + Sales - Refunds)
                                </div>
                            </div>

                            <button 
                                @click="handleCloseShift"
                                class="w-full mt-6 bg-red-50 hover:bg-red-100 text-red-600 font-bold py-3 rounded-xl transition flex items-center justify-center gap-2"
                            >
                                <LogOutIcon class="w-4 h-4" />
                                Close Shift
                            </button>
                        </div>
                        <div v-else class="text-center py-6">
                            <div class="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-3 text-gray-400">
                                <ClockIcon class="w-6 h-6" />
                            </div>
                            <p class="text-gray-500 text-sm mb-4">No active shift</p>
                            
                            <button 
                                @click="handleStartShift"
                                class="w-full bg-primary hover:bg-[#004d34] text-white font-bold py-3 rounded-xl transition flex items-center justify-center gap-2 mb-3 shadow-lg shadow-primary/30"
                            >
                                <ClockIcon class="w-4 h-4" />
                                Start Shift Now
                            </button>
                            
                            <router-link to="/pos" class="text-sm font-medium text-gray-500 hover:text-primary hover:underline">
                                Go to Register
                            </router-link>
                        </div>
                    </div>

                    <!-- Alerts Card -->
                    <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
                        <div class="flex justify-between items-center mb-4">
                            <h3 class="font-bold text-lg text-gray-900">Alerts</h3>
                            <span v-if="alerts.length > 0" class="bg-red-100 text-red-700 text-xs font-bold px-2 py-0.5 rounded-full">{{ alerts.length }}</span>
                        </div>
                        
                        <div v-if="alerts.length === 0" class="text-center py-4 text-gray-400 text-sm">
                            No active alerts
                        </div>

                        <div v-else class="space-y-3">
                            <div v-for="alert in alerts" :key="alert.id" class="p-3 bg-orange-50 rounded-xl border border-orange-100 flex items-start gap-3">
                                <AlertTriangleIcon class="w-5 h-5 text-orange-500 shrink-0 mt-0.5" />
                                <div>
                                    <h4 class="text-sm font-bold text-orange-800">Low Stock Warning</h4>
                                    <p class="text-xs text-orange-600 mt-1">
                                        <span class="font-bold">{{ alert.name }}</span> is running low. 
                                        Only {{ alert.current_stock }} {{ alert.unit }} remaining.
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div> 
            </div>
        </div>

        <ShiftModal 
            :is-open="isShiftModalOpen"
            :mode="shiftModalMode"
            :loading="shiftLoading"
            :expected-cash="stats.cash_in_drawer"
            @close="isShiftModalOpen = false"
            @submit="handleShiftSubmit"
        />
        <ShiftReceipt :shift="closedShift" />
    </PosLayout>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue';
import PosLayout from '../../components/layout/PosLayout.vue';
import StatsCard from '../../components/dashboard/StatsCard.vue';
import { useAuthStore } from '../../stores/auth';
import { usePosStore } from '../../stores/pos';
import api from '../../api/axios';
import { formatCurrency } from '../../utils/format';
import { 
    DollarSignIcon, ShoppingBagIcon, WalletIcon, ClockIcon, 
    MonitorIcon, PrinterIcon, LogOutIcon, AlertTriangleIcon 
} from 'lucide-vue-next';
import ShiftModal from '../../components/pos/ShiftModal.vue';
import ShiftReceipt from '../../components/pos/ShiftReceipt.vue';

const authStore = useAuthStore();
const posStore = usePosStore();
const currentDate = new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });

const stats = ref({
    today_sales: 0,
    transaction_count: 0,
    cash_in_drawer: 0,
    pending_count: 0
});

const alerts = ref([]);
const orders = ref([]);
const isShiftModalOpen = ref(false);
const shiftLoading = ref(false);
const shiftModalMode = ref('start');

// Reactive Pulse for Duration
const now = ref(new Date());
let timer;

const shiftDuration = computed(() => {
    if (!posStore.shift || !posStore.shift.start_time) return '0h 0m';
    const start = new Date(posStore.shift.start_time);
    const diffMs = now.value - start;
    const diffHrs = Math.floor(diffMs / 3600000);
    const diffMins = Math.floor((diffMs % 3600000) / 60000);
    return `${diffHrs}h ${diffMins}m`;
});

const startTime = computed(() => {
    if (!posStore.shift) return '-';
    return new Date(posStore.shift.start_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
});

const fetchStats = async () => {
    try {
        await posStore.fetchCurrentShift();
        
        const response = await api.get('/admin/pos/stats');
        const statsData = response.data?.data || response.data || {};
        stats.value = {
            ...statsData,
            cash_in_drawer: posStore.shift?.expected_cash || 0
        };
    } catch(e) {
        console.error('Error fetching stats:', e);
    }
};

const fetchRecentOrders = async () => {
    try {
        const response = await api.get('/admin/orders?per_page=5');
        const rawData = response.data?.data || response.data || {};
        orders.value = rawData.orders?.data || rawData.data || [];
    } catch (e) {
        console.error('Error fetching orders:', e);
    }
};

const fetchAlerts = async () => {
    try {
        const response = await api.get('/admin/inventory/alerts');
        const rawData = response.data?.data || response.data || [];
        alerts.value = Array.isArray(rawData) ? rawData : (rawData.data || []);
    } catch (e) {
        console.error('Error fetching alerts:', e);
    }
};

const handleStartShift = () => {
    shiftModalMode.value = 'start';
    isShiftModalOpen.value = true;
};

const handleCloseShift = () => {
    shiftModalMode.value = 'end';
    isShiftModalOpen.value = true;
};

const closedShift = ref(null);

const handleShiftSubmit = async (data) => {
    shiftLoading.value = true;
    try {
        if (shiftModalMode.value === 'start') {
            await posStore.startShift(data.amount);
            isShiftModalOpen.value = false;
            fetchStats();
        } else {
            // End Shift returns the closed shift object
            const response = await posStore.endShift({
                actual_cash: data.amount,
                note: data.note
            });
            
            // Store closed shift for printing
            closedShift.value = response; 
            
            isShiftModalOpen.value = false;
            fetchStats();
            
            // Trigger print after DOM update
            setTimeout(() => {
                window.print();
            }, 500);
        }
    } catch (e) {
        alert(e.message || 'Failed to update shift');
    } finally {
        shiftLoading.value = false;
    }
};

const formatTime = (date) => new Date(date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
const capitalize = (s) => s ? s.charAt(0).toUpperCase() + s.slice(1) : '';

const getStatusBadge = (status) => {
    switch(status) {
        case 'paid':
        case 'completed': return 'bg-green-100 text-green-700';
        case 'pending': return 'bg-orange-100 text-orange-700';
        case 'failed':
        case 'cancelled': return 'bg-red-100 text-red-700';
        default: return 'bg-gray-100 text-gray-700';
    }
};

onMounted(() => {
    fetchStats();
    fetchRecentOrders();
    fetchAlerts();
    timer = setInterval(() => { now.value = new Date(); }, 60000); // Update minute
});

onUnmounted(() => {
    if (timer) clearInterval(timer);
});
</script>
