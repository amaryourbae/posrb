<template>
    <MainLayout :loading="loading">
        <div class="mb-6 flex justify-between items-center">
            <div>
                <button @click="$router.push('/admin/shifts')" class="text-sm text-gray-500 hover:text-gray-700 flex items-center mb-2">
                    <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path></svg>
                    Back to History
                </button>
                <h1 class="text-2xl font-bold text-slate-800">Shift Details</h1>
                <p class="text-gray-500 text-sm mt-1" v-if="shift">Cashier: {{ shift.user }}</p>
            </div>
            
            <div class="flex space-x-2 items-center" v-if="shift">
                <span :class="{
                    'bg-green-100 text-green-700': shift.status === 'open',
                    'bg-gray-100 text-gray-700': shift.status === 'closed'
                }" class="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide">
                    {{ shift.status }}
                </span>
            </div>
        </div>

        <div v-if="!loading && shift" class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <!-- Header Grid -->
            <div class="grid grid-cols-2 gap-4 border-b border-gray-100 p-6 bg-gray-50">
                <div>
                    <span class="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-1">Started</span>
                    <span class="text-slate-800 font-medium">{{ formatDate(shift.start_time) }}</span>
                </div>
                <div>
                     <span class="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-1">Ended</span>
                    <span class="text-slate-800 font-medium">{{ shift.end_time ? formatDate(shift.end_time) : 'Ongoing' }}</span>
                </div>
            </div>

            <!-- Items Section -->
            <div class="p-6 border-b border-gray-100">
                <h2 class="text-sm font-black tracking-wider text-slate-900 border-b-2 border-slate-300 pb-2 mb-4">ITEMS</h2>
                
                <div 
                    @click="showItemsModal('Sold Items', shift.items.sold)"
                    class="flex justify-between items-center py-4 border-b border-gray-100 cursor-pointer hover:bg-gray-50 px-2 rounded -mx-2 transition-colors"
                >
                    <span class="font-bold text-gray-800">Sold Items</span>
                    <div class="flex items-center text-gray-600">
                        <span class="font-medium mr-2">{{ shift.items.total_sold_qty }}</span>
                        <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
                    </div>
                </div>

                <div 
                    @click="showItemsModal('Refunded Items', shift.items.refunded)"
                    class="flex justify-between items-center py-4 cursor-pointer hover:bg-gray-50 px-2 rounded -mx-2 transition-colors"
                >
                    <span class="font-bold text-gray-800">Refunded Items</span>
                    <div class="flex items-center text-gray-600">
                        <span class="font-medium mr-2">{{ shift.items.total_refunded_qty }}</span>
                        <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
                    </div>
                </div>
            </div>

            <!-- Dashboard Financial Sections -->
            <div class="p-6 border-b border-gray-100">
                <h2 class="text-sm font-black tracking-wider text-slate-900 border-b-2 border-slate-300 pb-2 mb-4">CASH</h2>
                
                <div class="space-y-1">
                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-semibold text-gray-700 text-sm">STARTING CASH</span>
                        <span class="font-medium text-gray-900 text-sm">{{ formatCurrency(shift.financials.starting_cash) }}</span>
                    </div>
                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-semibold text-gray-700 text-sm">CASH SALES</span>
                        <span class="font-medium text-gray-900 text-sm">{{ formatCurrency(shift.financials.cash_sales) }}</span>
                    </div>
                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-semibold text-gray-700 text-sm">CASH FROM INVOICE</span>
                        <span class="font-medium text-gray-900 text-sm">{{ formatCurrency(shift.financials.cash_from_invoice) }}</span>
                    </div>
                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-semibold text-gray-700 text-sm">CASH REFUNDS</span>
                        <span class="font-medium text-gray-900 text-sm">{{ formatCurrency(shift.financials.cash_refunds) }}</span>
                    </div>
                    
                    <div class="flex justify-between py-3 border-b border-gray-50 pl-4 items-center group">
                        <div class="flex items-center text-gray-500">
                            <svg class="w-3 h-3 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M9 5l7 7-7 7"></path></svg>
                            <span class="font-semibold text-sm">TOTAL EXPENSE</span>
                        </div>
                        <span class="font-medium text-gray-900 text-sm">{{ formatCurrency(shift.financials.total_expense) }}</span>
                    </div>
                    
                    <div class="flex justify-between py-3 border-b border-gray-50 pl-4 items-center group">
                        <div class="flex items-center text-gray-500">
                            <svg class="w-3 h-3 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M9 5l7 7-7 7"></path></svg>
                            <span class="font-semibold text-sm">TOTAL INCOME</span>
                        </div>
                        <span class="font-medium text-gray-900 text-sm">{{ formatCurrency(shift.financials.total_income) }}</span>
                    </div>

                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-bold text-gray-900 text-sm">EXPECTED ENDING CASH</span>
                        <span class="font-bold text-gray-900 text-sm">{{ formatCurrency(shift.financials.expected_ending_cash) }}</span>
                    </div>
                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-bold text-gray-900 text-sm">ACTUAL ENDING CASH</span>
                        <span class="font-bold text-gray-900 text-sm">{{ formatCurrency(shift.financials.actual_ending_cash) }}</span>
                    </div>
                </div>
            </div>

            <!-- Second Cash Breakdown -->
            <div class="p-6 border-b border-gray-100">
                <h2 class="text-sm font-black tracking-wider text-slate-900 border-b-2 border-slate-300 pb-2 mb-4">CASH</h2>
                <div class="space-y-1">
                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-semibold text-gray-700 text-sm">CASH</span>
                        <span class="font-medium text-gray-900 text-sm">{{ formatCurrency(shift.financials.cash_sales) }}</span>
                    </div>
                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-semibold text-gray-700 text-sm">CASH REFUNDS</span>
                        <span class="font-medium text-gray-900 text-sm">{{ formatCurrency(shift.financials.cash_refunds) }}</span>
                    </div>
                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-bold text-gray-900 text-sm">EXPECTED CASH PAYMENT</span>
                        <span class="font-bold text-gray-900 text-sm">{{ formatCurrency(shift.financials.expected_cash_payment) }}</span>
                    </div>
                </div>
            </div>

            <!-- Total Difference -->
            <div class="p-6">
                <h2 class="text-sm font-black tracking-wider text-slate-900 border-b-2 border-slate-300 pb-2 mb-4">TOTAL</h2>
                <div class="space-y-1">
                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-bold text-gray-900 text-sm">TOTAL EXPECTED</span>
                        <span class="font-bold text-gray-900 text-sm">{{ formatCurrency(shift.financials.expected_ending_cash) }}</span>
                    </div>
                    <div class="flex justify-between py-3 border-b border-gray-50">
                        <span class="font-bold text-gray-900 text-sm">TOTAL ACTUAL</span>
                        <span class="font-bold text-gray-900 text-sm">{{ formatCurrency(shift.financials.actual_ending_cash) }}</span>
                    </div>
                    <div class="flex justify-between py-3">
                        <span class="font-bold text-gray-900 text-sm">DIFFERENCE</span>
                        <span class="font-bold text-sm" :class="shift.financials.difference < 0 ? 'text-red-500' : 'text-gray-900'">
                            {{ formatDifference(shift.financials.difference) }}
                        </span>
                    </div>
                </div>
            </div>
        </div>

        <div v-else-if="!loading && !shift" class="text-center py-20 bg-white rounded-xl shadow-sm border border-gray-200">
            <svg class="w-12 h-12 text-gray-300 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <h3 class="text-lg font-medium text-gray-900">Shift not found</h3>
            <p class="mt-1 text-gray-500">The shift detail you are looking for does not exist.</p>
            <button @click="$router.push('/admin/shifts')" class="mt-6 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors">
                Back to Shifts
            </button>
        </div>
        
        <!-- Modal for Items -->
        <div v-if="isModalOpen" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
            <div class="bg-white rounded-xl shadow-lg w-full max-w-md mx-4 overflow-hidden">
                <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
                    <h3 class="text-lg font-bold text-gray-900">{{ modalTitle }}</h3>
                    <button @click="isModalOpen = false" class="text-gray-400 hover:text-gray-600 transition-colors">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                    </button>
                </div>
                
                <div class="p-6">
                    <div v-if="modalItems.length === 0" class="text-center py-8 text-gray-500">
                        No items found.
                    </div>
                    <div v-else class="max-h-96 overflow-y-auto pr-2">
                        <div v-for="(item, idx) in modalItems" :key="idx" class="flex justify-between items-center py-3 border-b border-gray-100 last:border-0">
                            <span class="font-medium text-gray-800">{{ item.name }}</span>
                            <span class="bg-gray-100 text-gray-600 px-3 py-1 rounded-full text-sm font-semibold">Qty: {{ item.qty }}</span>
                        </div>
                    </div>
                </div>
                
                <div class="px-6 py-4 bg-gray-50 flex justify-end">
                    <button @click="isModalOpen = false" class="px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium text-sm">
                        Close
                    </button>
                </div>
            </div>
        </div>

    </MainLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import MainLayout from '../../../components/layout/MainLayout.vue';
import api from '../../../api/axios';
import { format as dateFormat } from 'date-fns';

const route = useRoute();
const shift = ref(null);
const loading = ref(true);

// Modal state
const isModalOpen = ref(false);
const modalTitle = ref('');
const modalItems = ref([]);

const fetchShift = async () => {
    loading.value = true;
    try {
        const response = await api.get(`/admin/shifts/${route.params.id}`);
        shift.value = response.data?.data || response.data;
    } catch (error) {
        console.error("Fetch shift detail failed", error);
    } finally {
        loading.value = false;
    }
};

const showItemsModal = (title, items) => {
    modalTitle.value = title;
    modalItems.value = items || [];
    isModalOpen.value = true;
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value).replace('Rp', 'RP.');
};

const formatDifference = (value) => {
    if (value < 0) {
        const formatted = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(Math.abs(value)).replace('Rp', 'RP.');
        return `(${formatted})`;
    }
    return formatCurrency(value);
};

const formatDate = (dateString) => {
    return dateFormat(new Date(dateString), 'dd MMM yyyy HH:mm');
};

onMounted(() => {
    fetchShift();
});
</script>
