<template>
    <MainLayout :loading="pageLoading">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-slate-800">Shift History (Cash Drawer)</h1>
            <div class="flex space-x-2">
                <input type="date" v-model="filterDate" @change="fetchShifts" class="border-gray-300 rounded-lg text-sm focus:ring-primary focus:border-primary px-3 py-2 shadow-sm">
            </div>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
            <table class="w-full text-left">
                <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                    <tr>
                        <th class="px-6 py-4 font-semibold">Staff</th>
                        <th class="px-6 py-4 font-semibold">Start Time</th>
                        <th class="px-6 py-4 font-semibold">End Time</th>
                        <th class="px-6 py-4 font-semibold text-right">Starting Cash</th>
                        <th class="px-6 py-4 font-semibold text-right">Expected</th>
                        <th class="px-6 py-4 font-semibold text-right">Actual</th>
                        <th class="px-6 py-4 font-semibold text-right">Diff</th>
                        <th class="px-6 py-4 font-semibold text-center">Status</th>
                        <th class="px-6 py-4 font-semibold text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    <tr v-for="shift in (shifts.data || []).filter(s => s != null)" :key="shift.id" class="hover:bg-gray-50 transition-colors">
                        <td class="px-6 py-4 font-bold text-slate-800">{{ shift.user?.name || 'Unknown' }}</td>
                        <td class="px-6 py-4 text-gray-600">
                            {{ formatDate(shift.start_time) }}
                        </td>
                        <td class="px-6 py-4 text-gray-600">
                            {{ shift.end_time ? formatDate(shift.end_time) : '-' }}
                        </td>
                        <td class="px-6 py-4 text-right font-mono">{{ formatCurrency(shift.starting_cash) }}</td>
                        <td class="px-6 py-4 text-right font-mono">{{ shift.end_time ? formatCurrency(shift.ending_cash_expected) : '-' }}</td>
                        <td class="px-6 py-4 text-right font-mono font-bold">{{ shift.end_time ? formatCurrency(shift.ending_cash_actual) : '-' }}</td>
                         <td class="px-6 py-4 text-right font-mono font-bold" :class="shift.difference < 0 ? 'text-red-500' : 'text-green-500'">
                            {{ shift.difference ? formatCurrency(shift.difference) : '-' }}
                        </td>
                        <td class="px-6 py-4 text-center">
                            <span :class="{
                                'bg-green-100 text-green-700': shift.status === 'open',
                                'bg-gray-100 text-gray-700': shift.status === 'closed'
                            }" class="px-2 py-1 rounded-full text-xs font-bold uppercase tracking-wide">
                                {{ shift.status }}
                            </span>
                        </td>
                        <td class="px-6 py-4 text-right">
                            <router-link :to="`/admin/shifts/${shift.id}`" class="text-primary hover:text-primary-dark font-semibold text-sm">
                                View Details
                            </router-link>
                        </td>
                    </tr>
                    <tr v-if="shifts.data?.length === 0">
                        <td colspan="9" class="px-6 py-12 text-center text-gray-400">No shift records found</td>
                    </tr>
                </tbody>
            </table>
            
             <!-- Pagination -->
            <div class="p-6 border-t border-gray-100 flex justify-end">
                <div class="space-x-2">
                    <button 
                        @click="changePage(shifts.current_page - 1)" 
                        :disabled="!shifts.prev_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 transition-all"
                    >Previous</button>
                    <button 
                        @click="changePage(shifts.current_page + 1)" 
                        :disabled="!shifts.next_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 transition-all"
                    >Next</button>
                </div>
            </div>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import MainLayout from '../../../components/layout/MainLayout.vue';
import api from '../../../api/axios';
import { format as dateFormat } from 'date-fns';

const shifts = ref({ data: [] });
const pageLoading = ref(true);
const filterDate = ref('');

const fetchShifts = async (page = 1) => {
    try {
        const response = await api.get('/admin/shifts', {
            params: { page, date: filterDate.value }
        });
        shifts.value = response.data?.data || response.data || {};
    } catch (error) {
        console.error("Fetch shifts failed", error);
    } finally {
        pageLoading.value = false;
    }
};

const changePage = (page) => {
    if (page >= 1 && page <= shifts.value.last_page) {
        fetchShifts(page);
    }
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(value);
};

const formatDate = (dateString) => {
    return dateFormat(new Date(dateString), 'dd MMM HH:mm');
};

onMounted(() => {
    fetchShifts();
});
</script>
