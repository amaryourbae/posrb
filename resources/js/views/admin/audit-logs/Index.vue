<template>
    <MainLayout :loading="pageLoading">
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
            <div>
                <h1 class="text-2xl font-bold text-slate-800">Security Audit Logs</h1>
                <div class="text-gray-500 text-sm">System activity history</div>
            </div>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
             <!-- Search -->
             <div class="p-6 border-b border-gray-100 bg-gray-50/50">
                 <div class="relative w-full md:w-96">
                    <span class="absolute inset-y-0 left-0 flex items-center pl-3">
                        <SearchIcon class="w-5 h-5 text-gray-400" />
                    </span>
                    <input 
                        v-model="search" 
                        @input="debouncedSearch"
                        type="text" 
                        placeholder="Search logs..." 
                        class="pl-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary w-full py-2 shadow-sm"
                    >
                 </div>
             </div>

            <div class="overflow-x-auto">
                <table class="w-full text-left whitespace-nowrap">
                    <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                        <tr>
                            <th class="px-6 py-4 font-semibold">User</th>
                            <th class="px-6 py-4 font-semibold">Action</th>
                            <th class="px-6 py-4 font-semibold">Description</th>
                            <th class="px-6 py-4 font-semibold">Date</th>
                            <th class="px-6 py-4 font-semibold">IP Address</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 text-sm">
                        <tr v-for="log in (logs.data || []).filter(l => l != null)" :key="log.id" class="hover:bg-gray-50 transition-colors">
                            <td class="px-6 py-4">
                                <div class="font-bold text-slate-800">{{ log.user?.name || 'System' }}</div>
                                <div class="text-xs text-gray-500">{{ log.user?.email }}</div>
                            </td>
                            <td class="px-6 py-4">
                                 <span :class="{
                                    'bg-green-100 text-green-700': log.action.includes('created'),
                                    'bg-blue-100 text-blue-700': log.action.includes('updated'),
                                    'bg-red-100 text-red-700': log.action.includes('deleted'),
                                    'bg-gray-100 text-gray-700': !['created', 'updated', 'deleted'].some(a => log.action.includes(a))
                                }" class="px-2 py-1 rounded-full text-xs font-bold uppercase">
                                    {{ log.action }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-gray-600">{{ log.description }}</td>
                            <td class="px-6 py-4 text-gray-500 text-xs whitespace-nowrap">
                                {{ formatDate(log.created_at) }}
                            </td>
                            <td class="px-6 py-4 text-gray-400 font-mono text-xs">{{ log.ip_address }}</td>
                        </tr>
                        <tr v-if="logs.data?.length === 0">
                            <td colspan="5" class="px-6 py-12 text-center text-gray-400">No logs found</td>
                        </tr>
                    </tbody>
                </table>
            </div>
             <!-- Pagination -->
            <div class="p-6 border-t border-gray-100 flex flex-col md:flex-row justify-between items-center gap-4 bg-gray-50/30">
                <span class="text-sm text-gray-500 font-medium" v-if="logs.total">
                     Showing {{ logs.from }} to {{ logs.to }} of {{ logs.total }} results
                </span>
                <span v-else></span>
                <div class="space-x-2">
                    <button 
                        @click="changePage(logs.current_page - 1)" 
                        :disabled="!logs.prev_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all"
                    >Previous</button>
                    <button 
                        @click="changePage(logs.current_page + 1)" 
                        :disabled="!logs.next_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all"
                    >Next</button>
                </div>
            </div>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import MainLayout from '../../../components/layout/MainLayout.vue';
import { SearchIcon } from 'lucide-vue-next';
import api from '../../../api/axios';
import { format as dateFormat } from 'date-fns';

const logs = ref({ data: [] });
const search = ref('');
const pageLoading = ref(true);

const fetchLogs = async (page = 1) => {
    try {
        const response = await api.get('/admin/audit-logs', {
            params: { page, search: search.value }
        });
        logs.value = response.data?.data || response.data || {};
    } catch (error) {
        console.error("Fetch logs failed", error);
    } finally {
        pageLoading.value = false;
    }
};

let debounceTimeout = null;
const debouncedSearch = () => {
    if (debounceTimeout) clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
        fetchLogs(1);
    }, 300);
};

const changePage = (page) => {
    if (page >= 1 && page <= logs.value.last_page) {
        fetchLogs(page);
    }
};

const formatDate = (dateString) => {
    return dateFormat(new Date(dateString), 'dd MMM yyyy HH:mm');
};

onMounted(() => {
    fetchLogs();
});
</script>
