<template>
    <MainLayout :loading="pageLoading">
        <div
            class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6"
        >
            <h1 class="text-2xl font-bold text-slate-800">
                Transaction History
            </h1>
            <div class="flex space-x-2">
                <button
                    @click="exportToExcel"
                    class="flex items-center px-4 py-2 bg-green-600 text-white rounded-xl shadow-sm hover:bg-green-700 transition-colors font-bold text-sm"
                >
                    <DownloadIcon class="w-4 h-4 mr-2" />
                    Export Excel
                </button>
            </div>
        </div>

        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
            <div
                class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex items-center"
            >
                <div class="p-3 bg-blue-50 rounded-full mr-4">
                    <ClipboardListIcon class="w-6 h-6 text-blue-600" />
                </div>
                <div>
                    <div class="text-gray-500 text-sm font-medium">
                        Total Orders
                    </div>
                    <div class="text-2xl font-bold text-slate-800">
                        {{ stats.total_orders }}
                    </div>
                </div>
            </div>
            <div
                class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex items-center"
            >
                <div class="p-3 bg-green-50 rounded-full mr-4">
                    <span class="text-green-600 font-bold text-lg">Rp</span>
                </div>
                <div>
                    <div class="text-gray-500 text-sm font-medium">
                        Total Collected
                    </div>
                    <div class="text-2xl font-bold text-green-600">
                        {{ formatCurrency(stats.total_collected) }}
                    </div>
                    <div class="text-xs text-gray-400">Net Sales + Tax</div>
                </div>
            </div>
            <div
                class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex items-center"
            >
                <div class="p-3 bg-purple-50 rounded-full mr-4">
                    <span class="text-purple-600 font-bold text-lg">Rp</span>
                </div>
                <div>
                    <div class="text-gray-500 text-sm font-medium">
                        Total Net Sales
                    </div>
                    <div class="text-2xl font-bold text-purple-600">
                        {{ formatCurrency(stats.total_net_sales) }}
                    </div>
                    <div class="text-xs text-gray-400">Revenue before Tax</div>
                </div>
            </div>
        </div>

        <div
            class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden"
        >
            <!-- Filters -->
            <div
                class="p-6 border-b border-gray-100 flex flex-col md:flex-row gap-4 items-center bg-gray-50/50"
            >
                <div class="relative w-full md:w-auto">
                    <span
                        class="absolute inset-y-0 left-0 flex items-center pl-3"
                    >
                        <SearchIcon class="w-5 h-5 text-gray-400" />
                    </span>
                    <input
                        v-model="search"
                        @input="debouncedSearch"
                        type="text"
                        placeholder="Search Order # or Customer..."
                        class="pl-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary w-full md:w-80 py-2.5 shadow-sm"
                    />
                </div>
                <div class="flex items-center gap-2">
                    <button 
                        @click="navigateDate(-1)"
                        class="p-2.5 bg-white border border-gray-300 rounded-xl hover:bg-gray-50 text-gray-600 shadow-sm transition-all"
                        title="Previous Day"
                    >
                        <ChevronLeftIcon class="w-4 h-4" />
                    </button>

                    <div class="relative">
                        <span class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                            <CalendarIcon class="w-4 h-4 text-gray-400" />
                        </span>
                        <select
                            v-model="filterPeriod"
                            @change="onPeriodChange"
                            class="pl-9 pr-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary py-2.5 shadow-sm w-full md:w-auto appearance-none bg-white font-medium"
                        >
                            <option value="all">Semua Periode</option>
                            <option value="today">Hari Ini</option>
                            <option value="yesterday">Kemarin</option>
                            <option value="week">Minggu Ini</option>
                            <option value="month">Bulan Ini</option>
                            <option value="custom">Pilih Tanggal...</option>
                        </select>
                    </div>

                    <button 
                        @click="navigateDate(1)"
                        class="p-2.5 bg-white border border-gray-300 rounded-xl hover:bg-gray-50 text-gray-600 shadow-sm transition-all"
                        title="Next Day"
                    >
                        <ChevronRightIcon class="w-4 h-4" />
                    </button>
                </div>

                <div v-if="filterPeriod === 'custom'" class="flex items-center gap-2 animate-in fade-in slide-in-from-left-2 duration-300">
                    <input 
                        type="date"
                        v-model="startDate"
                        @change="fetchOrders(1)"
                        class="border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary py-2 shadow-sm"
                    />
                    <span class="text-gray-400">ke</span>
                    <input 
                        type="date"
                        v-model="endDate"
                        @change="fetchOrders(1)"
                        class="border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary py-2 shadow-sm"
                    />
                </div>

                <select
                    v-model="filterStatus"
                    @change="fetchOrders(1)"
                    class="border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary py-2.5 shadow-sm w-full md:w-auto font-medium"
                >
                    <option value="all">Semua Status</option>
                    <option value="paid">Paid</option>
                    <option value="pending">Pending</option>
                    <option value="failed">Failed</option>
                </select>
            </div>

            <div class="overflow-x-auto">
                <table class="w-full text-left whitespace-nowrap">
                    <thead
                        class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100"
                    >
                        <tr>
                            <th class="px-6 py-4 font-semibold">Order ID</th>
                            <th class="px-6 py-4 font-semibold">Customer</th>
                            <th class="px-6 py-4 font-semibold">Type</th>
                            <th class="px-6 py-4 font-semibold">Total</th>
                            <th class="px-6 py-4 font-semibold">Status</th>
                            <th class="px-6 py-4 font-semibold">Date</th>
                            <th class="px-6 py-4 font-semibold text-right">
                                Actions
                            </th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 text-sm">
                        <tr
                            v-for="order in (orders.data || []).filter(o => o != null)"
                            :key="order.id"
                            class="hover:bg-gray-50 transition-colors group"
                        >
                            <td
                                class="px-6 py-5 font-bold text-slate-800 text-base font-mono"
                            >
                                {{ order.order_number }}
                            </td>
                            <td class="px-6 py-5">
                                <div class="font-medium text-slate-800">
                                    {{
                                        order.customer_name ||
                                        order.customer?.name ||
                                        "Walk-in Customer"
                                    }}
                                </div>
                            </td>
                            <td class="px-6 py-5">
                                <span
                                    class="capitalize px-2 py-1 bg-gray-100 rounded text-xs font-semibold text-gray-600"
                                    >{{
                                        order.order_type.replace("_", " ")
                                    }}</span
                                >
                            </td>
                            <td class="px-6 py-5 font-bold text-slate-800">
                                {{ formatCurrency(order.grand_total) }}
                            </td>
                            <td class="px-6 py-5">
                                <span
                                    :class="{
                                        'bg-green-100 text-green-700 ring-green-600/20':
                                            order.payment_status === 'paid',
                                        'bg-yellow-100 text-yellow-700 ring-yellow-600/20':
                                            order.payment_status === 'pending',
                                        'bg-red-100 text-red-700 ring-red-600/20':
                                            order.payment_status === 'failed',
                                    }"
                                    class="px-2.5 py-1 rounded-full text-xs font-bold inline-flex items-center ring-1"
                                >
                                    <span
                                        class="w-1.5 h-1.5 rounded-full mr-1.5"
                                        :class="{
                                            'bg-green-600':
                                                order.payment_status === 'paid',
                                            'bg-yellow-600':
                                                order.payment_status ===
                                                'pending',
                                            'bg-red-600':
                                                order.payment_status ===
                                                'failed',
                                        }"
                                    ></span>
                                    {{
                                        order.payment_status
                                            .charAt(0)
                                            .toUpperCase() +
                                        order.payment_status.slice(1)
                                    }}
                                </span>
                            </td>
                            <td class="px-6 py-5 text-gray-500 text-xs">
                                {{ formatDate(order.created_at) }}
                            </td>
                            <td class="px-6 py-5 text-right space-x-2">
                                <button
                                    @click="viewOrder(order)"
                                    class="text-blue-600 hover:text-blue-800 font-medium text-sm hover:underline"
                                >
                                    View
                                </button>
                            </td>
                        </tr>
                        <tr v-if="orders.data?.length === 0">
                            <td
                                colspan="7"
                                class="px-6 py-12 text-center text-gray-400 bg-gray-50/50"
                            >
                                <div
                                    class="flex flex-col items-center justify-center"
                                >
                                    <p
                                        class="text-lg font-medium text-gray-500"
                                    >
                                        No orders found
                                    </p>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div
                class="p-6 border-t border-gray-100 flex flex-col md:flex-row justify-between items-center bg-gray-50/30"
            >
                <div class="space-x-2 ml-auto">
                    <button
                        @click="changePage(orders.current_page - 1)"
                        :disabled="!orders.prev_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all"
                    >
                        Previous
                    </button>
                    <button
                        @click="changePage(orders.current_page + 1)"
                        :disabled="!orders.next_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all"
                    >
                        Next
                    </button>
                </div>
            </div>
        </div>

        <!-- Order Detail Modal -->
        <div
            v-if="selectedOrder"
            class="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
            <div
                class="absolute inset-0 bg-black/30 backdrop-blur-sm"
                @click="closeModal"
            ></div>
            <div
                class="bg-white rounded-2xl shadow-xl w-full max-w-2xl relative z-10 overflow-hidden flex flex-col max-h-[90vh]"
            >
                <div
                    class="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50"
                >
                    <div>
                        <h2 class="text-xl font-bold text-slate-800">
                            Order {{ selectedOrder.order_number }}
                        </h2>
                        <p class="text-sm text-gray-500">
                            {{ formatDate(selectedOrder.created_at) }}
                        </p>
                    </div>
                    <button
                        @click="closeModal"
                        class="text-gray-400 hover:text-gray-600"
                    >
                        <XIcon class="w-6 h-6" />
                    </button>
                </div>

                <div class="p-6 overflow-y-auto flex-1">
                    <!-- Customer Info -->
                    <div
                        class="bg-blue-50 p-4 rounded-xl mb-6 flex justify-between items-start"
                    >
                        <div>
                            <div
                                class="text-xs text-blue-600 font-bold uppercase tracking-wide mb-1"
                            >
                                Customer
                            </div>
                            <div class="font-bold text-slate-800">
                                {{
                                    selectedOrder.customer_name ||
                                    selectedOrder.customer?.name ||
                                    "Walk-in Customer"
                                }}
                            </div>
                            <div class="text-sm text-gray-600">
                                {{ selectedOrder.customer?.phone || "-" }}
                            </div>
                        </div>
                        <div class="text-right">
                            <div
                                class="text-xs text-blue-600 font-bold uppercase tracking-wide mb-1"
                            >
                                Payment
                            </div>
                            <div class="font-bold text-slate-800 capitalize">
                                {{ selectedOrder.payment_method }}
                            </div>
                            <div class="text-sm text-gray-600 capitalize mb-2">
                                {{ selectedOrder.order_type.replace("_", " ") }}
                            </div>

                            <div
                                class="text-xs text-gray-400 uppercase font-bold tracking-wide"
                            >
                                Collected by
                            </div>
                            <div class="font-medium text-slate-800">
                                {{ selectedOrder.user?.name || "Unknown" }}
                            </div>
                        </div>
                    </div>

                    <!-- Items -->
                    <h3 class="font-bold text-slate-800 mb-3">Order Items</h3>
                    <div
                        class="border border-gray-200 rounded-xl overflow-hidden mb-6"
                    >
                        <table class="w-full text-sm text-left">
                            <thead
                                class="bg-gray-50 text-gray-500 font-semibold border-b border-gray-100"
                            >
                                <tr>
                                    <th class="px-4 py-3">Item</th>
                                    <th class="px-4 py-3 text-center">Qty</th>
                                    <th class="px-4 py-3 text-right">Price</th>
                                    <th class="px-4 py-3 text-right">Total</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-100">
                                <tr
                                    v-for="item in selectedOrder.items"
                                    :key="item.id"
                                >
                                    <td
                                        class="px-4 py-3 font-medium text-slate-800"
                                    >
                                        {{ getProductName(item) }}
                                        <div
                                            v-if="
                                                getVisibleModifiers(item).length
                                            "
                                            class="flex flex-wrap gap-1 mt-1"
                                        >
                                            <span
                                                v-for="(
                                                    mod, idx
                                                ) in getVisibleModifiers(item)"
                                                :key="idx"
                                                class="text-xs text-gray-500 bg-gray-50 px-1.5 py-0.5 rounded"
                                            >
                                                {{
                                                    getModifierDisplayName(mod)
                                                }}
                                            </span>
                                        </div>
                                        <div
                                            v-if="item.note"
                                            class="text-xs text-gray-500 italic mt-0.5"
                                        >
                                            Note: {{ item.note }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-4 py-3 text-center text-gray-600"
                                    >
                                        x{{ item.quantity }}
                                    </td>
                                    <td
                                        class="px-4 py-3 text-right text-gray-600"
                                    >
                                        {{ formatCurrency(item.unit_price) }}
                                    </td>
                                    <td
                                        class="px-4 py-3 text-right font-bold text-slate-800"
                                    >
                                        {{ formatCurrency(item.total_price) }}
                                    </td>
                                </tr>
                            </tbody>
                            <tfoot class="bg-gray-50 font-bold text-slate-800">
                                <tr>
                                    <td
                                        colspan="3"
                                        class="px-4 py-3 text-right"
                                    >
                                        Subtotal
                                    </td>
                                    <td class="px-4 py-3 text-right">
                                        {{
                                            formatCurrency(
                                                selectedOrder.subtotal,
                                            )
                                        }}
                                    </td>
                                </tr>
                                <tr v-if="selectedOrder.tax_amount > 0">
                                    <td
                                        colspan="3"
                                        class="px-4 py-3 text-right text-sm font-normal text-gray-600"
                                    >
                                        Tax
                                    </td>
                                    <td
                                        class="px-4 py-3 text-right text-sm font-normal text-gray-600"
                                    >
                                        {{
                                            formatCurrency(
                                                selectedOrder.tax_amount,
                                            )
                                        }}
                                    </td>
                                </tr>
                                <tr class="text-lg bg-primary/5 text-primary">
                                    <td
                                        colspan="3"
                                        class="px-4 py-3 text-right"
                                    >
                                        Grand Total
                                    </td>
                                    <td class="px-4 py-3 text-right">
                                        {{
                                            formatCurrency(
                                                selectedOrder.grand_total,
                                            )
                                        }}
                                    </td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>

                <div
                    class="p-4 border-t border-gray-100 bg-gray-50 flex justify-end"
                >
                    <button
                        @click="closeModal"
                        class="px-6 py-2 bg-white border border-gray-300 rounded-lg font-bold text-gray-600 hover:bg-gray-50"
                    >
                        Close
                    </button>
                    <!-- <button class="ml-3 px-6 py-2 bg-primary text-white rounded-lg font-bold hover:bg-green-800">Print Receipt</button> -->
                </div>
            </div>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, onMounted } from "vue";
import MainLayout from "../../../components/layout/MainLayout.vue";
import { SearchIcon, XIcon, ClipboardListIcon, DownloadIcon, ChevronLeftIcon, ChevronRightIcon, CalendarIcon, TagIcon } from "lucide-vue-next";
import api from "../../../api/axios";
import { useToast } from "vue-toastification";
import { useProductDisplay } from "../../../composables/useProductDisplay";

const { getProductName, getVisibleModifiers, getModifierDisplayName } =
    useProductDisplay();
import { format as dateFormat } from "date-fns";

const toast = useToast();
const orders = ref({ data: [] });
const stats = ref({ total_orders: 0, total_collected: 0, total_net_sales: 0 });
const search = ref("");
const filterStatus = ref("all");
const filterPeriod = ref("today"); // Default to today as requested
const startDate = ref(dateFormat(new Date(), "yyyy-MM-dd"));
const endDate = ref(dateFormat(new Date(), "yyyy-MM-dd"));
const pageLoading = ref(true);
const selectedOrder = ref(null);

const fetchOrders = async (page = 1) => {
    if (!orders.value.data) pageLoading.value = true;

    try {
        const response = await api.get("/admin/orders", {
            params: {
                page,
                search: search.value,
                status: filterStatus.value,
                period: filterPeriod.value,
                start_date: filterPeriod.value === 'custom' || filterPeriod.value === 'today' || filterPeriod.value === 'yesterday' ? startDate.value : null,
                end_date: filterPeriod.value === 'custom' || filterPeriod.value === 'today' || filterPeriod.value === 'yesterday' ? endDate.value : null,
            },
        });
        const data = response.data?.data || response.data || {};
        orders.value = data.orders || {};
        if (data.stats) {
            stats.value = data.stats;
        }
    } catch (error) {
        console.error("Fetch orders failed", error);
        toast.error("Failed to load orders");
    } finally {
        pageLoading.value = false;
    }
};

const onPeriodChange = () => {
    if (filterPeriod.value === 'today') {
        const today = dateFormat(new Date(), "yyyy-MM-dd");
        startDate.value = today;
        endDate.value = today;
    } else if (filterPeriod.value === 'yesterday') {
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const yStr = dateFormat(yesterday, "yyyy-MM-dd");
        startDate.value = yStr;
        endDate.value = yStr;
    }
    fetchOrders(1);
};

const navigateDate = (offset) => {
    // If not in a single day view, switch to custom or today
    if (filterPeriod.value !== 'today' && filterPeriod.value !== 'yesterday' && filterPeriod.value !== 'custom') {
        filterPeriod.value = 'custom';
    }

    const current = new Date(startDate.value);
    current.setDate(current.getDate() + offset);
    const dateStr = dateFormat(current, "yyyy-MM-dd");
    
    startDate.value = dateStr;
    endDate.value = dateStr;
    
    // Update period label if it matches today or yesterday
    const today = dateFormat(new Date(), "yyyy-MM-dd");
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = dateFormat(yesterday, "yyyy-MM-dd");

    if (dateStr === today) {
        filterPeriod.value = 'today';
    } else if (dateStr === yesterdayStr) {
        filterPeriod.value = 'yesterday';
    } else {
        filterPeriod.value = 'custom';
    }

    fetchOrders(1);
};

const exportToExcel = async () => {
    try {
        toast.info("Preparing export...");
        const response = await api.get("/admin/orders/export", {
            params: {
                search: search.value,
                status: filterStatus.value,
                period: filterPeriod.value,
                start_date: startDate.value,
                end_date: endDate.value,
            },
            responseType: 'blob'
        });

        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `orders_report_${startDate.value}_to_${endDate.value}.csv`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        toast.success("Export successful");
    } catch (e) {
        console.error("Export failed", e);
        toast.error("Failed to export data");
    }
};

let debounceTimeout = null;
const debouncedSearch = () => {
    if (debounceTimeout) clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
        fetchOrders(1);
    }, 300);
};

const changePage = (page) => {
    if (page >= 1 && page <= orders.value.last_page) {
        fetchOrders(page);
    }
};

const viewOrder = async (order) => {
    try {
        const response = await api.get(`/admin/orders/${order.id}`);
        selectedOrder.value = response.data?.data || response.data || {};
    } catch (e) {
        toast.error("Failed to load details");
    }
};

const closeModal = () => {
    selectedOrder.value = null;
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat("id-ID", {
        style: "currency",
        currency: "IDR",
    }).format(value);
};

const formatDate = (dateString) => {
    return dateFormat(new Date(dateString), "dd MMM yyyy, HH:mm");
};

onMounted(() => {
    fetchOrders();
});
</script>
