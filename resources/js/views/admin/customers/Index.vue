<template>
    <MainLayout :loading="pageLoading">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-slate-800">Member Management</h1>
            <button @click="openModal()" class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-sm">
                <PlusIcon class="w-5 h-5 mr-2" />
                Add Member
            </button>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
             <!-- Filters -->
             <div class="p-6 border-b border-gray-100 flex flex-wrap gap-4 items-center bg-gray-50/50">
                 <div class="relative">
                    <span class="absolute inset-y-0 left-0 flex items-center pl-3">
                        <SearchIcon class="w-5 h-5 text-gray-400" />
                    </span>
                    <input 
                        v-model="search" 
                        @input="debouncedSearch"
                        type="text" 
                        placeholder="Search name, phone..." 
                        class="pl-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary w-full md:w-80 py-2.5 shadow-sm"
                    >
                 </div>
             </div>

            <table class="w-full text-left">
                <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                    <tr>
                        <th class="px-6 py-4 font-semibold">Member</th>
                        <th class="px-6 py-4 font-semibold">Phone</th>
                        <th class="px-6 py-4 font-semibold">Points</th>
                        <th class="px-6 py-4 font-semibold">Status</th>
                        <th class="px-6 py-4 font-semibold text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    <tr v-for="customer in (customers.data || []).filter(c => c != null)" :key="customer.id" class="hover:bg-gray-50 transition-colors group">
                        <td class="px-6 py-5">
                            <div class="flex items-center">
                                <div class="h-10 w-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold mr-4 border border-primary/20">
                                    {{ customer.name.charAt(0).toUpperCase() }}
                                </div>
                                <div>
                                    <router-link :to="`/admin/customers/${customer.id}`" class="font-bold text-slate-800 hover:text-primary hover:underline transition-colors block text-base">
                                        {{ customer.name }}
                                    </router-link>
                                    <div class="text-xs text-gray-500 mt-0.5">{{ customer.email || 'No email' }}</div>
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-5 text-gray-600 font-medium">{{ customer.phone }}</td>
                        <td class="px-6 py-5">
                            <span class="inline-flex items-center px-2.5 py-1 rounded-md bg-yellow-50 text-yellow-700 font-bold border border-yellow-200">
                                 {{ customer.points_balance }} pts
                            </span>
                        </td>
                        <td class="px-6 py-5">
                             <span :class="!customer.is_banned ? 'bg-green-100 text-green-700 ring-1 ring-green-600/20' : 'bg-red-100 text-red-700 ring-1 ring-red-600/20'" class="px-2.5 py-1 rounded-full text-xs font-bold inline-flex items-center">
                                <template v-if="!customer.is_banned">
                                    <span class="w-1.5 h-1.5 rounded-full bg-green-600 mr-1.5"></span> Active
                                </template>
                                <template v-else>
                                    <span class="w-1.5 h-1.5 rounded-full bg-red-600 mr-1.5"></span> Banned
                                </template>
                            </span>
                        </td>
                        <td class="px-6 py-5 text-right space-x-2">
                             <div class="flex items-center justify-end space-x-3">
                                <router-link :to="`/admin/customers/${customer.id}`" class="text-gray-400 hover:text-primary transition-colors p-1 rounded-lg hover:bg-primary/5" title="View Details">
                                    <EyeIcon class="w-5 h-5" />
                                </router-link>
                                <button @click="openModal(customer)" class="text-blue-400 hover:text-blue-600 transition-colors p-1 rounded-lg hover:bg-blue-50" title="Edit">
                                    <PencilIcon class="w-5 h-5" />
                                </button>
                                <button @click="deleteCustomer(customer.id)" class="text-red-400 hover:text-red-600 transition-colors p-1 rounded-lg hover:bg-red-50" title="Delete">
                                    <TrashIcon class="w-5 h-5" />
                                </button>
                             </div>
                        </td>
                    </tr>
                    <tr v-if="customers.data?.length === 0">
                        <td colspan="5" class="px-6 py-12 text-center text-gray-400 bg-gray-50/50">
                            <div class="flex flex-col items-center justify-center">
                                <p class="text-lg font-medium text-gray-500">No members found</p>
                                <p class="text-sm">Try searching for a different name</p>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
            
             <!-- Pagination -->
            <div class="p-6 border-t border-gray-100 flex justify-between items-center bg-gray-50/30">
                <span class="text-sm text-gray-500 font-medium">
                    Showing {{ customers.from || 0 }} to {{ customers.to || 0 }} of {{ customers.total || 0 }} results
                </span>
                <div class="space-x-2">
                    <button 
                        @click="changePage(customers.current_page - 1)" 
                        :disabled="!customers.prev_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all"
                    >Previous</button>
                    <button 
                        @click="changePage(customers.current_page + 1)" 
                        :disabled="!customers.next_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all"
                    >Next</button>
                </div>
            </div>
        </div>

        <!-- Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div class="absolute inset-0 bg-black/30 backdrop-blur-sm" @click="closeModal"></div>
            <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg relative z-10 p-6">
                <h2 class="text-xl font-bold mb-4">{{ isEditing ? 'Edit Member' : 'Add Member' }}</h2>
                <form @submit.prevent="saveCustomer" class="space-y-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                        <input v-model="form.name" type="text" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                        <input v-model="form.phone" type="text" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Email (Optional)</label>
                        <input v-model="form.email" type="email" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>
                    <div>
                         <label class="block text-sm font-medium text-gray-700 mb-1">Birth Date (Optional)</label>
                         <input v-model="form.birth_date" type="date" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>

                    <div class="flex justify-end space-x-3 mt-6">
                        <button type="button" @click="closeModal" class="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg">Cancel</button>
                        <button type="submit" class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-green-800 disabled:opacity-50" :disabled="loading">
                            {{ loading ? 'Saving...' : 'Save Member' }}
                        </button>
                    </div>
                </form>
            </div>
        </div>

    </MainLayout>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue';
import MainLayout from '../../../components/layout/MainLayout.vue';
import { PlusIcon, EyeIcon, SearchIcon, PencilIcon, TrashIcon } from 'lucide-vue-next';
import api from '../../../api/axios';
import { useToast } from "vue-toastification";

const toast = useToast();
const customers = ref({ data: [] });
const search = ref('');
const showModal = ref(false);
const isEditing = ref(false);
const loading = ref(false); // Form loading
const pageLoading = ref(true);
const editId = ref(null);

const form = reactive({
    name: '',
    phone: '',
    email: '',
    birth_date: ''
});

const fetchCustomers = async (page = 1) => {
    if (!customers.value.data) pageLoading.value = true;
    try {
        const response = await api.get('/admin/customers', {
            params: {
                page,
                search: search.value
            }
        });
        customers.value = response.data?.data || response.data || {};
    } catch (error) {
        console.error("Fetch customers failed", error);
    } finally {
        pageLoading.value = false;
    }
};

let debounceTimeout = null;
const debouncedSearch = () => {
    if (debounceTimeout) clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
        fetchCustomers(1);
    }, 300);
};

const changePage = (page) => {
    if (page >= 1 && page <= customers.value.last_page) {
        fetchCustomers(page);
    }
};

const openModal = (customer = null) => {
    if (customer) {
        isEditing.value = true;
        editId.value = customer.id;
        form.name = customer.name;
        form.phone = customer.phone;
        form.email = customer.email || '';
        form.birth_date = customer.birth_date ? customer.birth_date.substring(0, 10) : '';
    } else {
        isEditing.value = false;
        editId.value = null;
        form.name = '';
        form.phone = '';
        form.email = '';
        form.birth_date = '';
    }
    showModal.value = true;
};

const closeModal = () => {
    showModal.value = false;
};

const saveCustomer = async () => {
    loading.value = true;
    try {
        if (isEditing.value) {
            await api.put(`/admin/customers/${editId.value}`, form);
            toast.success("Member updated successfully!");
        } else {
            await api.post('/admin/customers', form);
            toast.success("Member created successfully!");
        }
        await fetchCustomers(customers.value.current_page);
        closeModal();
    } catch (error) {
        toast.error(error.response?.data?.message || 'Failed to save member');
    } finally {
        loading.value = false;
    }
};

const deleteCustomer = async (id) => {
    if(!confirm('Delete this member?')) return;
    try {
        await api.delete(`/admin/customers/${id}`);
        toast.success("Member deleted successfully!");
        fetchCustomers(customers.value.current_page);
    } catch(e) {
        toast.error("Failed to delete member");
    }
};

onMounted(() => {
    fetchCustomers();
});
</script>
