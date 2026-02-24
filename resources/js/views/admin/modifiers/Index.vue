<template>
    <MainLayout :loading="pageLoading">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-slate-800">Modifier Management</h1>
            <button @click="openModal()" class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-sm">
                <PlusIcon class="w-5 h-5 mr-2" />
                Add Modifier
            </button>
        </div>

        <!-- Modifier List -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
            <table class="w-full text-left">
                <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                    <tr>
                        <th class="px-6 py-4 font-semibold">Name</th>
                        <th class="px-6 py-4 font-semibold">Type</th>
                        <th class="px-6 py-4 font-semibold">Options</th>
                        <th class="px-6 py-4 font-semibold">Required</th>
                        <th class="px-6 py-4 font-semibold text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    <tr v-for="modifier in (modifiers || []).filter(m => m != null)" :key="modifier.id" class="hover:bg-gray-50 transition-colors group">
                        <td class="px-6 py-5 font-bold text-slate-800 text-base">{{ modifier.name }}</td>
                        <td class="px-6 py-5">
                            <span :class="modifier.type === 'radio' ? 'bg-blue-100 text-blue-700' : 'bg-purple-100 text-purple-700'" class="px-2.5 py-1 rounded-full text-xs font-bold">
                                {{ modifier.type === 'radio' ? 'Single Select' : 'Multi Select' }}
                            </span>
                        </td>
                        <td class="px-6 py-5 text-gray-500">
                            <div class="flex flex-wrap gap-1">
                                <span v-for="opt in modifier.options" :key="opt.id" class="bg-gray-100 px-2 py-0.5 rounded text-xs">
                                    {{ opt.name }} <span v-if="parseFloat(opt.price) > 0" class="text-green-600">(+{{ formatNumber(opt.price) }})</span>
                                </span>
                            </div>
                        </td>
                        <td class="px-6 py-5">
                            <span :class="modifier.is_required ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'" class="px-2.5 py-1 rounded-full text-xs font-bold">
                                {{ modifier.is_required ? 'Required' : 'Optional' }}
                            </span>
                        </td>
                        <td class="px-6 py-5 text-right space-x-2">
                            <div class="flex items-center justify-end space-x-3">
                                <button @click="openModal(modifier)" class="text-blue-400 hover:text-blue-600 transition-colors p-1 rounded-lg hover:bg-blue-50" title="Edit">
                                    <PencilIcon class="w-5 h-5" />
                                </button>
                                <button @click="deleteModifier(modifier.id)" class="text-red-400 hover:text-red-600 transition-colors p-1 rounded-lg hover:bg-red-50" title="Delete">
                                    <TrashIcon class="w-5 h-5" />
                                </button>
                            </div>
                        </td>
                    </tr>
                    <tr v-if="modifiers.length === 0">
                        <td colspan="5" class="px-6 py-12 text-center text-gray-400 bg-gray-50/50">
                            <div class="flex flex-col items-center justify-center">
                                <p class="text-lg font-medium text-gray-500">No modifiers found</p>
                                <p class="text-sm">Click "Add Modifier" to create one (e.g., Size, Toppings)</p>
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
            <div class="bg-white rounded-2xl shadow-xl w-full max-w-xl relative z-10 p-6 max-h-[90vh] overflow-y-auto">
                <h2 class="text-xl font-bold mb-4">{{ isEditing ? 'Edit Modifier' : 'New Modifier' }}</h2>
                
                <form @submit.prevent="saveModifier" class="space-y-5">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Modifier Name</label>
                        <input v-model="form.name" type="text" required placeholder="e.g., Size, Topping, Ice Level" class="w-full border border-gray-300 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>
                    
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Type</label>
                            <select v-model="form.type" class="w-full border border-gray-300 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary py-3 px-4">
                                <option value="radio">Single Select (Radio)</option>
                                <option value="checkbox">Multi Select (Checkbox)</option>
                            </select>
                        </div>
                        <div class="flex items-end">
                            <label class="flex items-center cursor-pointer">
                                <input v-model="form.is_required" type="checkbox" class="text-primary focus:ring-primary rounded border-gray-300 mr-2">
                                <span class="text-sm text-gray-700">Required</span>
                            </label>
                        </div>
                    </div>

                    <!-- Options -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Options</label>
                        <div class="space-y-3">
                            <div v-for="(opt, index) in form.options" :key="index" class="p-4 bg-gray-50 rounded-xl border border-gray-200 relative group">
                                <button type="button" @click="removeOption(index)" class="absolute top-2 right-2 text-gray-400 hover:text-red-500 p-1" :disabled="form.options.length <= 1">
                                    <XIcon class="w-4 h-4" />
                                </button>
                                
                                <div class="grid grid-cols-12 gap-3">
                                    <div class="col-span-12 md:col-span-5">
                                        <label class="block text-xs font-medium text-gray-500 mb-1">Name</label>
                                        <input v-model="opt.name" type="text" required placeholder="Option Name" class="w-full border border-gray-300 rounded-lg bg-white py-2 px-3 text-sm focus:ring-primary focus:border-primary">
                                    </div>
                                    <div class="col-span-12 md:col-span-4">
                                        <label class="block text-xs font-medium text-gray-500 mb-1">Price</label>
                                        <div class="relative">
                                            <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">Rp</span>
                                            <input v-model.number="opt.price" type="number" min="0" step="1000" placeholder="0" class="w-full border border-gray-300 rounded-lg bg-white py-2 pl-9 pr-3 text-sm focus:ring-primary focus:border-primary">
                                        </div>
                                    </div>
                                    <div class="col-span-12 md:col-span-3">
                                        <label class="block text-xs font-medium text-gray-500 mb-1">Icon (Lucide)</label>
                                        <input v-model="opt.icon" type="text" placeholder="e.g. coffee" class="w-full border border-gray-300 rounded-lg bg-white py-2 px-3 text-sm focus:ring-primary focus:border-primary">
                                    </div>
                                    
                                    <div class="col-span-6">
                                        <label class="block text-xs font-medium text-gray-500 mb-1">Name Prefix</label>
                                        <input v-model="opt.name_prefix" type="text" placeholder="e.g. Iced " class="w-full border border-gray-300 rounded-lg bg-white py-2 px-3 text-sm focus:ring-primary focus:border-primary">
                                    </div>
                                    <div class="col-span-6">
                                        <label class="block text-xs font-medium text-gray-500 mb-1">Name Suffix</label>
                                        <input v-model="opt.name_suffix" type="text" placeholder="Suffix" class="w-full border border-gray-300 rounded-lg bg-white py-2 px-3 text-sm focus:ring-primary focus:border-primary">
                                    </div>
                                </div>
                            </div>
                        </div>
                        <button type="button" @click="addOption" class="mt-2 text-primary hover:text-green-700 text-sm font-medium flex items-center">
                            <PlusIcon class="w-4 h-4 mr-1" /> Add Option
                        </button>
                    </div>

                    <div class="flex justify-end space-x-3 mt-6 pt-4 border-t">
                        <button type="button" @click="closeModal" class="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg">Cancel</button>
                        <button type="submit" class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-green-800 disabled:opacity-50" :disabled="loading">
                            {{ loading ? 'Saving...' : 'Save Modifier' }}
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
import { PlusIcon, PencilIcon, TrashIcon, XIcon } from 'lucide-vue-next';
import api from '../../../api/axios';
import { useToast } from "vue-toastification";

const toast = useToast();

const modifiers = ref([]);
const showModal = ref(false);
const isEditing = ref(false);
const loading = ref(false);
const pageLoading = ref(true);
const editId = ref(null);

const form = reactive({
    name: '',
    type: 'radio',
    is_required: false,
    options: [{ name: '', price: 0 }]
});

const formatNumber = (num) => new Intl.NumberFormat('id-ID').format(num);

const fetchModifiers = async () => {
    if (modifiers.value.length === 0) pageLoading.value = true;
    
    try {
        const response = await api.get('/admin/modifiers');
        const rawData = response.data?.data || response.data || [];
        modifiers.value = Array.isArray(rawData) ? rawData : [];
    } catch (error) {
        console.error('Error fetching modifiers:', error);
        toast.error('Failed to load modifiers');
    } finally {
        pageLoading.value = false;
    }
};

const openModal = (modifier = null) => {
    if (modifier) {
        isEditing.value = true;
        editId.value = modifier.id;
        form.name = modifier.name;
        form.type = modifier.type;
        form.is_required = !!modifier.is_required;
        form.options = modifier.options.map(o => ({ 
            id: o.id, 
            name: o.name, 
            price: parseFloat(o.price) || 0,
            name_prefix: o.name_prefix || '',
            name_suffix: o.name_suffix || '',
            icon: o.icon || ''
        }));
        if (form.options.length === 0) form.options = [{ name: '', price: 0, name_prefix: '', name_suffix: '', icon: '' }];
    } else {
        isEditing.value = false;
        editId.value = null;
        form.name = '';
        form.type = 'radio';
        form.is_required = false;
        form.options = [{ name: '', price: 0, name_prefix: '', name_suffix: '', icon: '' }];
    }
    showModal.value = true;
};

const closeModal = () => {
    showModal.value = false;
};

const addOption = () => {
    form.options.push({ name: '', price: 0, name_prefix: '', name_suffix: '', icon: '' });
};

const removeOption = (index) => {
    if (form.options.length > 1) {
        form.options.splice(index, 1);
    }
};

const saveModifier = async () => {
    // Validate at least one option with name
    const validOptions = form.options.filter(o => o.name.trim());
    if (validOptions.length === 0) {
        toast.error('Please add at least one option');
        return;
    }
    
    loading.value = true;
    try {
        const payload = {
            name: form.name,
            type: form.type,
            is_required: form.is_required,
            options: validOptions
        };
        
        if (isEditing.value) {
            await api.put(`/admin/modifiers/${editId.value}`, payload);
            toast.success("Modifier updated successfully!");
        } else {
            await api.post('/admin/modifiers', payload);
            toast.success("Modifier created successfully!");
        }
        await fetchModifiers();
        closeModal();
    } catch (error) {
        toast.error(error.response?.data?.message || 'Failed to save modifier');
    } finally {
        loading.value = false;
    }
};

const deleteModifier = async (id) => {
    if (!confirm('Are you sure you want to delete this modifier?')) return;
    
    try {
        await api.delete(`/admin/modifiers/${id}`);
        toast.success("Modifier deleted successfully!");
        await fetchModifiers();
    } catch (error) {
        toast.error(error.response?.data?.message || 'Failed to delete modifier');
    }
};

onMounted(() => {
    fetchModifiers();
});
</script>
