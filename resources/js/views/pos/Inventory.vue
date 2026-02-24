<template>
    <PosLayout>
        <div class="flex flex-col lg:flex-row h-full overflow-hidden relative">
            <!-- Main Content (Inventory List) -->
            <div 
                class="flex-1 flex flex-col h-full relative overflow-hidden transition-all duration-300 ease-in-out"
                :class="{ 'lg:mr-[400px]': selectedItem }"
            >
                <!-- Header (Search) -->
                <div class="px-6 py-4 shrink-0 bg-white border-b border-gray-100">
                    <h2 class="text-2xl font-bold text-gray-900 mb-4">Inventory Management</h2>
                    <div class="relative">
                        <SearchIcon class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                        <input 
                            v-model="searchQuery"
                            type="text"
                            class="w-full pl-12 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none shadow-sm text-sm transition-colors" 
                            placeholder="Search inventory by name, SKU..." 
                        />
                    </div>
                </div>

                <!-- Filters -->
                <div class="px-6 py-4 shrink-0 overflow-x-auto no-scrollbar bg-white/50 border-b border-gray-50">
                    <div class="flex space-x-3">
                        <button 
                            @click="activeFilter = 'all'"
                            class="px-5 py-2 rounded-full text-sm font-medium shadow-sm whitespace-nowrap transition border"
                            :class="activeFilter === 'all' 
                                ? 'bg-primary text-white border-transparent shadow-primary/20' 
                                : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'"
                        >
                            All Items
                        </button>
                        <button 
                            @click="activeFilter = 'low_stock'"
                            class="px-5 py-2 rounded-full text-sm font-medium shadow-sm whitespace-nowrap transition border flex items-center gap-2"
                            :class="activeFilter === 'low_stock' 
                                ? 'bg-primary text-white border-transparent shadow-primary/20' 
                                : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'"
                        >
                            <span class="w-2 h-2 rounded-full" :class="activeFilter === 'low_stock' ? 'bg-white' : 'bg-red-500'"></span>
                            Low Stock
                        </button>
                    </div>
                </div>

                <!-- Item Grid -->
                <div class="flex-1 overflow-y-auto px-6 py-6 pb-24 lg:pb-6 bg-gray-50">
                    <div v-if="loading" class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 animate-pulse">
                        <div v-for="i in 8" :key="i" class="bg-white p-3 rounded-2xl shadow-sm h-64"></div>
                    </div>
                    
                    <div v-else-if="items.length > 0" class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
                        <div 
                            v-for="item in items" 
                            :key="item.id"
                            @click="selectItem(item)"
                            class="bg-white p-3 rounded-2xl shadow-sm border transition group cursor-pointer flex flex-col h-full relative"
                            :class="selectedItem?.id === item.id ? 'border-primary ring-2 ring-primary ring-opacity-100' : 'border-transparent hover:border-gray-200'"
                        >
                            <div class="absolute top-3 right-3 z-10">
                                <span 
                                    v-if="item.current_stock <= item.minimum_stock_alert && item.current_stock > 0"
                                    class="bg-orange-100 text-orange-700 text-[10px] font-bold px-2 py-0.5 rounded-full border border-orange-200 flex items-center gap-1"
                                >
                                    <span class="w-1.5 h-1.5 rounded-full bg-orange-500 animate-pulse"></span> Low
                                </span>
                                <span 
                                    v-else-if="item.current_stock <= 0"
                                    class="bg-red-100 text-red-700 text-[10px] font-bold px-2 py-0.5 rounded-full border border-red-200"
                                >
                                    Out
                                </span>
                                <span 
                                    v-else
                                    class="bg-green-100 text-green-700 text-[10px] font-bold px-2 py-0.5 rounded-full border border-green-200"
                                >
                                    In Stock
                                </span>
                            </div>

                            <div class="relative aspect-4/3 rounded-xl overflow-hidden mb-3 bg-gray-100">
                                <img 
                                    :src="item.image_url || '/no-image.jpg'" 
                                    class="w-full h-full object-cover group-hover:scale-105 transition duration-300" 
                                    :class="{'grayscale opacity-70': item.current_stock <= 0}"
                                    @error="$event.target.src = '/no-image.jpg'"
                                />
                            </div>
                            
                            <h3 class="font-bold text-gray-800 text-sm mb-0.5 line-clamp-1">{{ item.name }}</h3>
                            <p class="text-xs text-gray-400 mb-3">SKU: {{ item.sku }}</p>
                            
                            <div class="mt-auto flex justify-between items-end border-t border-gray-100 pt-3">
                                <div>
                                    <p class="text-[10px] text-gray-400 uppercase font-bold">Stock</p>
                                    <p 
                                        class="text-lg font-bold"
                                        :class="item.current_stock <= item.minimum_stock_alert ? 'text-red-500' : 'text-primary'"
                                    >
                                        {{ parseFloat(item.current_stock) }}
                                    </p>
                                </div>
                                <div>
                                    <p class="text-[10px] text-gray-400 uppercase font-bold text-right">Price</p>
                                    <p class="text-sm font-medium text-gray-600">{{ formatCurrency(item.price) }}</p>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div v-else class="flex flex-col items-center justify-center h-64 text-gray-400">
                         <PackageIcon class="w-12 h-12 mb-2 text-gray-300" />
                         <p>No inventory items found</p>
                    </div>
                </div>
            </div>

            <!-- Detail Sidebar (Edit Stock) -->
            <aside 
                v-if="selectedItem"
                class="absolute inset-y-0 right-0 w-full lg:w-[400px] bg-white shadow-2xl z-20 flex flex-col border-l border-gray-100 shrink-0 transform transition-transform duration-300"
            >
                <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-white">
                    <h2 class="text-lg font-bold text-gray-900">Edit Stock</h2>
                    <div class="flex items-center gap-3">
                         <button @click="selectedItem = null" class="p-1 rounded-full hover:bg-gray-100 text-gray-500">
                            <XIcon class="w-5 h-5" />
                        </button>
                    </div>
                </div>

                <div class="flex-1 overflow-y-auto px-6 py-6 space-y-6">
                    <!-- Item Header -->
                    <div class="flex gap-4 items-start">
                        <div class="w-20 h-20 rounded-2xl overflow-hidden bg-gray-100 shadow-sm shrink-0 border border-gray-100">
                            <img :src="selectedItem.image_url || '/no-image.jpg'" class="w-full h-full object-cover" @error="$event.target.src = '/no-image.jpg'" />
                        </div>
                        <div>
                            <div class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-primary/10 text-primary text-[10px] font-bold mb-1">
                                <span class="w-1.5 h-1.5 rounded-full bg-primary"></span> 
                                {{ editForm.is_available ? 'Active' : 'Inactive' }}
                            </div>
                            <h3 class="text-lg font-bold text-gray-900 leading-tight">{{ selectedItem.name }}</h3>
                            <p class="text-sm text-gray-500 mt-1">SKU: {{ selectedItem.sku }}</p>
                        </div>
                    </div>

                    <!-- Stock Counter -->
                    <div class="bg-gray-50 p-5 rounded-2xl border border-gray-100">
                        <label class="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-3">Current Stock Level</label>
                        <div class="flex items-center justify-between gap-4">
                            <button 
                                @click="adjustStock(-1)"
                                class="w-12 h-12 rounded-xl bg-white border border-gray-200 text-gray-600 flex items-center justify-center hover:bg-gray-50 active:scale-95 transition shadow-sm"
                            >
                                <MinusIcon class="w-6 h-6" />
                            </button>
                            <div class="flex-1 text-center">
                                <input 
                                    v-model.number="editForm.current_stock"
                                    type="number"
                                    class="text-3xl font-bold text-gray-900 tracking-tight text-center bg-transparent border-none focus:ring-0 w-full p-0"
                                />
                                <p class="text-xs text-gray-400 mt-0.5">units</p>
                            </div>
                            <button 
                                @click="adjustStock(1)"
                                class="w-12 h-12 rounded-xl bg-primary text-white border border-primary flex items-center justify-center hover:bg-[#004d34] active:scale-95 transition shadow-lg shadow-primary/20"
                            >
                                <PlusIcon class="w-6 h-6" />
                            </button>
                        </div>
                    </div>

                    <!-- Settings -->
                    <div class="space-y-5">
                        <div>
                            <div class="flex justify-between mb-2">
                                <label class="text-sm font-medium text-gray-700">Low Stock Alert</label>
                                <span class="text-sm font-bold text-gray-900">{{ editForm.minimum_stock_alert }} units</span>
                            </div>
                            <input 
                                v-model.number="editForm.minimum_stock_alert"
                                class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-primary" 
                                max="100" 
                                min="0" 
                                type="range"
                            />
                            <p class="text-xs text-gray-500 mt-2">Alert triggers when stock falls below this value.</p>
                        </div>
                        
                        <div class="flex items-center justify-between py-2">
                             <div class="flex flex-col">
                                <span class="text-sm font-medium text-gray-700">Available on Menu</span>
                                <span class="text-xs text-gray-500">Show or hide from POS</span>
                            </div>
                            <label class="relative inline-flex items-center cursor-pointer">
                                <input type="checkbox" v-model="editForm.is_available" class="sr-only peer">
                                <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                            </label>
                        </div>
                        
                        <div>
                             <label class="text-sm font-medium text-gray-700 block mb-2">Update Reason (Optional)</label>
                             <input 
                                v-model="editForm.reason"
                                type="text"
                                placeholder="e.g. Restock, Spoilage, Correction"
                                class="w-full px-4 py-2 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
                             />
                        </div>
                    </div>
                </div>

                <!-- Footer (Save) -->
                <div class="px-6 py-6 bg-white border-t border-gray-100 mt-auto">
                    <button 
                        @click="saveChanges"
                        :disabled="saving"
                        class="w-full bg-primary hover:bg-[#004d34] text-white font-bold py-3.5 rounded-2xl shadow-lg shadow-primary/30 transition transform active:scale-[0.98] flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        <SaveIcon v-if="!saving" class="w-5 h-5" />
                        <LoaderIcon v-else class="w-5 h-5 animate-spin" />
                        <span>{{ saving ? 'Saving...' : 'Save Changes' }}</span>
                    </button>
                </div>
            </aside>
        </div>
    </PosLayout>
</template>

<script setup>
import { ref, onMounted, watch, reactive } from 'vue';
import PosLayout from '../../components/layout/PosLayout.vue';
import { 
    SearchIcon, PackageIcon, MinusIcon, PlusIcon, 
    SaveIcon, XIcon, LoaderIcon 
} from 'lucide-vue-next';
import api from '../../api/axios';
import { formatCurrency } from '../../utils/format';
import { useAuthStore } from '../../stores/auth';
import { useToast } from 'vue-toastification';

const authStore = useAuthStore();
const toast = useToast();

const items = ref([]);
const loading = ref(false);
const searchQuery = ref('');
const activeFilter = ref('all');
const selectedItem = ref(null);
const saving = ref(false);

const editForm = reactive({
    current_stock: 0,
    minimum_stock_alert: 0,
    is_available: true,
    reason: ''
});

const fetchInventory = async () => {
    loading.value = true;
    try {
        let url = '/admin/pos/inventory?per_page=50';
        if (searchQuery.value) {
            url += `&search=${searchQuery.value}`;
        }
        if (activeFilter.value === 'low_stock') {
            url += `&low_stock=true`;
        }
        
        const response = await api.get(url);
        const rawData = response.data?.data || response.data || [];
        items.value = Array.isArray(rawData) ? rawData : (rawData.data || []);
    } catch (e) {
        console.error("Failed to load inventory", e);
    } finally {
        loading.value = false;
    }
};

const selectItem = (item) => {
    selectedItem.value = item;
    editForm.current_stock = parseFloat(item.current_stock);
    editForm.minimum_stock_alert = parseFloat(item.minimum_stock_alert);
    editForm.is_available = Boolean(item.is_available);
    editForm.reason = '';
};

const adjustStock = (amount) => {
    editForm.current_stock = Math.max(0, editForm.current_stock + amount);
};

const saveChanges = async () => {
    if (!selectedItem.value) return;
    
    saving.value = true;
    try {
        const response = await api.put(`/admin/pos/inventory/${selectedItem.value.id}`, {
            current_stock: editForm.current_stock,
            minimum_stock_alert: editForm.minimum_stock_alert,
            is_available: editForm.is_available,
            reason: editForm.reason
        });
        
        // Update local item
        const index = items.value.findIndex(i => i.id === selectedItem.value.id);
        if (index !== -1) {
            const updatedItem = response.data?.data || response.data || {};
            items.value[index] = { ...items.value[index], ...updatedItem };
        }
        
        toast.success('Inventory updated successfully');
        selectedItem.value = null; // Close sidebar
    } catch (e) {
        toast.error(e.response?.data?.message || 'Failed to update inventory');
    } finally {
        saving.value = false;
    }
};

watch([searchQuery, activeFilter], () => {
    fetchInventory();
});

onMounted(() => {
    fetchInventory();
});
</script>
