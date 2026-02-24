<template>
    <MainLayout :loading="pageLoading">
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
            <h1 class="text-2xl font-bold text-slate-800">Product Management</h1>
            <router-link to="/admin/products/create" class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-sm w-full md:w-auto justify-center">
                <PlusIcon class="w-5 h-5 mr-2" />
                Add Product
            </router-link>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
             <!-- Filters -->
             <div class="p-6 border-b border-gray-100 flex flex-col md:flex-row gap-4 items-center bg-gray-50/50">
                 <div class="relative w-full md:w-auto">
                    <span class="absolute inset-y-0 left-0 flex items-center pl-3">
                        <SearchIcon class="w-5 h-5 text-gray-400" />
                    </span>
                    <input 
                        v-model="search" 
                        @input="debouncedSearch"
                        type="text" 
                        placeholder="Search products..." 
                        class="pl-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary w-full md:w-96 py-2.5 shadow-sm"
                    >
                 </div>
                 <select v-model="filterCategory" @change="fetchProducts" class="border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary py-2.5 shadow-sm w-full md:w-auto">
                     <option value="">All Categories</option>
                     <option v-for="cat in (categories || []).filter(c => c != null)" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
                 </select>
             </div>

            <div class="overflow-x-auto">
                <table class="w-full text-left whitespace-nowrap">
                    <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                        <tr>
                            <th class="px-6 py-4 font-semibold">Product</th>
                            <th class="px-6 py-4 font-semibold">SKU</th>
                            <th class="px-6 py-4 font-semibold">Category</th>
                            <th class="px-6 py-4 font-semibold">Price</th>
                            <th class="px-6 py-4 font-semibold">Upsell</th>
                            <th class="px-6 py-4 font-semibold">Status</th>
                            <th class="px-6 py-4 font-semibold text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 text-sm">
                        <tr v-for="product in (products.data || []).filter(p => p != null)" :key="product.id" class="hover:bg-gray-50 transition-colors group">
                            <td class="px-6 py-5">
                                <div class="flex items-center">
                                    <img :src="product.image_url || '/no-image.jpg'" class="h-12 w-12 rounded-lg bg-gray-100 object-cover mr-4 border border-gray-200 group-hover:border-primary/30 transition-colors">
                                    <span class="font-bold text-slate-800 text-base">{{ product.name }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-5 text-gray-500">{{ product.sku }}</td>
                            <td class="px-6 py-5">
                                <span class="px-2.5 py-1 rounded-md bg-gray-100 text-gray-600 font-medium text-xs">
                                    {{ product.category?.name || 'Uncategorized' }}
                                </span>
                            </td>
                            <td class="px-6 py-5 font-bold text-slate-800">{{ formatCurrency(product.price) }}</td>
                            <td class="px-6 py-5">
                                <button 
                                    @click="toggleUpsell(product)"
                                    class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2"
                                    :class="product.is_upsell ? 'bg-primary' : 'bg-gray-200'"
                                >
                                    <span 
                                        class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"
                                        :class="product.is_upsell ? 'translate-x-5' : 'translate-x-0'"
                                    ></span>
                                </button>
                            </td>
                            <td class="px-6 py-5">
                                 <span :class="product.is_available ? 'bg-green-100 text-green-700 ring-1 ring-green-600/20' : 'bg-red-100 text-red-700 ring-1 ring-red-600/20'" class="px-2.5 py-1 rounded-full text-xs font-bold inline-flex items-center">
                                    <template v-if="product.is_available">
                                        <span class="w-1.5 h-1.5 rounded-full bg-green-600 mr-1.5"></span> Available
                                    </template>
                                    <template v-else>
                                        <span class="w-1.5 h-1.5 rounded-full bg-red-600 mr-1.5"></span> Unavailable
                                    </template>
                                </span>
                            </td>
                            <td class="px-6 py-5 text-right space-x-2">
                                 <div class="flex items-center justify-end space-x-3">
                                    <router-link :to="`/admin/products/${product.id}/edit`" class="text-blue-400 hover:text-blue-600 transition-colors p-1 rounded-lg hover:bg-blue-50" title="Edit">
                                        <PencilIcon class="w-5 h-5" />
                                    </router-link>
                                    <button @click="deleteProduct(product.id)" class="text-red-400 hover:text-red-600 transition-colors p-1 rounded-lg hover:bg-red-50" title="Delete">
                                        <TrashIcon class="w-5 h-5" />
                                    </button>
                                 </div>
                            </td>
                        </tr>
                        <tr v-if="products.data?.length === 0">
                            <td colspan="6" class="px-6 py-12 text-center text-gray-400 bg-gray-50/50">
                                <div class="flex flex-col items-center justify-center">
                                    <p class="text-lg font-medium text-gray-500">No products found</p>
                                    <p class="text-sm">Try adjusting your search or filters</p>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
            
             <!-- Pagination -->
            <div class="p-6 border-t border-gray-100 flex flex-col md:flex-row justify-between items-center gap-4 bg-gray-50/30">
                <span class="text-sm text-gray-500 font-medium">
                    Showing {{ products.from || 0 }} to {{ products.to || 0 }} of {{ products.total || 0 }} results
                </span>
                <div class="space-x-2">
                    <button 
                        @click="changePage(products.current_page - 1)" 
                        :disabled="!products.prev_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all"
                    >Previous</button>
                    <button 
                        @click="changePage(products.current_page + 1)" 
                        :disabled="!products.next_page_url"
                        class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all"
                    >Next</button>
                </div>
            </div>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import MainLayout from '../../../components/layout/MainLayout.vue';
import { PlusIcon, SearchIcon, PencilIcon, TrashIcon } from 'lucide-vue-next';
import api from '../../../api/axios'; 
import { useToast } from "vue-toastification";

const toast = useToast();
const products = ref({ data: [] });
const categories = ref([]);
const search = ref('');
const filterCategory = ref('');
const pageLoading = ref(true);

const fetchProducts = async (page = 1) => {
    // Only trigger skeleton if we don't have data yet
    if (!products.value.data) pageLoading.value = true;

    try {
        const response = await api.get('/admin/products', {
            params: {
                page,
                search: search.value,
                category_id: filterCategory.value
            }
        });
        products.value = response.data?.data || response.data || { data: [] };
    } catch (error) {
        console.error("Fetch products failed", error);
    } finally {
        pageLoading.value = false;
    }
};

const fetchCategories = async () => {
    try {
         const response = await api.get('/admin/categories');
         const rawData = response.data?.data ?? response.data ?? [];
         categories.value = Array.isArray(rawData) ? rawData : [];
    } catch(e) {
        categories.value = [];
    }
};

let debounceTimeout = null;
const debouncedSearch = () => {
    if (debounceTimeout) clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
        fetchProducts(1);
    }, 300);
};

const toggleUpsell = async (product) => {
    try {
        const newValue = !product.is_upsell;
        await api.put(`/admin/products/${product.id}`, {
            is_upsell: newValue
        });
        product.is_upsell = newValue;
        toast.success(`${product.name} ${newValue ? 'added to' : 'removed from'} upsell`);
    } catch (error) {
        toast.error("Failed to update upsell status");
        console.error(error);
    }
};

const changePage = (page) => {
    if (page >= 1 && page <= products.value.last_page) {
        fetchProducts(page);
    }
};

const deleteProduct = async (id) => {
    if(!confirm('Delete this product?')) return;
    try {
        await api.delete(`/admin/products/${id}`);
        toast.success("Product deleted successfully!");
        fetchProducts(products.value.current_page);
    } catch(e) {
        toast.error("Failed to delete product");
    }
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(value);
};

onMounted(() => {
    fetchCategories();
    fetchProducts();
});
</script>
