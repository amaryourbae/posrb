<template>
    <MainLayout>
        <div class="mb-6">
            <router-link to="/admin/customers" class="text-gray-500 hover:text-gray-700 flex items-center mb-4 transition-colors">
                <ArrowLeftIcon class="w-4 h-4 mr-2" />
                Back to Members
            </router-link>
            <h1 class="text-2xl font-bold text-slate-800">Member Details</h1>
        </div>

        <div v-if="loading" class="text-center py-12">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
        </div>

        <div v-else-if="customer" class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <!-- Left: Profile Info -->
            <div class="lg:col-span-2 space-y-6">
                <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                    <h2 class="text-lg font-bold text-slate-800 mb-4 border-b border-gray-100 pb-2">Profile Information</h2>
                    <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-4 gap-y-6">
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Full Name</dt>
                            <dd class="mt-1 text-base font-bold text-slate-800">{{ customer.name }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Phone Number</dt>
                            <dd class="mt-1 text-base font-medium text-slate-800">{{ customer.phone }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Email Address</dt>
                            <dd class="mt-1 text-base font-medium text-slate-800">{{ customer.email || '-' }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Birth Date</dt>
                            <dd class="mt-1 text-base font-medium text-slate-800">{{ customer.birth_date ? customer.birth_date.substring(0, 10) : '-' }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Join Date</dt>
                            <dd class="mt-1 text-base font-medium text-slate-800">{{ formatDate(customer.created_at) }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Status</dt>
                            <dd class="mt-1">
                                <span :class="!customer.is_banned ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'" class="px-2 py-1 rounded-full text-xs font-bold">
                                    {{ !customer.is_banned ? 'Active' : 'Banned' }}
                                </span>
                            </dd>
                        </div>
                    </dl>
                </div>

                <!-- Transaction History -->
                 <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                    <h2 class="text-lg font-bold text-slate-800 mb-4">Recent Transactions</h2>
                    
                    <div v-if="customer.orders && customer.orders.length > 0" class="overflow-x-auto">
                        <table class="w-full text-left text-sm">
                            <thead class="bg-gray-50 text-gray-500">
                                <tr>
                                    <th class="px-4 py-2 rounded-l-lg">Order ID</th>
                                    <th class="px-4 py-2">Date</th>
                                    <th class="px-4 py-2">Total</th>
                                    <th class="px-4 py-2 rounded-r-lg">Status</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-100">
                                <tr v-for="order in customer.orders" :key="order.id" class="hover:bg-gray-50 transition-colors">
                                    <td class="px-4 py-3 font-bold text-primary">#{{ order.order_number }}</td>
                                    <td class="px-4 py-3 text-gray-600">{{ formatDate(order.created_at, 'short') }}</td>
                                    <td class="px-4 py-3 font-semibold text-gray-800">{{ formatCurrency(order.grand_total) }}</td>
                                    <td class="px-4 py-3">
                                        <span class="px-2 py-1 rounded text-[10px] font-bold uppercase tracking-wider"
                                            :class="{
                                                'bg-green-100 text-green-700': order.payment_status === 'paid',
                                                'bg-yellow-100 text-yellow-700': order.payment_status === 'pending',
                                                'bg-red-100 text-red-700': order.payment_status === 'failed'
                                            }"
                                        >
                                            {{ order.payment_status }}
                                        </span>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <div v-else class="text-center py-8 bg-gray-50 rounded-lg">
                        <p class="text-gray-500 text-sm">No recent transactions found.</p>
                    </div>
                </div>
            </div>

            <!-- Right: Digital Card -->
            <div class="lg:col-span-1">
                <h2 class="text-lg font-bold text-slate-800 mb-4">Digital Member Card</h2>
                
                <!-- The Card -->
                <div class="relative w-full aspect-[1.586] rounded-2xl overflow-hidden shadow-2xl transform transition-transform hover:scale-105 duration-300">
                    <!-- Background -->
                    <div class="absolute inset-0 bg-linear-to-br from-green-900 via-green-800 to-slate-900"></div>
                    
                    <!-- Texture/Pattern Overlay -->
                    <div class="absolute inset-0 opacity-10" style="background-image: radial-gradient(#ffffff 1px, transparent 1px); background-size: 20px 20px;"></div>

                    <!-- Glowing Orbs -->
                    <div class="absolute top-[-50%] left-[-20%] w-[80%] h-[80%] bg-green-500 rounded-full blur-[80px] opacity-20"></div>
                    <div class="absolute bottom-[-20%] right-[-20%] w-[60%] h-[60%] bg-yellow-500 rounded-full blur-[60px] opacity-10"></div>

                    <!-- Content -->
                    <div class="absolute inset-0 p-6 flex flex-col justify-between text-white z-10">
                        <!-- Header -->
                        <div class="flex justify-between items-start">
                            <div class="flex items-center">
                                <CoffeeIcon class="w-6 h-6 mr-2 text-yellow-500" />
                                <div>
                                    <h3 class="font-bold text-sm tracking-widest text-white uppercase">RuangBincang</h3>
                                    <p class="text-[8px] tracking-[0.3em] text-green-200 uppercase">Premium Member</p>
                                </div>
                            </div>
                        </div>

                        <!-- Middle: Chip & Contactless -->
                        <div class="flex items-center space-x-4">
                             <div class="w-10 h-8 bg-linear-to-tr from-yellow-200 to-yellow-600 rounded-md shadow-sm flex flex-col justify-center px-1 overflow-hidden relative">
                                 <!-- Chip lines -->
                                 <div class="absolute inset-0 border border-yellow-700/30 rounded-md"></div>
                             </div>
                             <WifiIcon class="w-6 h-6 text-white/50 rotate-90" />
                        </div>

                        <!-- Footer Info -->
                        <div class="flex justify-between items-end">
                            <div>
                                <p class="text-[10px] text-green-200/70 mb-0.5 uppercase tracking-wider">Member Name</p>
                                <p class="font-mono text-base font-bold tracking-wide text-white shadow-black drop-shadow-md truncate w-40">{{ customer.name.toUpperCase() }}</p>
                                <p class="mt-1 text-[10px] font-mono text-green-300 tracking-wider">{{ customer.phone }}</p>
                            </div>
                            <div class="text-right">
                                <p class="text-[10px] text-green-200/70 mb-0.5 uppercase tracking-wider">Balance</p>
                                <p class="font-bold text-xl text-yellow-400 drop-shadow-md">{{ customer.points_balance }} <span class="text-xs text-yellow-200">PTS</span></p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- QR Code Section -->
                 <div class="mt-6 bg-white p-6 rounded-xl border border-gray-100 shadow-sm text-center">
                    <p class="text-sm text-gray-500 mb-4 font-medium">Scan to earn or redeem points</p>
                    <div class="inline-block p-2 bg-white border border-gray-200 rounded-xl shadow-inner mb-2">
                        <qrcode-vue :value="customer.id" :size="150" level="H" />
                    </div>
                    <p class="text-xs font-mono text-gray-400 mt-2 break-all">{{ customer.id.toUpperCase() }}</p>
                 </div>

            </div>
        </div>

        <div v-else class="text-center py-12 text-gray-500">
            Member not found.
        </div>

    </MainLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import MainLayout from '../../../components/layout/MainLayout.vue';
import { ArrowLeftIcon, WifiIcon, CoffeeIcon } from 'lucide-vue-next';
import api from '../../../api/axios';
import QrcodeVue from 'qrcode.vue';
import { formatCurrency } from '../../../utils/format';

const route = useRoute();
const customer = ref(null);
const loading = ref(true);

const fetchCustomer = async () => {
    loading.value = true;
    try {
        const response = await api.get(`/admin/customers/${route.params.id}`);
        customer.value = response.data?.data || response.data || null;
    } catch (error) {
        console.error("Failed to fetch customer", error);
    } finally {
        loading.value = false;
    }
};

const formatDate = (dateString, format = 'long') => {
    if (!dateString) return '-';
    // Handle 'YYYY-MM-DD' vs ISO string
    const date = new Date(dateString);
    if(isNaN(date.getTime())) return dateString; // Return original if parse fails

    if (format === 'short') {
        return date.toLocaleDateString('id-ID', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        });
    }

    return date.toLocaleDateString('id-ID', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
};

onMounted(() => {
    fetchCustomer();
});
</script>
