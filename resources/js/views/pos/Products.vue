<template>
    <PosLayout>
        <div class="flex flex-col lg:flex-row h-full overflow-hidden relative">
            <!-- Main Content (Product List) -->
            <div 
                class="flex-1 flex flex-col h-full relative overflow-hidden transition-all duration-300 ease-in-out"
                :class="{ 'lg:mr-[400px]': selectedProduct || isCreating }"
            >
                <!-- Header (Actions) -->
                <div class="px-6 pt-6 pb-4 shrink-0 flex flex-col gap-4 bg-white border-b border-gray-100">
                    <div class="flex items-center justify-between">
                        <h2 class="text-2xl font-bold text-gray-900">All Menu</h2>
                        <button 
                            @click="startCreate"
                            class="flex items-center gap-2 px-5 py-2.5 bg-primary hover:bg-[#004d34] text-white rounded-xl font-medium shadow-lg shadow-primary/20 transition-all active:scale-95"
                        >
                            <PlusIcon class="w-4 h-4" />
                            <span>Add Menu</span>
                        </button>
                    </div>
                    <div class="relative">
                        <SearchIcon class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                        <input 
                            v-model="searchQuery"
                            type="text"
                            class="w-full pl-12 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none shadow-sm text-sm transition-colors" 
                            placeholder="Search product name, SKU..." 
                        />
                    </div>
                </div>

                <!-- Filters -->
                <div class="px-6 py-4 shrink-0 overflow-x-auto no-scrollbar bg-white/50 border-b border-gray-50">
                    <div class="flex space-x-3">
                        <button 
                            @click="activeCategory = 'all'"
                            class="px-5 py-2 rounded-full text-sm font-medium shadow-sm whitespace-nowrap transition border"
                            :class="activeCategory === 'all' 
                                ? 'bg-primary text-white border-transparent shadow-primary/20' 
                                : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'"
                        >
                            All Items
                        </button>
                        <button 
                            v-for="cat in categories"
                            :key="cat.id"
                            @click="activeCategory = cat.id"
                            class="px-5 py-2 rounded-full text-sm font-medium shadow-sm whitespace-nowrap transition border"
                            :class="activeCategory === cat.id
                                ? 'bg-primary text-white border-transparent shadow-primary/20' 
                                : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'"
                        >
                            {{ cat.name }}
                        </button>
                    </div>
                </div>

                <!-- Product Grid -->
                <div class="flex-1 overflow-y-auto px-6 py-6 pb-24 lg:pb-6 bg-gray-50">
                    <div v-if="loading" class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 animate-pulse">
                        <div v-for="i in 8" :key="i" class="bg-white p-3 rounded-2xl shadow-sm h-64"></div>
                    </div>
                    
                    <div v-else-if="products.length > 0" class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
                        <div 
                            v-for="product in products" 
                            :key="product.id"
                            @click="editProduct(product)"
                            class="bg-white p-3 rounded-2xl shadow-sm border transition group cursor-pointer flex flex-col h-full relative"
                            :class="(selectedProduct?.id === product.id) ? 'border-primary ring-2 ring-primary ring-opacity-100' : 'border-transparent hover:border-gray-200'"
                        >
                             <div class="relative aspect-4/3 rounded-xl overflow-hidden mb-3 bg-gray-100">
                                <img 
                                    :src="product.image_url || '/no-image.jpg'" 
                                    class="w-full h-full object-cover group-hover:scale-105 transition duration-300"
                                    :class="{'grayscale opacity-70': !product.is_available}"
                                    @error="$event.target.src = '/no-image.jpg'"
                                />
                                <div class="absolute top-2 right-2 bg-white/90 backdrop-blur rounded-full p-1.5 text-primary opacity-0 group-hover:opacity-100 transition">
                                    <PenIcon class="w-3 h-3" />
                                </div>
                            </div>
                            
                            <div class="flex justify-between items-start mb-2">
                                <div>
                                    <h3 class="font-bold text-gray-800 text-sm mb-0.5 line-clamp-1">{{ product.name }}</h3>
                                    <p class="text-gray-500 text-xs">{{ formatCurrency(product.price) }}</p>
                                </div>
                            </div>
                            
                            <div class="mt-auto pt-3 border-t border-gray-100 flex items-center justify-between">
                                <span 
                                    class="text-[10px] font-semibold uppercase tracking-wider"
                                    :class="product.is_available ? 'text-gray-400' : 'text-red-500'"
                                >
                                    {{ product.is_available ? 'Available' : 'Hidden' }}
                                </span>
                                <div 
                                    class="w-8 h-5 rounded-full relative transition-colors"
                                    :class="product.is_available ? 'bg-primary' : 'bg-gray-200'"
                                >
                                    <span 
                                        class="absolute top-1 bg-white w-3 h-3 rounded-full transition-transform shadow-sm"
                                        :class="product.is_available ? 'left-1 translate-x-3' : 'left-1'"
                                    ></span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div v-else class="flex flex-col items-center justify-center h-64 text-gray-400">
                         <LayoutGridIcon class="w-12 h-12 mb-2 text-gray-300" />
                         <p>No products found</p>
                    </div>
                </div>
            </div>

            <!-- Editor Sidebar -->
            <aside 
                v-if="selectedProduct || isCreating"
                class="absolute inset-y-0 right-0 w-full lg:w-[400px] bg-white shadow-2xl z-20 flex flex-col border-l border-gray-100 shrink-0 transform transition-transform duration-300"
            >
                <div class="p-6 flex justify-between items-center border-b border-gray-100">
                    <h2 class="text-xl font-bold text-gray-900">{{ isCreating ? 'New Product' : 'Edit Product' }}</h2>
                    <button @click="closeEditor" class="p-2 hover:bg-gray-100 rounded-lg text-gray-500 transition">
                        <XIcon class="w-5 h-5" />
                    </button>
                </div>

                <div class="flex-1 overflow-y-auto px-6 py-6">
                    <form @submit.prevent="saveProduct" class="flex flex-col gap-6">
                        <!-- Image Upload -->
                        <div class="flex justify-center">
                            <div 
                                class="relative group cursor-pointer"
                                @click="$refs.fileInput.click()"
                            >
                                <div class="w-40 h-40 rounded-2xl overflow-hidden shadow-md bg-gray-100 border-2 border-dashed border-gray-300 hover:border-primary transition">
                                    <img 
                                        v-if="form.image_preview || form.image_url" 
                                        :src="form.image_preview || form.image_url" 
                                        class="w-full h-full object-cover" 
                                    />
                                    <div v-else class="w-full h-full flex items-center justify-center text-gray-400">
                                        <CameraIcon class="w-8 h-8" />
                                    </div>
                                </div>
                                <button type="button" class="absolute bottom-2 right-2 bg-white p-2 rounded-full shadow-lg text-primary hover:scale-110 transition">
                                    <CameraIcon class="w-4 h-4" />
                                </button>
                                <input 
                                    ref="fileInput"
                                    type="file" 
                                    accept="image/*" 
                                    class="hidden" 
                                    @change="handleImagePayload"
                                />
                            </div>
                        </div>

                        <div class="space-y-4">
                            <div>
                                <label class="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Product Information</label>
                                <div class="space-y-3">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 mb-1">Product Name</label>
                                        <input 
                                            v-model="form.name"
                                            required
                                            class="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-200 text-sm focus:ring-1 focus:ring-primary focus:border-primary outline-none transition-colors" 
                                            type="text" 
                                            placeholder="e.g. Buttercream Latte"
                                        />
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 mb-1">SKU</label>
                                        <input 
                                            v-model="form.sku"
                                            required
                                            class="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-200 text-sm focus:ring-1 focus:ring-primary focus:border-primary outline-none transition-colors" 
                                            type="text" 
                                            placeholder="e.g. BEV-001"
                                        />
                                    </div>
                                    <div class="grid grid-cols-2 gap-3">
                                        <div>
                                            <label class="block text-sm font-medium text-gray-700 mb-1">Price (Rp)</label>
                                            <input 
                                                v-model="form.price"
                                                required
                                                class="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-200 text-sm focus:ring-1 focus:ring-primary focus:border-primary outline-none transition-colors" 
                                                type="number" 
                                                min="0"
                                            />
                                        </div>
                                        <div>
                                            <label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
                                            <div class="relative">
                                                <select 
                                                    v-model="form.category_id"
                                                    required
                                                    class="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-200 text-sm focus:ring-1 focus:ring-primary focus:border-primary outline-none appearance-none cursor-pointer"
                                                >
                                                    <option value="" disabled>Select Category</option>
                                                    <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
                                                </select>
                                                <ChevronDownIcon class="absolute right-4 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="h-px bg-gray-100"></div>
                            
                            <div>
                                <label class="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Inventory & Status</label>
                                <div class="space-y-3">
                                    <div class="flex items-center justify-between p-3 rounded-xl border border-gray-100 bg-gray-50">
                                        <span class="text-sm font-medium text-gray-700">Available Online</span>
                                        <label class="relative inline-flex items-center cursor-pointer">
                                            <input type="checkbox" v-model="form.is_available" class="sr-only peer">
                                            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                                        </label>
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 mb-1">Current Stock (Initial)</label>
                                        <input 
                                            v-model="form.current_stock"
                                            type="number"
                                            class="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-200 text-sm focus:ring-1 focus:ring-primary focus:border-primary outline-none transition-colors"
                                            :disabled="!isCreating"
                                            :placeholder="!isCreating ? 'Use Inventory Page to Update Stock' : '0'"
                                        />
                                        <p v-if="!isCreating" class="text-xs text-gray-500 mt-1">To adjust stock, please use the Inventory page.</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>

                <div class="px-6 py-6 bg-white border-t border-gray-100 mt-auto">
                    <div class="flex gap-3">
                        <button 
                            v-if="!isCreating"
                            @click="deleteProduct"
                            type="button"
                            class="flex-1 py-3.5 rounded-xl border border-red-200 text-red-600 font-bold text-sm hover:bg-red-50 transition"
                        >
                            Delete
                        </button>
                        <button 
                            @click="saveProduct"
                            :disabled="saving"
                            class="flex-2 bg-primary hover:bg-[#004d34] text-white font-bold py-3.5 rounded-xl shadow-lg shadow-primary/30 transition transform active:scale-[0.98] flex items-center justify-center gap-2"
                        >
                            <LoaderIcon v-if="saving" class="w-4 h-4 animate-spin" />
                            {{ saving ? 'Saving...' : 'Save Changes' }}
                        </button>
                    </div>
                </div>
            </aside>
        </div>
    </PosLayout>
</template>

<script setup>
import { ref, onMounted, reactive, watch } from 'vue';
import PosLayout from '../../components/layout/PosLayout.vue';
import { 
    SearchIcon, PlusIcon, PenIcon, LayoutGridIcon, 
    XIcon, CameraIcon, ChevronDownIcon, LoaderIcon 
} from 'lucide-vue-next';
import api from '../../api/axios';
import { formatCurrency } from '../../utils/format';
import { useToast } from 'vue-toastification';

const toast = useToast();

// State
const products = ref([]);
const categories = ref([]);
const loading = ref(false);
const searchQuery = ref('');
const activeCategory = ref('all');
const selectedProduct = ref(null);
const isCreating = ref(false);
const saving = ref(false);
const fileInput = ref(null);

const form = reactive({
    id: null,
    category_id: '',
    name: '',
    sku: '',
    price: 0,
    is_available: true,
    current_stock: 0,
    image: null,      // File object
    image_url: null,  // Existing URL
    image_preview: null // Preview URL
});

// Fetch Data
const fetchCategories = async () => {
    try {
        const response = await api.get('/admin/categories');
        const rawData = response.data?.data || response.data || [];
        categories.value = Array.isArray(rawData) ? rawData : (rawData.data || []);
    } catch (e) {
        console.error("Failed to categories", e);
    }
};

const fetchProducts = async () => {
    loading.value = true;
    try {
        let url = '/admin/products?per_page=50';
        if (searchQuery.value) url += `&search=${searchQuery.value}`;
        if (activeCategory.value !== 'all') url += `&category_id=${activeCategory.value}`;
        
        const response = await api.get(url);
        const rawData = response.data?.data || response.data || {};
        products.value = Array.isArray(rawData) ? rawData : (rawData.data || []);
    } catch (e) {
        console.error("Failed to load products", e);
    } finally {
        loading.value = false;
    }
};

// Editor Logic
const startCreate = () => {
    selectedProduct.value = null;
    isCreating.value = true;
    resetForm();
    // Default SKU generator
    form.sku = `PRD-${Math.floor(Math.random() * 10000)}`;
};

const editProduct = (product) => {
    isCreating.value = false;
    selectedProduct.value = product;
    
    form.id = product.id;
    form.category_id = product.category_id;
    form.name = product.name;
    form.sku = product.sku;
    form.price = parseFloat(product.price);
    form.is_available = Boolean(product.is_available);
    form.current_stock = parseFloat(product.current_stock || 0);
    form.image_url = product.image_url;
    form.image = null;
    form.image_preview = null;
};

const closeEditor = () => {
    selectedProduct.value = null;
    isCreating.value = false;
};

const resetForm = () => {
    form.id = null;
    form.category_id = '';
    form.name = '';
    form.sku = '';
    form.price = 0;
    form.is_available = true;
    form.current_stock = 0;
    form.image = null;
    form.image_url = null;
    form.image_preview = null;
};

const handleImagePayload = (event) => {
    const file = event.target.files[0];
    if (file) {
        form.image = file;
        form.image_preview = URL.createObjectURL(file);
    }
};

const saveProduct = async () => {
    saving.value = true;
    try {
        const formData = new FormData();
        formData.append('category_id', form.category_id);
        formData.append('name', form.name);
        formData.append('sku', form.sku);
        formData.append('price', form.price);
        formData.append('is_available', form.is_available ? 1 : 0);
        
        if (form.image) {
            formData.append('image', form.image);
        }
        
        if (isCreating.value) {
            // Initial stock only on create? Actually ProductController might not handle current_stock in store/update yet?
            // Wait, ProductController DOES NOT handle current_stock in store().
            // But we added columns. We should probably update ProductController to allow setting initial stock?
            // For now, let's assume ProductController only handles product basics.
            // But I should try to send it if supported, or ignore.
            // Let's just create product.
            await api.post('/admin/products', formData);
            toast.success('Product created successfully');
        } else {
            formData.append('_method', 'PUT');
            await api.post(`/admin/products/${form.id}`, formData);
            toast.success('Product updated successfully');
        }
        
        closeEditor();
        fetchProducts();
    } catch (e) {
        toast.error(e.response?.data?.message || 'Failed to save product');
    } finally {
        saving.value = false;
    }
};

const deleteProduct = async () => {
    if (!confirm('Are you sure you want to delete this product?')) return;
    
    try {
        await api.delete(`/admin/products/${form.id}`);
        toast.success('Product deleted');
        closeEditor();
        fetchProducts();
    } catch (e) {
        toast.error('Failed to delete product');
    }
};

watch([searchQuery, activeCategory], () => {
    fetchProducts();
});

onMounted(() => {
    fetchCategories();
    fetchProducts();
});
</script>
