<template>
  <MainLayout>
    <div class="mb-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
      <div>
        <h1 class="text-2xl font-bold text-slate-800">Laporan Stok (In/Out)</h1>
        <p class="text-gray-500 mt-1">Lacak pergerakan stok bahan baku dan pengeluaran.</p>
      </div>

      <div class="flex items-center gap-3">
        <!-- Date Filters -->
        <div class="flex items-center bg-white rounded-xl shadow-sm border border-gray-100 p-1">
          <input 
            type="date" 
            v-model="filters.start_date"
            class="px-3 py-2 text-sm border-none focus:ring-0 text-gray-600 bg-transparent"
          >
          <span class="text-gray-400 px-2">-</span>
          <input 
            type="date" 
            v-model="filters.end_date"
            class="px-3 py-2 text-sm border-none focus:ring-0 text-gray-600 bg-transparent"
          >
        </div>

        <!-- Type Filter -->
        <select 
            v-model="filters.type"
            class="bg-white border border-gray-200 text-gray-700 text-sm rounded-xl focus:ring-primary focus:border-primary block p-2.5 shadow-sm"
        >
            <option value="all">Semua Tipe</option>
            <option value="in">Stock In</option>
            <option value="out">Stock Out</option>
        </select>

        <button 
          @click="fetchData"
          class="btn btn-primary"
        >
          <FilterIcon class="w-4 h-4 mr-2" />
          Filter
        </button>

        <button 
          @click="exportToExcel"
          class="btn btn-outline"
        >
          <DownloadIcon class="w-4 h-4 mr-2" />
          Export CSV
        </button>
      </div>
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
      <div class="bg-white rounded-2xl p-6 border border-gray-100 shadow-sm relative overflow-hidden group">
        <div class="absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity">
          <ArrowDownCircleIcon class="w-24 h-24 text-green-500" />
        </div>
        <div class="flex items-center gap-4 relative">
          <div class="p-3 bg-green-50 text-green-600 rounded-xl">
            <ArrowDownCircleIcon class="w-6 h-6" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500 mb-1">Total Stock In (Nilai)</p>
            <h3 class="text-2xl font-bold text-gray-900">{{ formatCurrency(stats.total_in) }}</h3>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl p-6 border border-gray-100 shadow-sm relative overflow-hidden group">
        <div class="absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity">
          <ArrowUpCircleIcon class="w-24 h-24 text-red-500" />
        </div>
        <div class="flex items-center gap-4 relative">
          <div class="p-3 bg-red-50 text-red-600 rounded-xl">
            <ArrowUpCircleIcon class="w-6 h-6" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500 mb-1">Total Stock Out (Nilai)</p>
            <h3 class="text-2xl font-bold text-gray-900">{{ formatCurrency(stats.total_out) }}</h3>
          </div>
        </div>
      </div>
    </div>

    <!-- Data Table -->
    <div class="bg-white border border-gray-100 shadow-sm rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-sm text-left text-gray-500">
                <thead class="text-xs text-gray-500 uppercase bg-gray-50/50 border-b border-gray-100">
                    <tr>
                        <th scope="col" class="px-6 py-4 font-semibold">Tanggal</th>
                        <th scope="col" class="px-6 py-4 font-semibold">Bahan Baku</th>
                        <th scope="col" class="px-6 py-4 font-semibold text-center">Tipe</th>
                        <th scope="col" class="px-6 py-4 font-semibold text-right">Qty</th>
                        <th scope="col" class="px-6 py-4 font-semibold text-right">Total Nilai</th>
                        <th scope="col" class="px-6 py-4 font-semibold">Ref/Notes</th>
                        <th scope="col" class="px-6 py-4 font-semibold">Staff</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50">
                    <tr v-if="loading" class="animate-pulse">
                        <td colspan="7" class="px-6 py-8 text-center text-gray-400">
                            Memuat data laporan...
                        </td>
                    </tr>
                    <tr v-else-if="transactions.length === 0">
                        <td colspan="7" class="px-6 py-12 text-center text-gray-500">
                            <div class="flex flex-col items-center justify-center">
                                <FileTextIcon class="w-12 h-12 text-gray-300 mb-4" />
                                <p class="text-lg font-medium text-gray-900">Tidak ada transaksi</p>
                                <p class="text-sm">Tidak ada data stok masuk/keluar pada periode ini.</p>
                            </div>
                        </td>
                    </tr>
                    <tr v-for="item in transactions" :key="item.id" class="hover:bg-gray-50/50 transition-colors">
                        <td class="px-6 py-4 font-medium text-gray-900">
                            <div class="flex flex-col">
                                <span>{{ formatDate(item.created_at) }}</span>
                                <span class="text-xs text-gray-400">{{ formatTime(item.created_at) }}</span>
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            <span class="font-medium text-gray-900">{{ item.ingredient?.name || '-' }}</span>
                        </td>
                        <td class="px-6 py-4 text-center">
                            <span class="px-2.5 py-1 text-xs font-medium rounded-full"
                                :class="item.type === 'in' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'">
                                {{ item.type === 'in' ? 'STOCK IN' : 'STOCK OUT' }}
                            </span>
                        </td>
                        <td class="px-6 py-4 text-right">
                            {{ item.quantity }} {{ item.ingredient?.unit?.symbol }}
                        </td>
                        <td class="px-6 py-4 text-right font-medium">
                            <span :class="item.type === 'in' ? 'text-gray-900' : 'text-red-600'">
                                {{ formatCurrency(item.total_cost) }}
                            </span>
                        </td>
                        <td class="px-6 py-4">
                            <div class="max-w-[200px] truncate" :title="(item.reference ? item.reference + ' - ' : '') + item.notes">
                                <span v-if="item.reference" class="text-xs font-semibold bg-gray-100 px-1.5 py-0.5 rounded text-gray-600 mr-1">{{ item.reference }}</span>
                                {{ item.notes || '-' }}
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            {{ item.user?.name || 'System' }}
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        
        <!-- Pagination -->
        <div v-if="meta.last_page > 1" class="px-6 py-4 border-t border-gray-100 bg-gray-50/50 flex items-center justify-between">
            <span class="text-sm text-gray-500">
                Menampilkan <span class="font-medium text-gray-900">{{ (meta.current_page - 1) * meta.per_page + 1 }}</span> 
                hingga <span class="font-medium text-gray-900">{{ Math.min(meta.current_page * meta.per_page, meta.total) }}</span> 
                dari <span class="font-medium text-gray-900">{{ meta.total }}</span> entri
            </span>
            <div class="flex gap-2">
                <button 
                    @click="changePage(meta.current_page - 1)"
                    :disabled="meta.current_page === 1"
                    class="p-2 border border-gray-200 rounded-lg hover:bg-white disabled:opacity-50 transition-colors"
                >
                    <ChevronLeftIcon class="w-4 h-4" />
                </button>
                <button 
                    @click="changePage(meta.current_page + 1)"
                    :disabled="meta.current_page === meta.last_page"
                    class="p-2 border border-gray-200 rounded-lg hover:bg-white disabled:opacity-50 transition-colors"
                >
                    <ChevronRightIcon class="w-4 h-4" />
                </button>
            </div>
        </div>
    </div>
  </MainLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import MainLayout from '../../../components/layout/MainLayout.vue';
import api from '../../../api/axios';
import { useToast } from 'vue-toastification';
import { 
    FilterIcon, 
    DownloadIcon,
    ArrowDownCircleIcon,
    ArrowUpCircleIcon,
    FileTextIcon,
    ChevronLeftIcon,
    ChevronRightIcon
} from 'lucide-vue-next';

const toast = useToast();
const loading = ref(false);
const transactions = ref([]);
const stats = ref({ total_in: 0, total_out: 0 });

const filters = ref({
    start_date: new Date(new Date().setDate(1)).toISOString().split('T')[0], // First day of month
    end_date: new Date().toISOString().split('T')[0], // Today
    type: 'all'
});

const meta = ref({
    current_page: 1,
    last_page: 1,
    per_page: 15,
    total: 0
});

const formatCurrency = (value) => {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(value);
};

const formatDate = (dateString) => {
    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit', month: 'short', year: 'numeric'
    }).format(new Date(dateString));
};

const formatTime = (dateString) => {
    return new Intl.DateTimeFormat('id-ID', {
        hour: '2-digit', minute: '2-digit'
    }).format(new Date(dateString));
};

const fetchData = async (page = 1) => {
    loading.value = true;
    try {
        const response = await api.get('/reports/inventory-transactions', {
            params: {
                ...filters.value,
                page
            }
        });
        
        transactions.value = response.data.data;
        stats.value = response.data.stats;
        meta.value = response.data.meta;
    } catch (error) {
        toast.error('Gagal memuat laporan stok');
        console.error(error);
    } finally {
        loading.value = false;
    }
};

const changePage = (page) => {
    if (page >= 1 && page <= meta.value.last_page) {
        fetchData(page);
    }
};

const exportToExcel = async () => {
    try {
        const queryParams = new URLSearchParams(filters.value).toString();
        const response = await api.get(`/reports/export-inventory?${queryParams}`, {
            responseType: 'blob'
        });

        // Create a blob from the response
        const blob = new Blob([response.data], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        
        const fileName = `laporan_stok_${filters.value.start_date}_sampai_${filters.value.end_date}.csv`;
        link.setAttribute('download', fileName);
        
        document.body.appendChild(link);
        link.click();
        
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
        
        toast.success('Laporan berhasil diexport');
    } catch (error) {
        console.error("Export error", error);
        toast.error('Gagal export laporan');
    }
};

onMounted(() => {
    fetchData();
});
</script>
