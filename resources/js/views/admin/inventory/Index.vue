<template>
    <MainLayout :loading="pageLoading">
        <div class="flex justify-between items-center mb-6">
            <div>
                <h1 class="text-2xl font-bold text-slate-800">Inventory Management</h1>
                <p class="text-gray-500">Manage ingredients, stock levels, and costs.</p>
            </div>
            <div class="flex space-x-3">
                 <button @click="openStockInModal()" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-sm">
                    <PlusIcon class="w-5 h-5 mr-2" />
                    Stock In
                </button>
                <button @click="openModal()" class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-sm">
                    <PlusIcon class="w-5 h-5 mr-2" />
                    Add Ingredient
                </button>
            </div>
        </div>

        <!-- Ingredient List -->
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
                        placeholder="Search ingredients..." 
                        class="pl-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary w-full md:w-80 py-2.5 shadow-sm"
                    >
                 </div>
             </div>

            <table class="w-full text-left">
                <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                    <tr>
                        <th class="px-6 py-4 font-semibold">Name</th>
                        <th class="px-6 py-4 font-semibold">Stock</th>
                        <th class="px-6 py-4 font-semibold">Unit</th>
                        <th class="px-6 py-4 font-semibold">Avg Cost (IDR)</th>
                         <th class="px-6 py-4 font-semibold">Status</th>
                        <th class="px-6 py-4 font-semibold text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    <tr v-for="item in (ingredients || []).filter(i => i != null)" :key="item.id" class="hover:bg-gray-50 transition-colors group">
                        <td class="px-6 py-5 font-bold text-slate-800 text-base">{{ item.name }}</td>
                        <td class="px-6 py-5 font-bold" :class="item.current_stock <= item.minimum_stock_alert ? 'text-red-600' : 'text-slate-700'">
                            {{ parseFloat(item.current_stock) }}
                        </td>
                        <td class="px-6 py-5 text-gray-500 text-xs uppercase font-medium tracking-wide">{{ item.unit }}</td>
                        <td class="px-6 py-5 text-slate-700 font-mono">{{ formatCurrency(item.cost_per_unit) }}</td>
                        <td class="px-6 py-5">
                             <span v-if="item.current_stock <= item.minimum_stock_alert" class="bg-red-100 text-red-700 ring-1 ring-red-600/20 px-2.5 py-1 rounded-full text-xs font-bold inline-flex items-center">
                                <span class="w-1.5 h-1.5 rounded-full bg-red-600 mr-1.5"></span> Low Stock
                            </span>
                            <span v-else class="bg-green-100 text-green-700 ring-1 ring-green-600/20 px-2.5 py-1 rounded-full text-xs font-bold inline-flex items-center">
                                <span class="w-1.5 h-1.5 rounded-full bg-green-600 mr-1.5"></span> OK
                            </span>
                        </td>
                        <td class="px-6 py-5 text-right space-x-2">
                             <div class="flex items-center justify-end space-x-3">
                                <button @click="openModal(item)" class="text-blue-400 hover:text-blue-600 transition-colors p-1 rounded-lg hover:bg-blue-50" title="Edit">
                                    <PencilIcon class="w-5 h-5" />
                                </button>
                                <button @click="deleteIngredient(item.id)" class="text-red-400 hover:text-red-600 transition-colors p-1 rounded-lg hover:bg-red-50" title="Delete">
                                    <TrashIcon class="w-5 h-5" />
                                </button>
                             </div>
                        </td>
                    </tr>
                    <tr v-if="ingredients.length === 0">
                        <td colspan="6" class="px-6 py-12 text-center text-gray-400 bg-gray-50/50">
                            <div class="flex flex-col items-center justify-center">
                                <p class="text-lg font-medium text-gray-500">No ingredients found</p>
                                <p class="text-sm">Start by adding raw materials.</p>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Add/Edit Ingredient Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div class="absolute inset-0 bg-black/30 backdrop-blur-sm" @click="closeModal"></div>
            <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg relative z-10 p-6">
                <h2 class="text-xl font-bold mb-4">{{ isEditing ? 'Edit Ingredient' : 'New Ingredient' }}</h2>
                <form @submit.prevent="saveIngredient" class="space-y-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                        <input v-model="form.name" type="text" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Unit</label>
                        <select v-model="form.unit" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                             <option value="gram">Gram (g)</option>
                             <option value="ml">Milliliter (ml)</option>
                             <option value="pcs">Pieces (pcs)</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Minimum Stock Alert</label>
                        <input v-model="form.minimum_stock_alert" type="number" step="0.01" min="0" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>
                    <div class="flex justify-end space-x-3 mt-6">
                        <button type="button" @click="closeModal" class="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg">Cancel</button>
                        <button type="submit" class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-green-800 disabled:opacity-50" :disabled="loading">
                            {{ loading ? 'Saving...' : 'Save' }}
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Stock In Modal -->
        <div v-if="showStockInModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div class="absolute inset-0 bg-black/30 backdrop-blur-sm" @click="closeStockInModal"></div>
            <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg relative z-10 p-6">
                 <h2 class="text-xl font-bold mb-4">Stock In (Purchase)</h2>
                 <form @submit.prevent="submitStockIn" class="space-y-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Ingredient</label>
                        <select v-model="stockInForm.ingredient_id" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                            <option value="" disabled>Select Ingredient</option>
                            <option v-for="item in ingredients" :key="item.id" :value="item.id">
                                {{ item.name }} (Current: {{ parseFloat(item.current_stock) }} {{ item.unit }})
                            </option>
                        </select>
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                         <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Quantity Added</label>
                            <input v-model="stockInForm.quantity" type="number" step="0.01" min="0" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                        </div>
                         <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Cost Per Unit (IDR)</label>
                            <input v-model="stockInForm.unit_cost" type="number" step="0.01" min="0" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                        </div>
                    </div>
                    <div>
                         <label class="block text-sm font-medium text-gray-700 mb-1">Notes (Optional)</label>
                         <textarea v-model="stockInForm.notes" rows="2" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4"></textarea>
                    </div>
                    <div class="bg-blue-50 p-4 rounded-lg text-sm text-blue-700 mb-4">
                        Total Value: <strong>{{ formatCurrency(stockInForm.quantity * stockInForm.unit_cost) }}</strong>
                    </div>

                    <div class="flex justify-end space-x-3 mt-6">
                        <button type="button" @click="closeStockInModal" class="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg">Cancel</button>
                        <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50" :disabled="loading">
                             {{ loading ? 'Processing...' : 'Confirm Stock In' }}
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
import { PlusIcon, PencilIcon, TrashIcon, SearchIcon } from 'lucide-vue-next';
import api from '../../../api/axios';
import { useToast } from 'vue-toastification';

const toast = useToast();
const ingredients = ref([]);
const search = ref('');
const showModal = ref(false);
const showStockInModal = ref(false);
const isEditing = ref(false);
const loading = ref(false);
const pageLoading = ref(true);
const editId = ref(null);

const form = reactive({
    name: '',
    unit: 'gram',
    minimum_stock_alert: 100
});

const stockInForm = reactive({
    ingredient_id: '',
    quantity: 0,
    unit_cost: 0,
    notes: ''
});

const fetchIngredients = async () => {
    if (ingredients.value.length === 0) pageLoading.value = true;
    try {
        const response = await api.get('/admin/ingredients', {
            params: { search: search.value }
        });
        const rawData = response.data?.data || response.data || [];
        ingredients.value = Array.isArray(rawData) ? rawData : [];
    } catch (error) {
        toast.error('Failed to load ingredients');
    } finally {
        pageLoading.value = false;
    }
};

let debounceTimeout = null;
const debouncedSearch = () => {
    if (debounceTimeout) clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
        fetchIngredients();
    }, 300);
};

const openModal = (item = null) => {
    if (item) {
        isEditing.value = true;
        editId.value = item.id;
        form.name = item.name;
        form.unit = item.unit;
        form.minimum_stock_alert = item.minimum_stock_alert;
    } else {
        isEditing.value = false;
        editId.value = null;
        form.name = '';
        form.unit = 'gram';
        form.minimum_stock_alert = 100;
    }
    showModal.value = true;
};

const closeModal = () => {
    showModal.value = false;
};

const saveIngredient = async () => {
    loading.value = true;
    try {
        if (isEditing.value) {
            await api.put(`/admin/ingredients/${editId.value}`, form);
            toast.success('Ingredient updated successfully');
        } else {
            await api.post('/admin/ingredients', form);
            toast.success('Ingredient created successfully');
        }
        await fetchIngredients();
        closeModal();
    } catch (error) {
        toast.error(error.response?.data?.message || 'Failed to save ingredient');
    } finally {
        loading.value = false;
    }
};

const deleteIngredient = async (id) => {
    if (!confirm('Delete this ingredient?')) return;
    try {
        await api.delete(`/admin/ingredients/${id}`);
        toast.success('Ingredient deleted');
        await fetchIngredients();
    } catch (error) {
        toast.error('Failed to delete ingredient');
    }
};

// Stock In Logic
const openStockInModal = () => {
    stockInForm.ingredient_id = '';
    stockInForm.quantity = 0;
    stockInForm.unit_cost = 0;
    stockInForm.notes = '';
    showStockInModal.value = true;
};

const closeStockInModal = () => {
    showStockInModal.value = false;
};

const submitStockIn = async () => {
   loading.value = true;
   try {
       await api.post('/admin/inventory/stock-in', stockInForm);
       toast.success('Stock added successfully');
       await fetchIngredients();
       closeStockInModal();
   } catch (error) {
       toast.error(error.response?.data?.message || 'Failed to stock in');
   } finally {
       loading.value = false;
   }
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(value);
};

onMounted(() => {
    fetchIngredients();
});
</script>
