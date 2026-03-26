<template>
    <MainLayout :loading="loading">
        <div class="mb-8 flex justify-between items-end">
            <div>
                <h1 class="text-3xl font-bold text-slate-800 tracking-tight">
                    Laporan Laba Rugi (HPP)
                </h1>
                <p class="text-gray-500 mt-2">
                    Analisa pendapatan bersih, Harga Pokok Penjualan (HPP), dan margin keuntungan.
                </p>
            </div>
            
            <div class="flex items-center space-x-3">
                <!-- Date Picker placeholder (Manual) -->
                <div class="flex items-center bg-white border border-gray-200 rounded-xl p-1 shadow-sm">
                    <button 
                        v-for="range in ['today', 'week', 'month']" 
                        :key="range"
                        @click="activeRange = range; fetchReport()"
                        class="px-4 py-2 rounded-lg text-sm font-bold transition-all"
                        :class="activeRange === range ? 'bg-primary text-white shadow-md' : 'text-gray-500 hover:bg-gray-50'"
                    >
                        {{ range === 'today' ? 'Hari Ini' : (range === 'week' ? 'Minggu Ini' : 'Bulan Ini') }}
                    </button>
                </div>

                <div class="h-10 w-px bg-gray-200 mx-2"></div>

                <button
                    @click="exportReport"
                    class="bg-white border border-gray-200 text-slate-700 px-5 py-2.5 rounded-xl font-bold hover:bg-gray-50 transition-all shadow-sm flex items-center"
                >
                    <DownloadIcon class="w-4 h-4 mr-2" />
                    Export
                </button>
            </div>
        </div>

        <!-- Summary Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div class="bg-white p-6 rounded-3xl shadow-sm border border-gray-100 relative overflow-hidden group">
                <div class="absolute -right-4 -top-4 w-24 h-24 bg-blue-50 rounded-full transition-transform group-hover:scale-110"></div>
                <div class="relative">
                    <div class="bg-blue-100 p-2 rounded-xl inline-flex mb-4">
                        <DollarSignIcon class="w-5 h-5 text-blue-600" />
                    </div>
                    <div class="text-gray-500 text-sm font-medium mb-1">Total Pendapatan</div>
                    <div class="text-2xl font-black text-slate-800 tracking-tight">{{ formatCurrency(summary.total_revenue) }}</div>
                </div>
            </div>

            <div class="bg-white p-6 rounded-3xl shadow-sm border border-gray-100 relative overflow-hidden group">
                <div class="absolute -right-4 -top-4 w-24 h-24 bg-orange-50 rounded-full transition-transform group-hover:scale-110"></div>
                <div class="relative">
                    <div class="bg-orange-100 p-2 rounded-xl inline-flex mb-4">
                        <PackageIcon class="w-5 h-5 text-orange-600" />
                    </div>
                    <div class="text-gray-500 text-sm font-medium mb-1">Total HPP (COGS)</div>
                    <div class="text-2xl font-black text-slate-800 tracking-tight">{{ formatCurrency(summary.total_cogs) }}</div>
                </div>
            </div>

            <div class="bg-white p-6 rounded-3xl shadow-sm border border-gray-100 relative overflow-hidden group">
                <div class="absolute -right-4 -top-4 w-24 h-24 bg-green-50 rounded-full transition-transform group-hover:scale-110"></div>
                <div class="relative">
                    <div class="bg-green-100 p-2 rounded-xl inline-flex mb-4">
                        <TrendingUpIcon class="w-5 h-5 text-green-600" />
                    </div>
                    <div class="text-gray-500 text-sm font-medium mb-1">Laba Kotor</div>
                    <div class="text-2xl font-black text-green-600 tracking-tight">{{ formatCurrency(summary.gross_profit) }}</div>
                </div>
            </div>

            <div class="bg-white p-6 rounded-3xl shadow-sm border border-gray-100 relative overflow-hidden group">
                <div class="absolute -right-4 -top-4 w-24 h-24 bg-purple-50 rounded-full transition-transform group-hover:scale-110"></div>
                <div class="relative">
                    <div class="bg-purple-100 p-2 rounded-xl inline-flex mb-4">
                        <PieChartIcon class="w-5 h-5 text-purple-600" />
                    </div>
                    <div class="text-gray-500 text-sm font-medium mb-1">Margin Keuntungan</div>
                    <div class="text-2xl font-black text-slate-800 tracking-tight">{{ summary.profit_margin }}%</div>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <!-- Chart Side -->
            <div class="lg:col-span-2 space-y-8">
                <div class="bg-white p-8 rounded-3xl shadow-sm border border-gray-100">
                    <div class="flex justify-between items-center mb-8">
                        <div>
                            <h3 class="font-bold text-xl text-slate-800">Tren Laba Rugi</h3>
                            <p class="text-sm text-gray-400 mt-1">Pergerakan omset vs modal vs profit.</p>
                        </div>
                    </div>
                    <div class="h-96 relative">
                        <Line v-if="chartData" :data="chartData" :options="chartOptions" />
                        <div v-else class="flex flex-col items-center justify-center h-full text-gray-400">
                            <BarChart3Icon class="w-12 h-12 mb-2 opacity-20" />
                            <span>Loading chart data...</span>
                        </div>
                    </div>
                </div>

                <!-- Product Table -->
                <div class="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
                    <div class="p-8 border-b border-gray-50 bg-gray-50/30 flex justify-between items-center">
                        <div>
                            <h3 class="font-bold text-xl text-slate-800">Breakdown per Produk</h3>
                            <p class="text-sm text-gray-400 mt-1">Detail margin untuk setiap item.</p>
                        </div>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="w-full text-left">
                            <thead class="bg-gray-50/50 text-gray-500 text-xs uppercase tracking-widest">
                                <tr>
                                    <th class="px-8 py-4 font-bold">Produk</th>
                                    <th class="px-8 py-4 font-bold text-center">Terjual</th>
                                    <th class="px-8 py-4 font-bold text-right">Revenue</th>
                                    <th class="px-8 py-4 font-bold text-right">Modal (HPP)</th>
                                    <th class="px-8 py-4 font-bold text-right">Laba</th>
                                    <th class="px-8 py-4 font-bold text-right">Margin</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-50 text-sm">
                                <tr v-for="item in productBreakdown" :key="item.product_id" class="hover:bg-gray-50/50 transition-colors">
                                    <td class="px-8 py-5 font-bold text-slate-800">
                                        {{ item.product_name }}
                                    </td>
                                    <td class="px-8 py-5 text-center text-gray-600 font-medium">
                                        {{ item.quantity_sold }}
                                    </td>
                                    <td class="px-8 py-5 text-right text-slate-800 font-medium">
                                        {{ formatCurrency(item.total_revenue) }}
                                    </td>
                                    <td class="px-8 py-5 text-right text-gray-500 font-medium">
                                        {{ formatCurrency(item.total_cogs) }}
                                    </td>
                                    <td class="px-8 py-5 text-right font-bold text-green-600">
                                        {{ formatCurrency(item.gross_profit) }}
                                    </td>
                                    <td class="px-8 py-5 text-right">
                                        <div class="flex items-center justify-end">
                                            <span 
                                                class="px-2 py-1 rounded-lg text-xs font-bold"
                                                :class="item.profit_margin > 50 ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'"
                                            >
                                                {{ item.profit_margin }}%
                                            </span>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="!productBreakdown.length">
                                    <td colspan="6" class="px-8 py-20 text-center text-gray-400 font-medium italic">
                                        Belum ada data transaksi dalam periode ini.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- Side Cards -->
            <div class="space-y-8">
                <div class="bg-white p-8 rounded-3xl shadow-sm border border-gray-100">
                    <h3 class="font-bold text-xl text-slate-800 mb-6 flex items-center">
                        <AlertCircleIcon class="w-5 h-5 mr-2 text-primary" />
                        Analisa Margin
                    </h3>
                    <div class="space-y-6">
                        <div class="p-4 rounded-2xl bg-slate-50 border border-slate-100">
                            <div class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-1">Rekomendasi</div>
                            <p class="text-sm text-slate-600 leading-relaxed font-medium">
                                Margin Anda saat ini adalah <span class="text-primary font-bold">{{ summary.profit_margin }}%</span>. 
                                <span v-if="summary.profit_margin < 40">Disarankan untuk meninjau kembali HPP bahan baku atau menaikkan harga jual produk dengan margin rendah.</span>
                                <span v-else>Performa margin Anda sangat baik dan sehat untuk bisnis F&B.</span>
                            </p>
                        </div>
                        
                        <div v-if="productBreakdown.length > 0">
                            <div class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">Item Paling Menguntungkan</div>
                            <div class="flex items-center justify-between p-3 bg-green-50 rounded-2xl border border-green-100">
                                <div class="font-bold text-green-800 text-sm truncate mr-2">{{ productBreakdown[0].product_name }}</div>
                                <div class="bg-green-600 text-white text-[10px] font-black px-2 py-0.5 rounded-full">{{ productBreakdown[0].profit_margin }}%</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="bg-[#5a6c37] p-8 rounded-3xl shadow-lg relative overflow-hidden group">
                    <div class="absolute right-0 bottom-0 opacity-10 group-hover:rotate-12 transition-transform duration-500">
                        <PackageSearchIcon class="w-32 h-32 text-white" />
                    </div>
                    <div class="relative z-10 text-white">
                        <h4 class="font-bold text-xl mb-2">Pantau Stok?</h4>
                        <p class="text-white/80 text-sm font-medium mb-6">
                            Pastikan ketersediaan bahan baku sesuai dengan HPP yang dihitung.
                        </p>
                        <router-link to="/admin/ingredients" class="bg-white/10 hover:bg-white/20 px-6 py-3 rounded-2xl text-sm font-bold transition-all inline-block border border-white/20">
                            Kelola Bahan Baku
                        </router-link>
                    </div>
                </div>
            </div>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import MainLayout from '../../../components/layout/MainLayout.vue';
import api from '../../../api/axios';
import { 
    DownloadIcon, 
    DollarSignIcon, 
    PackageIcon, 
    TrendingUpIcon, 
    PieChartIcon,
    BarChart3Icon,
    AlertCircleIcon,
    PackageSearchIcon
} from 'lucide-vue-next';
import {
    Chart as ChartJS,
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    Title,
    Tooltip,
    Legend,
    Filler,
} from "chart.js";
import { Line } from "vue-chartjs";

ChartJS.register(
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    Title,
    Tooltip,
    Legend,
    Filler,
);

const loading = ref(true);
const activeRange = ref('month');
const summary = ref({ total_revenue: 0, total_cogs: 0, gross_profit: 0, profit_margin: 0 });
const chartData = ref(null);
const productBreakdown = ref([]);

const formatCurrency = (value) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(value || 0);
};

const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
        mode: 'index',
        intersect: false,
    },
    plugins: {
        legend: { 
            position: 'top',
            labels: {
                usePointStyle: true,
                padding: 20,
                font: { family: 'Inter', weight: 'bold' }
            }
        },
        tooltip: {
            backgroundColor: 'rgba(255, 255, 255, 0.95)',
            titleColor: '#1e293b',
            titleFont: { weight: 'bold', size: 14 },
            bodyColor: '#64748b',
            bodyFont: { weight: 'medium' },
            borderColor: '#f1f5f9',
            borderWidth: 1,
            padding: 12,
            boxPadding: 8,
            usePointStyle: true,
            callbacks: {
                label: function(context) {
                    let label = context.dataset.label || '';
                    if (label) label += ': ';
                    if (context.parsed.y !== null) {
                        label += formatCurrency(context.parsed.y);
                    }
                    return label;
                }
            }
        }
    },
    scales: {
        y: { 
            grid: { color: "#f1f5f9", drawBorder: false }, 
            ticks: { 
                callback: (value) => value >= 1000000 ? (value/1000000) + 'jt' : (value >= 1000 ? (value/1000) + 'rb' : value),
                font: { weight: 'bold', color: '#94a3b8' }
            }
        },
        x: { 
            grid: { display: false },
            ticks: { font: { weight: 'bold', color: '#94a3b8' } }
        },
    },
};

const fetchReport = async () => {
    loading.value = true;
    try {
        const response = await api.get('/admin/reports/profit-loss', {
            params: { range: activeRange.value }
        });
        
        const data = response.data.data;
        summary.value = data.summary;
        productBreakdown.value = data.product_breakdown;

        // Process Trend Data
        const labels = data.trend.map(t => {
            const date = new Date(t.date);
            return date.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
        });

        chartData.value = {
            labels,
            datasets: [
                {
                    label: 'Pendapatan',
                    backgroundColor: 'rgba(0, 96, 65, 0.1)',
                    borderColor: '#006041',
                    pointBackgroundColor: "#fff",
                    pointBorderColor: "#006041",
                    pointBorderWidth: 2,
                    data: data.trend.map(t => t.revenue),
                    fill: true,
                    tension: 0.4
                },
                {
                    label: 'Modal (HPP)',
                    backgroundColor: 'transparent',
                    borderColor: '#f97316',
                    pointBackgroundColor: "#fff",
                    pointBorderColor: "#f97316",
                    pointBorderWidth: 2,
                    data: data.trend.map(t => t.cogs),
                    fill: false,
                    tension: 0.4,
                    borderDash: [5, 5]
                }
            ]
        };
    } catch (error) {
        console.error("Failed to fetch profit-loss report", error);
    } finally {
        loading.value = false;
    }
};

const exportReport = () => {
    alert('Fungsi export akan segera hadir.');
};

onMounted(() => {
    fetchReport();
});
</script>

<style scoped>
/* Optional specific styles */
</style>
