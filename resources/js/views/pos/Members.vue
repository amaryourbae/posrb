<template>
    <PosLayout>
        <div class="flex flex-col h-full bg-gray-50">
            <!-- Header -->
            <div class="px-6 py-4 bg-white border-b border-gray-100 flex justify-between items-center shrink-0">
                <h2 class="text-2xl font-bold text-gray-900">Members</h2>
                <button 
                    @click="openModal()" 
                    class="bg-primary hover:bg-[#004d34] text-white px-6 py-2.5 rounded-xl font-bold text-sm shadow-lg shadow-primary/30 flex items-center gap-2 transition"
                >
                    <PlusIcon class="w-5 h-5" />
                    New Member
                </button>
            </div>

            <!-- Search & Filter -->
            <div class="px-6 py-4 bg-white border-b border-gray-50 shrink-0">
                <div class="relative max-w-lg">
                    <SearchIcon class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                    <input 
                        v-model="search" 
                        @input="debouncedSearch"
                        type="text" 
                        class="w-full pl-12 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none shadow-sm text-sm transition-colors" 
                        placeholder="Search member by Name or Phone..." 
                    />
                </div>
            </div>

            <!-- Content -->
            <div class="flex-1 overflow-y-auto px-6 py-4 pb-24 lg:pb-6">
                <!-- Loading State -->
                <div v-if="loading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                    <div v-for="i in 8" :key="i" class="bg-white p-4 rounded-2xl shadow-sm border border-transparent animate-pulse h-32">
                        <div class="flex items-center gap-4 mb-3">
                            <div class="w-12 h-12 rounded-full bg-gray-200 shrink-0"></div>
                            <div class="space-y-2 w-full">
                                <div class="h-4 bg-gray-200 rounded w-3/4"></div>
                                <div class="h-3 bg-gray-200 rounded w-1/2"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Empty State -->
                <div v-else-if="customers.data?.length === 0" class="flex flex-col items-center justify-center h-64 text-gray-400">
                    <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                        <UsersIcon class="w-8 h-8 text-gray-300" />
                    </div>
                    <p class="font-medium">No members found</p>
                    <p class="text-sm">Try searching for a different name</p>
                </div>

                <!-- Member Grid -->
                <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                    <div 
                        v-for="customer in customers.data" 
                        :key="customer.id" 
                        class="bg-white p-5 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md hover:border-primary/30 transition group relative"
                    >
                        <!-- Actions (Hover) -->
                        <div class="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button @click="openModal(customer)" class="p-2 bg-gray-50 hover:bg-blue-50 text-gray-500 hover:text-blue-600 rounded-lg transition">
                                <PencilIcon class="w-4 h-4" />
                            </button>
                            <button @click="deleteCustomer(customer.id)" class="p-2 bg-gray-50 hover:bg-red-50 text-gray-500 hover:text-red-600 rounded-lg transition">
                                <TrashIcon class="w-4 h-4" />
                            </button>
                        </div>

                        <div class="flex items-center gap-4 mb-4">
                            <div class="w-14 h-14 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-xl border border-primary/20 shrink-0">
                                {{ customer.name.charAt(0).toUpperCase() }}
                            </div>
                            <div class="min-w-0">
                                <h3 class="font-bold text-gray-900 truncate text-lg">{{ customer.name }}</h3>
                                <p class="text-sm text-gray-500 truncate">{{ customer.phone }}</p>
                            </div>
                        </div>
                        
                        <div class="flex items-center justify-between pt-4 border-t border-gray-50">
                            <div>
                                <p class="text-xs text-gray-400 uppercase font-bold tracking-wider">Points</p>
                                <p class="font-bold text-gray-900 text-lg">{{ customer.points_balance }} <span class="text-xs font-normal text-gray-400">pts</span></p>
                            </div>
                            <div>
                                <span 
                                    class="px-2.5 py-1 rounded-full text-xs font-bold flex items-center gap-1.5"
                                    :class="!customer.is_banned ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'"
                                >
                                    <span class="w-1.5 h-1.5 rounded-full" :class="!customer.is_banned ? 'bg-green-500' : 'bg-red-500'"></span>
                                    {{ !customer.is_banned ? 'Active' : 'Banned' }}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Pagination -->
                <div class="mt-8 flex justify-between items-center" v-if="customers.total > 0">
                    <span class="text-sm text-gray-500 font-medium">
                        Showing {{ customers.from }} - {{ customers.to }} of {{ customers.total }} members
                    </span>
                    <div class="flex gap-2">
                        <button 
                            @click="changePage(customers.current_page - 1)" 
                            :disabled="!customers.prev_page_url"
                            class="px-4 py-2 bg-white border border-gray-200 rounded-xl text-sm font-bold text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition"
                        >
                            Previous
                        </button>
                        <button 
                            @click="changePage(customers.current_page + 1)" 
                            :disabled="!customers.next_page_url"
                            class="px-4 py-2 bg-white border border-gray-200 rounded-xl text-sm font-bold text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition"
                        >
                            Next
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Add/Edit Modal (Reusable) -->
        <MemberFormModal 
            :is-open="showModal" 
            :customer="editCustomer" 
            @close="closeModal" 
            @saved="handleSaved" 
        />
    </PosLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import PosLayout from '../../components/layout/PosLayout.vue';
import MemberFormModal from '../../components/pos/MemberFormModal.vue';
import { PlusIcon, SearchIcon, UsersIcon, PencilIcon, TrashIcon } from 'lucide-vue-next';
import api from '../../api/axios';
import { useToast } from 'vue-toastification';

const toast = useToast();
const customers = ref({});
const search = ref('');
const loading = ref(false);
const showModal = ref(false);
const editCustomer = ref(null);

// Fetch Members
const fetchCustomers = async (page = 1) => {
    loading.value = true;
    try {
        const response = await api.get('/admin/customers', {
            params: {
                page,
                search: search.value
            }
        });
        customers.value = response.data?.data || response.data || { data: [] };
    } catch (e) {
        toast.error('Failed to load members');
    } finally {
        loading.value = false;
    }
};

let debounceTimeout;
const debouncedSearch = () => {
    if (debounceTimeout) clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
        fetchCustomers(1);
    }, 400);
};

const changePage = (page) => {
    if (page >= 1 && page <= customers.value.last_page) {
        fetchCustomers(page);
    }
};

const openModal = (customer = null) => {
    editCustomer.value = customer;
    showModal.value = true;
};

const closeModal = () => {
    showModal.value = false;
    editCustomer.value = null;
};

const handleSaved = () => {
    fetchCustomers(customers.value.current_page);
};

const deleteCustomer = async (id) => {
    if (!confirm('Are you sure you want to delete this member?')) return;
    try {
        await api.delete(`/admin/customers/${id}`);
        toast.success('Member deleted');
        fetchCustomers(customers.value.current_page);
    } catch (e) {
        toast.error('Failed to delete member');
    }
};

onMounted(() => {
    fetchCustomers();
});
</script>
