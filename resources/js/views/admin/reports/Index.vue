<template>
    <MainLayout>
        <div class="mb-6 flex justify-between items-center">
            <div>
                <h1 class="text-2xl font-bold text-slate-800">Laporan Penjualan</h1>
                <p class="text-gray-500">Analisa performa penjualan & laba rugi.</p>
            </div>
            
            <!-- Actions -->
            <div class="flex space-x-2">
                 <button class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-lg text-sm">
                    <DownloadIcon class="w-4 h-4 mr-2" />
                    Export
                </button>
                <div class="flex bg-white rounded-lg border border-gray-200 p-1">
                    <button 
                        v-for="range in ['today', 'week', 'month']" 
                        :key="range"
                        @click="activeRange = range; fetchReport()"
                        class="px-3 py-1.5 rounded-md text-sm font-medium capitalize transition-colors"
                        :class="activeRange === range ? 'bg-primary/10 text-primary' : 'text-gray-500 hover:bg-gray-50'"
                    >
                        {{ range === 'today' ? 'Hari Ini' : (range === 'week' ? 'Minggu Ini' : 'Bulan Ini') }}
                    </button>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Summary Type Cards -->
             <div class="lg:col-span-3 grid grid-cols-1 md:grid-cols-3 gap-6">
                 <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                     <div class="text-gray-500 text-sm mb-1">Total Pendapatan (Omset)</div>
                     <div class="text-2xl font-bold text-slate-800">{{ formatCurrency(summary.total_revenue) }}</div>
                 </div>
                 <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                     <div class="text-gray-500 text-sm mb-1">Laba Kotor (Gross Profit)</div>
                     <div class="text-2xl font-bold text-green-600">{{ formatCurrency(summary.gross_profit) }}</div>
                 </div>
                 <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                     <div class="text-gray-500 text-sm mb-1">Total Transaksi</div>
                     <div class="text-2xl font-bold text-blue-600">{{ summary.total_transactions }}</div>
                 </div>
             </div>

            <!-- Chart -->
            <div class="lg:col-span-2 bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                <h3 class="font-bold text-lg text-slate-800 mb-6">Tren Pendapatan</h3>
                <div class="h-80 relative">
                     <Line v-if="chartData" :data="chartData" :options="chartOptions" />
                </div>
            </div>

            <!-- Top Products -->
            <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                 <h3 class="font-bold text-lg text-slate-800 mb-6">Produk Terlaris</h3>
                 <div class="space-y-4">
                     <div v-for="(item, index) in topProducts" :key="index" class="flex items-center justify-between">
                         <div class="flex items-center">
                             <div class="h-8 w-8 rounded-full bg-gray-100 flex items-center justify-center text-xs font-bold text-gray-500 mr-3">
                                 {{ index + 1 }}
                             </div>
                             <div>
                                 <div class="text-sm font-medium text-slate-800">{{ item.product_name }}</div>
                                 <div class="text-xs text-gray-500">{{ item.quantity_sold }} terjual</div>
                             </div>
                         </div>
                         <div class="text-sm font-bold text-slate-800">
                             {{ formatCurrency(item.total_revenue) }}
                         </div>
                     </div>
                     <div v-if="topProducts.length === 0" class="text-center text-gray-400 py-4">Belum ada data</div>
                 </div>
            </div>

             <!-- Staff Performance -->
            <div class="lg:col-span-2 bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                <h3 class="font-bold text-lg text-slate-800 mb-6">Performa Kasir</h3>
                <div class="overflow-x-auto">
                    <table class="w-full text-left">
                        <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider">
                            <tr>
                                <th class="px-6 py-3 font-semibold">Nama Staff</th>
                                <th class="px-6 py-3 font-semibold text-center">Total Order</th>
                                <th class="px-6 py-3 font-semibold text-right">Penjualan</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100 text-sm">
                            <tr v-for="staff in staffPerformance" :key="staff.staff_name">
                                <td class="px-6 py-3 font-medium text-slate-800">{{ staff.staff_name }}</td>
                                <td class="px-6 py-3 text-center text-gray-600">{{ staff.total_orders }}</td>
                                <td class="px-6 py-3 text-right font-bold text-green-600">{{ formatCurrency(staff.total_sales) }}</td>
                            </tr>
                            <tr v-if="staffPerformance.length === 0">
                                <td colspan="3" class="px-6 py-3 text-center text-gray-400">Belum ada data</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Payment Methods -->
             <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                <h3 class="font-bold text-lg text-slate-800 mb-6">Metode Pembayaran</h3>
                <div class="space-y-4">
                    <div v-for="method in paymentMethods" :key="method.payment_method" class="flex items-center justify-between">
                        <span class="capitalize text-gray-700 font-medium">{{ method.payment_method }}</span>
                        <div class="text-right">
                             <div class="text-sm font-bold text-slate-800">{{ formatCurrency(method.total) }}</div>
                             <div class="text-xs text-gray-500">{{ method.count }} transaksi</div>
                        </div>
                    </div>
                     <div v-if="paymentMethods.length === 0" class="text-center text-gray-400 py-4">Belum ada data</div>
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
import { DownloadIcon } from "lucide-vue-next";

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

const activeRange = ref('week');
const summary = ref({ total_revenue: 0, gross_profit: 0, total_transactions: 0 });
const topProducts = ref([]);
const staffPerformance = ref([]);
const paymentMethods = ref([]);
const chartData = ref(null);

const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: { display: false },
    },
    scales: {
        y: { display: true, grid: { color: "#f3f4f6" }, beginAtZero: true },
        x: { grid: { display: false } },
    },
};

const fetchReport = async () => {
    try {
        const response = await api.get('/admin/reports/sales', {
            params: { range: activeRange.value }
        });
        
        const data = response.data?.data || response.data || {};
        summary.value = {
            total_revenue: data.total_revenue,
            gross_profit: data.gross_profit,
            total_transactions: data.total_transactions // Assuming API returns this
        };
        topProducts.value = data.top_products || [];
        staffPerformance.value = data.staff_performance || [];
        paymentMethods.value = data.payment_methods || [];

        // simplistic chart mapping from "sales_trend" if available, else mock
        // Assuming API sends 'sales_trend': { 'YYYY-MM-DD': amount, ... }
        const trend = data.sales_trend || {};
        const labels = Object.keys(trend);
        const values = Object.values(trend);

        chartData.value = {
            labels: labels.length ? labels : ['No Data'],
            datasets: [{
                label: 'Revenue',
                 backgroundColor: (ctx) => {
                    const canvas = ctx.chart.ctx;
                    const gradient = canvas.createLinearGradient(0, 0, 0, 400);
                    gradient.addColorStop(0, "rgba(0, 96, 65, 0.2)");
                    gradient.addColorStop(1, "rgba(0, 96, 65, 0)");
                    return gradient;
                },
                borderColor: "#006041",
                pointBackgroundColor: "#fff",
                pointBorderColor: "#006041",
                data: values.length ? values : [0],
                fill: true,
                tension: 0.4
            }]
        };

    } catch (error) {
        console.error("Failed to fetch reports", error);
    }
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(value);
};

onMounted(() => {
    fetchReport();
});
</script>
