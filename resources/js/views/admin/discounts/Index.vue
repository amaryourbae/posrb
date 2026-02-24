<template>
    <MainLayout :loading="pageLoading">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-slate-800">Discount & Vouchers</h1>
            <button @click="openModal()" class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-lg shadow-green-200">
                <PlusIcon class="w-5 h-5 mr-2" />
                Add Discount
            </button>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
             <!-- Search -->
             <div class="p-6 border-b border-gray-100 bg-gray-50/50">
                 <div class="relative max-w-sm">
                    <span class="absolute inset-y-0 left-0 flex items-center pl-3">
                        <SearchIcon class="w-5 h-5 text-gray-400" />
                    </span>
                    <input 
                        v-model="search" 
                        @input="debouncedSearch"
                        type="text" 
                        placeholder="Search name or code..." 
                        class="pl-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary w-full py-2 shadow-sm"
                    >
                 </div>
             </div>

            <table class="w-full text-left">
                <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                    <tr>
                        <th class="px-6 py-4 font-semibold">Name</th>
                        <th class="px-6 py-4 font-semibold">Code</th>
                        <th class="px-6 py-4 font-semibold">Value</th>
                        <th class="px-6 py-4 font-semibold">Status</th>
                        <th class="px-6 py-4 font-semibold">Valid Period</th>
                        <th class="px-6 py-4 font-semibold text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    <tr v-for="discount in (discounts.data || []).filter(d => d != null)" :key="discount.id" class="hover:bg-gray-50 transition-colors">
                        <td class="px-6 py-4 font-bold text-slate-800">{{ discount.name }}</td>
                        <td class="px-6 py-4 font-mono text-gray-600 bg-gray-100 rounded-md inline-block my-2 text-xs">{{ discount.code }}</td>
                        <td class="px-6 py-4 font-bold text-primary">
                            {{ discount.type === 'percentage' ? discount.value + '%' : formatCurrency(discount.value) }}
                        </td>
                        <td class="px-6 py-4">
                            <span :class="discount.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'" class="px-2 py-1 rounded-full text-xs font-bold capitalize">
                                {{ discount.is_active ? 'Active' : 'Inactive' }}
                            </span>
                        </td>
                        <td class="px-6 py-4 text-xs text-gray-500">
                             <div v-if="discount.start_date || discount.end_date">
                                 {{ discount.start_date ? formatDate(discount.start_date) : 'Anytime' }} - 
                                 {{ discount.end_date ? formatDate(discount.end_date) : 'Forever' }}
                             </div>
                             <span v-else>Always Valid</span>
                        </td>
                        <td class="px-6 py-4 text-right space-x-2">
                             <button @click="openModal(discount)" class="text-blue-600 hover:text-blue-800 font-medium text-sm hover:underline">Edit</button>
                             <button @click="deleteDiscount(discount)" class="text-red-500 hover:text-red-700 font-medium text-sm hover:underline">Delete</button>
                        </td>
                    </tr>
                    <tr v-if="discounts.data?.length === 0">
                        <td colspan="6" class="px-6 py-12 text-center text-gray-400">No discounts found</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div class="absolute inset-0 bg-black/30 backdrop-blur-sm" @click="closeModal"></div>
            <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg relative z-10 overflow-hidden flex flex-col max-h-[90vh]">
                <div class="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50">
                    <h2 class="text-xl font-bold text-slate-800">{{ isEditing ? 'Edit Discount' : 'Add Discount' }}</h2>
                    <button @click="closeModal" class="text-gray-400 hover:text-gray-600"><XIcon class="w-6 h-6" /></button>
                </div>
                
                <form @submit.prevent="submitForm" class="p-6 space-y-4 overflow-y-auto">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                        <input v-model="form.name" type="text" required placeholder="e.g., Summer Sale" class="w-full border-gray-300 rounded-lg focus:ring-primary focus:border-primary">
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                         <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Code</label>
                            <input v-model="form.code" type="text" required placeholder="SUMMER10" class="w-full border-gray-300 rounded-lg focus:ring-primary focus:border-primary font-mono uppercase">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Type</label>
                            <select v-model="form.type" class="w-full border-gray-300 rounded-lg focus:ring-primary focus:border-primary">
                                <option value="percentage">Percentage (%)</option>
                                <option value="fixed">Fixed Amount (Rp)</option>
                            </select>
                        </div>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Value</label>
                        <input v-model="form.value" type="number" required min="0" class="w-full border-gray-300 rounded-lg focus:ring-primary focus:border-primary">
                    </div>
                    
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Min. Purchase (Optional)</label>
                        <input v-model="form.min_purchase" type="number" min="0" class="w-full border-gray-300 rounded-lg focus:ring-primary focus:border-primary">
                    </div>

                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
                            <input v-model="form.start_date" type="date" class="w-full border-gray-300 rounded-lg focus:ring-primary focus:border-primary">
                        </div>
                        <div>
                             <label class="block text-sm font-medium text-gray-700 mb-1">End Date</label>
                            <input v-model="form.end_date" type="date" class="w-full border-gray-300 rounded-lg focus:ring-primary focus:border-primary">
                        </div>
                    </div>
                    
                    <div class="flex items-center">
                        <input v-model="form.is_active" type="checkbox" id="is_active" class="rounded border-gray-300 text-primary focus:ring-primary w-4 h-4">
                        <label for="is_active" class="ml-2 text-sm text-gray-700 font-medium">Active</label>
                    </div>

                    <div class="pt-4 flex justify-end space-x-3">
                        <button type="button" @click="closeModal" class="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 font-medium">Cancel</button>
                        <button type="submit" :disabled="formLoading" class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-green-800 font-bold disabled:opacity-50">
                            {{ formLoading ? 'Saving...' : 'Save Discount' }}
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
import { format as dateFormat } from 'date-fns';

const toast = useToast();
const discounts = ref({ data: [] });
const search = ref('');
const pageLoading = ref(true);
const showModal = ref(false);
const isEditing = ref(false);
const formLoading = ref(false);

const form = reactive({
    id: null,
    name: '',
    code: '',
    type: 'percentage',
    value: 0,
    min_purchase: 0,
    start_date: '',
    end_date: '',
    is_active: true
});

const fetchDiscounts = async (page = 1) => {
    try {
        const response = await api.get('/admin/discounts', {
            params: { page, search: search.value }
        });
        discounts.value = response.data?.data || response.data || {};
    } catch (error) {
        console.error("Fetch discounts failed", error);
    } finally {
        pageLoading.value = false;
    }
};

let debounceTimeout = null;
const debouncedSearch = () => {
    if (debounceTimeout) clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
        fetchDiscounts(1);
    }, 300);
};

const openModal = (discount = null) => {
    if (discount) {
        isEditing.value = true;
        Object.assign(form, discount);
        // Date formatting for input type="date"
        if (form.start_date) form.start_date = form.start_date.split('T')[0];
        if (form.end_date) form.end_date = form.end_date.split('T')[0];
    } else {
        isEditing.value = false;
        Object.assign(form, {
            id: null,
            name: '',
            code: '',
            type: 'percentage',
            value: 0,
            min_purchase: 0,
            start_date: '',
            end_date: '',
            is_active: true
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
            await api.put(`/admin/discounts/${form.id}`, payload);
            toast.success("Discount updated");
        } else {
            await api.post('/admin/discounts', payload);
            toast.success("Discount created");
        }
        closeModal();
        fetchDiscounts();
    } catch (error) {
        toast.error("Failed to save discount. Code might be duplicate.");
    } finally {
        formLoading.value = false;
    }
};

const deleteDiscount = async (discount) => {
    if (!confirm("Are you sure?")) return;
    try {
        await api.delete(`/admin/discounts/${discount.id}`);
        toast.success("Discount deleted");
        fetchDiscounts();
    } catch {
        toast.error("Failed to delete");
    }
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(value);
};

const formatDate = (dateString) => {
    return dateFormat(new Date(dateString), 'dd MMM yyyy');
};

onMounted(() => {
    fetchDiscounts();
});
</script>
