<template>
    <MainLayout :loading="loading">
        <div class="mb-8 flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
            <div>
                <h1 class="text-3xl font-bold text-slate-800 tracking-tight">
                    Dashboard Overview
                </h1>
                <p class="text-gray-500 mt-2">
                    Welcome back! Here's what's happening today.
                </p>
            </div>
            <button
                class="bg-primary hover:bg-green-800 text-white px-6 py-3 rounded-xl font-bold transition-all shadow-lg flex items-center w-full md:w-auto justify-center"
            >
                <PlusIcon class="w-5 h-5 mr-2" />
                New Order
            </button>
        </div>

        <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <StatsCard
                title="Total Revenue"
                :value="formatCurrency(stats.total_sales_today || 0)"
                :icon="DollarSignIcon"
                :trend="12.5"
                iconBgClass="bg-green-100"
                iconColorClass="text-primary"
                valueClass="text-2xl md:text-xl xl:text-3xl"
            />
            <StatsCard
                title="Transactions"
                :value="stats.transaction_count_today || '0'"
                :icon="ShoppingBagIcon"
                :trend="8.2"
                iconBgClass="bg-blue-100"
                iconColorClass="text-blue-600"
            />
            <StatsCard
                title="New Members"
                :value="stats.new_members_count || '0'"
                :icon="UsersIcon"
                :trend="-2.4"
                iconBgClass="bg-purple-100"
                iconColorClass="text-purple-600"
            />
            <StatsCard
                title="Low Stock Alert"
                :value="stats.low_stock_count || '0'"
                :icon="AlertTriangleIcon"
                :trend="0"
                iconBgClass="bg-red-100"
                iconColorClass="text-red-600"
            />
        </div>

        <!-- Charts Section -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
            <!-- Sales Trend Chart -->
            <div
                class="lg:col-span-2 bg-white p-6 rounded-2xl border border-gray-100 shadow-sm"
            >
                <div class="flex justify-between items-center mb-6">
                    <h3 class="font-bold text-lg text-slate-800">
                        Sales Analytics
                    </h3>
                    <select
                        class="bg-gray-50 border-none text-sm rounded-lg px-3 py-1 text-gray-500 focus:ring-0"
                    >
                        <option>This Week</option>
                        <option>This Month</option>
                    </select>
                </div>
                <div class="h-64 w-full">
                    <Line :data="chartData" :options="chartOptions" />
                </div>
            </div>

            <!-- Top Products -->
            <div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                <h3 class="font-bold text-lg text-slate-800 mb-6">
                    Popular Items
                </h3>
                <div class="space-y-4">
                    <div v-if="!stats.popular_items || stats.popular_items.length === 0" class="text-center text-gray-400 py-4">
                        No popular items yet.
                    </div>
                    <div v-else v-for="item in stats.popular_items" :key="item.id" class="flex items-center">
                        <img 
                            :src="item.image_url || '/no-image.jpg'" 
                            alt="Product Image"
                            class="h-12 w-12 rounded-xl bg-gray-100 mr-4 object-cover"
                            @error="$event.target.src = '/no-image.jpg'"
                        />
                        <div class="flex-1">
                            <div class="font-bold text-slate-700">
                                {{ item.name }}
                            </div>
                            <div class="text-xs text-gray-400">{{ item.category_name || 'Uncategorized' }}</div>
                        </div>
                        <div class="font-bold text-primary">{{ item.total_sold }} sold</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Detailed Table -->
        <div
            class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden"
        >
            <div
                class="p-6 border-b border-gray-100 flex justify-between items-center"
            >
                <h3 class="font-bold text-lg text-slate-800">
                    Recent Transactions
                </h3>
                <router-link to="/admin/orders" class="text-sm text-primary font-bold hover:underline">
                    View All
                </router-link>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-left">
                    <thead
                        class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider"
                    >
                        <tr>
                            <th class="px-6 py-4 font-semibold">Order ID</th>
                            <th class="px-6 py-4 font-semibold">Customer</th>
                            <th class="px-6 py-4 font-semibold">Amount</th>
                            <th class="px-6 py-4 font-semibold">Status</th>
                            <th class="px-6 py-4 font-semibold">Date</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 text-sm">
                        <tr v-if="!stats.recent_orders || stats.recent_orders.length === 0">
                             <td colspan="5" class="px-6 py-8 text-center text-gray-400">No recent transactions</td>
                        </tr>
                        <tr
                            v-for="order in stats.recent_orders"
                            :key="order.id"
                            class="hover:bg-gray-50 transition-colors"
                        >
                            <td class="px-6 py-4 font-medium text-slate-800 font-mono">
                                {{ order.order_number }}
                            </td>
                            <td class="px-6 py-4 text-gray-600">
                                {{ order.customer_name || order.customer?.name || 'Walk-in Customer' }}
                            </td>
                            <td class="px-6 py-4 font-bold text-slate-800">
                                {{ formatCurrency(order.grand_total) }}
                            </td>
                            <td class="px-6 py-4">
                                <span
                                    class="bg-green-100 text-green-700 px-3 py-1 rounded-full text-xs font-bold capitalize"
                                    >{{ order.payment_status }}</span
                                >
                            </td>
                            <td class="px-6 py-4 text-gray-400 text-xs">
                                {{ new Date(order.created_at).toLocaleTimeString() }}
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, onMounted } from "vue";
import MainLayout from "../../components/layout/MainLayout.vue";
import StatsCard from "../../components/dashboard/StatsCard.vue";
import {
    DollarSignIcon,
    ShoppingBagIcon,
    UsersIcon,
    AlertTriangleIcon,
    PlusIcon,
} from "lucide-vue-next";
import api from "../../api/axios";

// Chart.js imports
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

const stats = ref({});
const loading = ref(true);
const chartData = ref({
    labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
    datasets: [
        {
            label: "Revenue",
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
            pointBorderWidth: 2,
            data: [65, 59, 80, 81, 56, 120, 130], // Mock Data
            fill: true,
            tension: 0.4,
        },
    ],
});

const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: { display: false },
    },
    scales: {
        y: { display: true, grid: { color: "#f3f4f6" } },
        x: { grid: { display: false } },
    },
};

const fetchDashboardStats = async () => {
    loading.value = true;
    try {
        const response = await api.get("/admin/dashboard");
        const data = response.data?.data || response.data || {};
        stats.value = data;

        // Map Chart Data
        const trend = data.sales_trend || {};
        const labels = Object.keys(trend).map(date => {
            const d = new Date(date);
            return d.toLocaleDateString('en-US', { weekday: 'short' }); // Mon, Tue
        });
        const values = Object.values(trend);

        chartData.value = {
            labels: labels,
            datasets: [
                {
                    label: "Revenue",
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
                    pointBorderWidth: 2,
                    data: values, 
                    fill: true,
                    tension: 0.4,
                },
            ],
        };

    } catch (error) {
        console.error("Failed to load dashboard data", error);
    } finally {
        loading.value = false;
    }
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat("id-ID", {
        style: "currency",
        currency: "IDR",
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(value);
};

onMounted(() => {
    fetchDashboardStats();
});
</script>
