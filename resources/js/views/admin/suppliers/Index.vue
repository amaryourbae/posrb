<template>
    <MainLayout :loading="pageLoading">
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
            <h1 class="text-2xl font-bold text-slate-800">Supplier Management</h1>
            <button @click="openModal()" class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-lg shadow-green-200 w-full md:w-auto justify-center">
                <PlusIcon class="w-5 h-5 mr-2" />
                Add Supplier
            </button>
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
                        placeholder="Search supplier..." 
                        class="pl-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary w-full py-2 shadow-sm"
                    >
                 </div>
             </div>

            <div class="overflow-x-auto">
                <table class="w-full text-left whitespace-nowrap">
                    <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                        <tr>
                            <th class="px-6 py-4 font-semibold">Name</th>
                            <th class="px-6 py-4 font-semibold">Contact Person</th>
                            <th class="px-6 py-4 font-semibold">Phone/Email</th>
                            <th class="px-6 py-4 font-semibold">Address</th>
                            <th class="px-6 py-4 font-semibold text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 text-sm">
                        <tr v-for="supplier in (suppliers.data || []).filter(s => s != null)" :key="supplier.id" class="hover:bg-gray-50 transition-colors">
                            <td class="px-6 py-4 font-bold text-slate-800">{{ supplier.name }}</td>
                            <td class="px-6 py-4 text-gray-600">{{ supplier.contact_person || '-' }}</td>
                            <td class="px-6 py-4 text-gray-600">
                                <div v-if="supplier.phone">{{ supplier.phone }}</div>
                                <div v-if="supplier.email" class="text-xs text-blue-500">{{ supplier.email }}</div>
                            </td>
                            <td class="px-6 py-4 text-gray-500 truncate max-w-xs">{{ supplier.address || '-' }}</td>
                            <td class="px-6 py-4 text-right space-x-2">
                                <button @click="openModal(supplier)" class="text-blue-600 hover:text-blue-800 font-medium text-sm hover:underline">Edit</button>
                                <button @click="deleteSupplier(supplier)" class="text-red-500 hover:text-red-700 font-medium text-sm hover:underline">Delete</button>
                            </td>
                        </tr>
                        <tr v-if="suppliers.data?.length === 0">
                            <td colspan="5" class="px-6 py-12 text-center text-gray-400">No suppliers found</td>
                        </tr>
                    </tbody>
                </table>
            </div>
             <!-- Pagination -->
            <div class="p-6 border-t border-gray-100 flex flex-col md:flex-row justify-between items-center gap-4 bg-gray-50/30">
                <span class="text-sm text-gray-500 font-medium" v-if="suppliers.total">
                     Showing {{ suppliers.from }} to {{ suppliers.to }} of {{ suppliers.total }} results
                </span>
                <span v-else></span>
                <div class="space-x-2">
                    <button 
                        @click="changePage(suppliers.current_page - 1)" 
                        :disabled="!suppliers.prev_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all"
                    >Previous</button>
                    <button 
                        @click="changePage(suppliers.current_page + 1)" 
                        :disabled="!suppliers.next_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all"
                    >Next</button>
                </div>
            </div>
        </div>

        <!-- Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div class="absolute inset-0 bg-black/30 backdrop-blur-sm" @click="closeModal"></div>
            <div class="bg-white rounded-2xl shadow-xl w-full max-w-md relative z-10 overflow-hidden">
                <div class="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50">
                    <h2 class="text-xl font-bold text-slate-800">{{ isEditing ? 'Edit Supplier' : 'Add Supplier' }}</h2>
                    <button @click="closeModal" class="text-gray-400 hover:text-gray-600"><XIcon class="w-6 h-6" /></button>
                </div>
                
                <form @submit.prevent="submitForm" class="p-6 space-y-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Supplier Name</label>
                        <input v-model="form.name" type="text" required class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Contact Person</label>
                        <input v-model="form.contact_person" type="text" class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3">
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                         <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                            <input v-model="form.phone" type="text" class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3">
                        </div>
                        <div>
                             <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                            <input v-model="form.email" type="email" class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3">
                        </div>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Address</label>
                        <textarea v-model="form.address" rows="3" class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3"></textarea>
                    </div>

                    <div class="pt-4 flex justify-end space-x-3">
                        <button type="button" @click="closeModal" class="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 font-medium">Cancel</button>
                        <button type="submit" :disabled="formLoading" class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-green-800 font-bold disabled:opacity-50">
                            {{ formLoading ? 'Saving...' : 'Save Supplier' }}
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
import { SearchIcon, PlusIcon, XIcon } from 'lucide-vue-next';
import api from '../../../api/axios';
import { useToast } from "vue-toastification";

const toast = useToast();
const suppliers = ref({ data: [] });
const search = ref('');
const pageLoading = ref(true);
const showModal = ref(false);
const isEditing = ref(false);
const formLoading = ref(false);

const form = reactive({
    id: null,
    name: '',
    contact_person: '',
    phone: '',
    email: '',
    address: '',
    note: ''
});

const fetchSuppliers = async (page = 1) => {
    try {
        const response = await api.get('/admin/suppliers', {
            params: { page, search: search.value }
        });
        suppliers.value = response.data?.data || response.data || {};
    } catch (error) {
        console.error("Fetch suppliers failed", error);
    } finally {
        pageLoading.value = false;
    }
};

let debounceTimeout = null;
const debouncedSearch = () => {
    if (debounceTimeout) clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
        fetchSuppliers(1);
    }, 300);
};

const openModal = (supplier = null) => {
    if (supplier) {
        isEditing.value = true;
        Object.assign(form, supplier);
    } else {
        isEditing.value = false;
        Object.assign(form, {
            id: null,
            name: '',
            contact_person: '',
            phone: '',
            email: '',
            address: '',
            note: ''
        });
    }
    showModal.value = true;
};

const closeModal = () => showModal.value = false;

const submitForm = async () => {
    formLoading.value = true;
    try {
        const payload = { ...form };
        if (isEditing.value) {
            await api.put(`/admin/suppliers/${form.id}`, payload);
            toast.success("Supplier updated");
        } else {
            await api.post('/admin/suppliers', payload);
            toast.success("Supplier created");
        }
        closeModal();
        fetchSuppliers();
    } catch (error) {
        toast.error("Failed to save supplier");
    } finally {
        formLoading.value = false;
    }
};

const deleteSupplier = async (supplier) => {
    if (!confirm("Delete this supplier?")) return;
    try {
        await api.delete(`/admin/suppliers/${supplier.id}`);
        toast.success("Supplier deleted");
        fetchSuppliers();
    } catch {
        toast.error("Failed to delete");
    }
};

const changePage = (page) => {
    if (page >= 1 && page <= suppliers.value.last_page) {
        fetchSuppliers(page);
    }
};

onMounted(() => {
    fetchSuppliers();
});
</script>
