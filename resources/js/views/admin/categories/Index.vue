<template>
    <MainLayout :loading="pageLoading">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-slate-800">Category Management</h1>
            <button @click="openModal()" class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-sm">
                <PlusIcon class="w-5 h-5 mr-2" />
                Add Category
            </button>
        </div>

        <!-- Category List -->
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
                        placeholder="Search categories..." 
                        class="pl-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary w-full md:w-80 py-2.5 shadow-sm"
                    >
                 </div>
             </div>

            <table class="w-full text-left">
                <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                    <tr>
                        <th class="px-6 py-4 font-semibold">Name</th>
                        <th class="px-6 py-4 font-semibold">Slug</th>
                        <th class="px-6 py-4 font-semibold">Status</th>
                        <th class="px-6 py-4 font-semibold text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    <tr v-for="category in (categories || []).filter(c => c != null)" :key="category.id" class="hover:bg-gray-50 transition-colors group">
                        <td class="px-6 py-5 font-bold text-slate-800 text-base">{{ category.name }}</td>
                        <td class="px-6 py-5 text-gray-500 font-mono text-xs">{{ category.slug }}</td>
                        <td class="px-6 py-5">
                            <span :class="category.is_active ? 'bg-green-100 text-green-700 ring-1 ring-green-600/20' : 'bg-gray-100 text-gray-600 ring-1 ring-gray-600/20'" class="px-2.5 py-1 rounded-full text-xs font-bold inline-flex items-center">
                                <span class="w-1.5 h-1.5 rounded-full mr-1.5" :class="category.is_active ? 'bg-green-600' : 'bg-gray-500'"></span>
                                {{ category.is_active ? 'Active' : 'Inactive' }}
                            </span>
                        </td>
                        <td class="px-6 py-5 text-right space-x-2">
                             <div class="flex items-center justify-end space-x-3">
                                <button @click="openModal(category)" class="text-blue-400 hover:text-blue-600 transition-colors p-1 rounded-lg hover:bg-blue-50" title="Edit">
                                    <PencilIcon class="w-5 h-5" />
                                </button>
                                <button @click="deleteCategory(category.id)" class="text-red-400 hover:text-red-600 transition-colors p-1 rounded-lg hover:bg-red-50" title="Delete">
                                    <TrashIcon class="w-5 h-5" />
                                </button>
                             </div>
                        </td>
                    </tr>
                    <tr v-if="categories.length === 0">
                        <td colspan="4" class="px-6 py-12 text-center text-gray-400 bg-gray-50/50">
                            <div class="flex flex-col items-center justify-center">
                                <p class="text-lg font-medium text-gray-500">No categories found</p>
                                <p class="text-sm">Click "Add Category" to create one</p>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
            <!-- Backdrop -->
            <div class="absolute inset-0 bg-black/30 backdrop-blur-sm" @click="closeModal"></div>
            
            <!-- Modal Content -->
            <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg relative z-10 p-6">
                <h2 class="text-xl font-bold mb-4">{{ isEditing ? 'Edit Category' : 'New Category' }}</h2>
                
                <form @submit.prevent="saveCategory" class="space-y-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                        <input v-model="form.name" type="text" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>
                    
                    <div class="flex items-center">
                        <input v-model="form.is_active" type="checkbox" id="is_active" class="text-primary focus:ring-primary rounded border-gray-300">
                        <label for="is_active" class="ml-2 text-sm text-gray-700">Active</label>
                    </div>

                    <div class="flex justify-end space-x-3 mt-6">
                        <button type="button" @click="closeModal" class="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg">Cancel</button>
                        <button type="submit" class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-green-800 disabled:opacity-50" :disabled="loading">
                            {{ loading ? 'Saving...' : 'Save Category' }}
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
import { useToast } from "vue-toastification";

const toast = useToast();

const categories = ref([]);
const search = ref('');
const showModal = ref(false);
const isEditing = ref(false);
const loading = ref(false); // Form loading
const pageLoading = ref(true); // Page skeleton loading
const editId = ref(null);

const form = reactive({
    name: '',
    is_active: true
});

const fetchCategories = async () => {
    // Only show skeleton on initial load or if explicitly needed
    if (categories.value.length === 0) pageLoading.value = true;
    
    try {
        const response = await api.get('/admin/categories', {
            params: { search: search.value }
        });
        const rawData = response.data?.data ?? response.data ?? [];
        categories.value = Array.isArray(rawData) ? rawData : [];
    } catch (error) {
        console.error('Error fetching categories:', error);
    } finally {
        pageLoading.value = false;
    }
};

let debounceTimeout = null;
const debouncedSearch = () => {
    if (debounceTimeout) clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
        fetchCategories();
    }, 300);
};

const openModal = (category = null) => {
    if (category) {
        isEditing.value = true;
        editId.value = category.id;
        form.name = category.name;
        form.is_active = !!category.is_active;
    } else {
        isEditing.value = false;
        editId.value = null;
        form.name = '';
        form.is_active = true;
    }
    showModal.value = true;
};

const closeModal = () => {
    showModal.value = false;
};

const saveCategory = async () => {
    loading.value = true;
    try {
        if (isEditing.value) {
            await api.put(`/admin/categories/${editId.value}`, form);
            toast.success("Category updated successfully!");
        } else {
            await api.post('/admin/categories', form);
            toast.success("Category created successfully!");
        }
        await fetchCategories();
        closeModal();
    } catch (error) {
        toast.error(error.response?.data?.message || 'Failed to save category');
    } finally {
        loading.value = false;
    }
};

const deleteCategory = async (id) => {
    if (!confirm('Are you sure you want to delete this category?')) return;
    
    try {
        await api.delete(`/admin/categories/${id}`);
        toast.success("Category deleted successfully!");
        await fetchCategories();
    } catch (error) {
         toast.error(error.response?.data?.message || 'Failed to delete category');
    }
};

onMounted(() => {
    fetchCategories();
});
</script>
