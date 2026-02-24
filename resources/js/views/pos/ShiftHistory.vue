<template>
    <PosLayout>
        <div class="px-6 py-8 h-full overflow-y-auto bg-gray-50">
            <div class="flex justify-between items-center mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Shift History</h1>
                <div class="text-sm text-gray-500">
                    Showing your recent shifts
                </div>
            </div>

            <!-- Shift Table -->
            <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
                <div class="overflow-x-auto">
                    <table class="w-full text-left">
                        <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider">
                            <tr>
                                <th class="px-6 py-4 font-semibold">Start Time</th>
                                <th class="px-6 py-4 font-semibold">End Time</th>
                                <th class="px-6 py-4 font-semibold text-right">Starting Cash</th>
                                <th class="px-6 py-4 font-semibold text-right">Ending Cash</th>
                                <th class="px-6 py-4 font-semibold text-right">Difference</th>
                                <th class="px-6 py-4 font-semibold">Status</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100 text-sm">
                            <tr v-if="loading && shifts.length === 0">
                                <td colspan="6" class="px-6 py-8">
                                    <div class="flex justify-center">
                                        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                                    </div>
                                </td>
                            </tr>
                            <tr v-else-if="shifts.length === 0">
                                <td colspan="6" class="px-6 py-8 text-center text-gray-400">No shift history found</td>
                            </tr>
                            <tr v-for="shift in shifts" :key="shift.id" class="hover:bg-gray-50 transition-colors">
                                <td class="px-6 py-4 font-medium text-gray-900">
                                    {{ formatDate(shift.start_time) }}
                                </td>
                                <td class="px-6 py-4 text-gray-600">
                                    {{ shift.end_time ? formatDate(shift.end_time) : '-' }}
                                </td>
                                <td class="px-6 py-4 text-right font-mono">
                                    {{ formatCurrency(shift.starting_cash) }}
                                </td>
                                <td class="px-6 py-4 text-right font-mono">
                                    {{ shift.ending_cash_actual ? formatCurrency(shift.ending_cash_actual) : '-' }}
                                </td>
                                <td class="px-6 py-4 text-right font-mono" :class="getDiffClass(shift.difference)">
                                    {{ shift.difference ? formatCurrency(shift.difference) : '-' }}
                                </td>
                                <td class="px-6 py-4">
                                    <span 
                                        class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-md text-xs font-bold"
                                        :class="shift.status === 'open' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'"
                                    >
                                        {{ capitalize(shift.status) }}
                                    </span>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                
                <!-- Pagination -->
                <div v-if="pagination.last_page > 1" class="px-6 py-4 border-t border-gray-100 flex justify-center gap-2">
                    <button 
                        @click="changePage(pagination.current_page - 1)"
                        :disabled="pagination.current_page === 1"
                        class="px-3 py-1 rounded-lg border border-gray-200 text-sm hover:bg-gray-50 disabled:opacity-50"
                    >
                        Previous
                    </button>
                    <span class="px-3 py-1 text-sm text-gray-600">
                        Page {{ pagination.current_page }} of {{ pagination.last_page }}
                    </span>
                    <button 
                        @click="changePage(pagination.current_page + 1)"
                        :disabled="pagination.current_page === pagination.last_page"
                        class="px-3 py-1 rounded-lg border border-gray-200 text-sm hover:bg-gray-50 disabled:opacity-50"
                    >
                        Next
                    </button>
                </div>
            </div>
        </div>
    </PosLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import PosLayout from '../../components/layout/PosLayout.vue';
import { usePosStore } from '../../stores/pos';
import { useAuthStore } from '../../stores/auth';
import { formatCurrency } from '../../utils/format';

const posStore = usePosStore();
const authStore = useAuthStore();
const shifts = ref([]);
const loading = ref(false);
const pagination = ref({ current_page: 1, last_page: 1 });

const fetchShifts = async (page = 1) => {
    loading.value = true;
    try {
        const response = await posStore.fetchShifts({
            user_id: authStore.user?.id,
            page: page
        });
        // response is already unwrapped from the store
        shifts.value = Array.isArray(response.data) ? response.data : (response || []);
        pagination.value = {
            current_page: response.current_page || 1,
            last_page: response.last_page || 1
        };
    } catch (e) {
        // Error handled in store
    } finally {
        loading.value = false;
    }
};


const changePage = (page) => {
    if (page >= 1 && page <= pagination.value.last_page) {
        fetchShifts(page);
    }
};

const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString([], { 
        month: 'short', day: 'numeric', 
        hour: '2-digit', minute: '2-digit' 
    });
};

const capitalize = (s) => s.charAt(0).toUpperCase() + s.slice(1);

const getDiffClass = (diff) => {
    if (!diff) return 'text-gray-400';
    if (diff > 0) return 'text-green-600 font-bold';
    if (diff < 0) return 'text-red-600 font-bold';
    return 'text-gray-600';
};

onMounted(() => {
    fetchShifts();
});
</script>
