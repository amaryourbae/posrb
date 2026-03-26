<template>
    <MainLayout>
        <div class="mb-6">
             <button @click="$router.back()" class="text-gray-500 hover:text-gray-800 flex items-center mb-4">
                &larr; Back to Products
            </button>
            <h1 class="text-2xl font-bold text-slate-800">{{ isEditing ? 'Edit Product' : 'Create New Product' }}</h1>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-8 max-w-4xl">
            <!-- Tabs -->
            <div class="flex border-b border-gray-100 mb-6">
                <button 
                    @click="activeTab = 'general'"
                    class="px-6 py-2 pb-3 font-medium text-sm transition-colors border-b-2"
                    :class="activeTab === 'general' ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-gray-700'"
                >
                    General Information
                </button>
                <button 
                    v-if="isEditing" 
                    @click="activeTab = 'recipe'"
                    class="px-6 py-2 pb-3 font-medium text-sm transition-colors border-b-2"
                    :class="activeTab === 'recipe' ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-gray-700'"
                >
                    Recipe & Costing
                </button>
                <button 
                    v-else
                    disabled
                    class="px-6 py-2 pb-3 font-medium text-sm text-gray-300 cursor-not-allowed"
                    title="Save product first to add recipe"
                >
                    Recipe & Costing
                </button>
                <button 
                    v-if="isEditing" 
                    @click="activeTab = 'modifiers'"
                    class="px-6 py-2 pb-3 font-medium text-sm transition-colors border-b-2"
                    :class="activeTab === 'modifiers' ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-gray-700'"
                >
                    Modifiers
                </button>
                <button 
                    v-else
                    disabled
                    class="px-6 py-2 pb-3 font-medium text-sm text-gray-300 cursor-not-allowed"
                    title="Save product first to assign modifiers"
                >
                    Modifiers
                </button>
            </div>

            <!-- General Tab -->
            <form v-show="activeTab === 'general'" @submit.prevent="submitForm" class="space-y-6">
                <!-- Image Upload -->
                <div>
                     <label class="block text-sm font-medium text-gray-700 mb-2">Product Image</label>
                     <div class="flex items-center space-x-4">
                        <div class="relative h-24 w-24 rounded-lg bg-gray-100 border border-gray-200 flex items-center justify-center overflow-hidden group">
                            <img v-if="previewImage" :src="previewImage" class="h-full w-full object-cover">
                            <img v-else src="/no-image.jpg" class="h-full w-full object-cover opacity-50">
                            <button 
                                v-if="previewImage && isEditing" 
                                type="button"
                                @click="deleteImage" 
                                class="absolute inset-0 bg-black/50 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
                                title="Delete Image"
                            >
                                <TrashIcon class="w-5 h-5" />
                            </button>
                        </div>
                        <div class="flex-1">
                            <input 
                                type="file" 
                                @change="handleImageUpload" 
                                accept="image/*"
                                class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-primary/10 file:text-primary hover:file:bg-primary/20"
                            />
                            <button 
                                v-if="previewImage && isEditing" 
                                type="button" 
                                @click="deleteImage" 
                                class="mt-2 text-xs text-red-500 hover:text-red-700 font-medium flex items-center"
                            >
                                <TrashIcon class="w-3 h-3 mr-1" /> Remove Image
                            </button>
                        </div>
                     </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Product Name</label>
                        <input v-model="form.name" type="text" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">SKU</label>
                        <input v-model="form.sku" type="text" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                     <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
                        <select v-model="form.category_id" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                            <option value="" disabled>Select Category</option>
                            <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Price (IDR)</label>
                        <input v-model="form.price" type="number" min="0" required class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                    </div>
                </div>

                <!-- Sales Type Pricing -->
                <div class="bg-gray-50 p-6 rounded-xl border border-gray-200">
                    <h3 class="text-sm font-bold text-gray-800 mb-4 flex items-center">
                        <span class="bg-primary/10 text-primary p-1 rounded mr-2">
                             <PlusIcon class="w-4 h-4" />
                        </span>
                        Pricing by Sales Type (Optional)
                    </h3>
                    <div class="space-y-4">
                        <div v-for="type in activeSalesTypes" :key="type.id" class="flex items-center space-x-4">
                            <div class="w-1/3">
                                <span class="text-sm font-medium text-gray-700">{{ type.name }}</span>
                                <p class="text-[10px] text-gray-400">Slug: {{ type.slug }}</p>
                            </div>
                            <div class="flex-1 relative">
                                <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xs font-bold">Rp</span>
                                <input 
                                    v-model="salePrices[type.id]" 
                                    type="number" 
                                    min="0" 
                                    placeholder="Use base price"
                                    class="w-full border border-gray-300 rounded-lg bg-white focus:ring-primary focus:border-primary py-2 pl-9 pr-4 text-sm"
                                >
                            </div>
                        </div>
                        <p v-if="activeSalesTypes.length === 0" class="text-xs text-gray-400 italic">No additional sales types configured.</p>
                    </div>
                    <p class="mt-4 text-[10px] text-gray-500 italic">Leave empty to use the standard Base Price for that sales type.</p>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
                    <textarea v-model="form.description" rows="3" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4"></textarea>
                </div>

                <div class="flex items-center space-x-6">
                    <div class="flex items-center">
                        <input v-model="form.is_available" type="checkbox" id="is_available" class="text-primary focus:ring-primary rounded border-gray-300">
                        <label for="is_available" class="ml-2 text-sm text-gray-700">Available for Sale</label>
                    </div>
                    <div class="flex items-center">
                        <input v-model="form.is_recommended" type="checkbox" id="is_recommended" class="text-primary focus:ring-primary rounded border-gray-300">
                        <label for="is_recommended" class="ml-2 text-sm text-gray-700">Recommended Product</label>
                    </div>
                    <div class="flex items-center">
                        <input v-model="form.is_upsell" type="checkbox" id="is_upsell" class="text-primary focus:ring-primary rounded border-gray-300">
                        <label for="is_upsell" class="ml-2 text-sm text-gray-700">Upsell in Checkout</label>
                    </div>
                </div>

                <div class="flex justify-end pt-4 border-t border-gray-100">
                     <button type="submit" :disabled="loading" class="bg-primary hover:bg-green-800 text-white px-6 py-2 rounded-lg font-bold transition-colors disabled:opacity-50 flex items-center">
                        {{ loading ? 'Saving...' : 'Save Product' }}
                     </button>
                </div>
            </form>

            <!-- Recipe Tab -->
            <div v-show="activeTab === 'recipe'" class="space-y-6">
                <div class="flex justify-between items-center mb-4">
                    <h3 class="text-lg font-bold text-gray-800">Ingredients</h3>
                    <button @click="addIngredientRow" class="text-primary hover:text-green-700 text-sm font-bold flex items-center">
                        <PlusIcon class="w-4 h-4 mr-1"/> Add Ingredient
                    </button>
                </div>

                <div v-if="recipeList.length === 0" class="text-center py-8 text-gray-400 bg-gray-50 rounded-lg border border-dashed border-gray-200">
                    No ingredients linked. Add ingredients to calculate HPP.
                </div>

                <div v-else class="space-y-3">
                    <div v-for="(item, index) in recipeList" :key="index" class="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg border border-gray-200">
                        <div class="flex-1">
                             <select v-model="item.ingredient_id" class="w-full text-sm border-gray-300 rounded-md focus:ring-primary focus:border-primary">
                                <option value="" disabled>Select Ingredient</option>
                                <option v-for="ing in ingredients" :key="ing.id" :value="ing.id">
                                    {{ ing.name }} ({{ ing.unit ? ing.unit.abbreviation : '-' }}) - Cost: {{ formatCurrency(ing.cost_per_unit) }}
                                </option>
                            </select>
                        </div>
                        <div class="w-32">
                             <input v-model="item.quantity_needed" type="number" step="0.0001" placeholder="Qty" class="w-full text-sm border-gray-300 rounded-md focus:ring-primary focus:border-primary">
                        </div>
                         <div class="text-sm text-gray-500 w-12">
                             {{ getUnit(item.ingredient_id) }}
                        </div>
                         <div class="w-32 text-right font-medium text-slate-700">
                             {{ formatCurrency(calculateCost(item)) }}
                        </div>
                        <button @click="removeIngredientRow(index)" class="text-red-500 hover:text-red-700">
                            <TrashIcon class="w-4 h-4" />
                        </button>
                    </div>
                </div>

                 <div class="border-t border-gray-100 pt-4 bg-green-50 p-4 rounded-lg space-y-3">
                    <div class="flex justify-between items-center">
                        <span class="font-bold text-gray-700">Estimated HPP (Cost of Goods):</span>
                        <span class="text-xl font-bold text-green-700">{{ formatCurrency(totalHpp) }}</span>
                    </div>
                    <div class="flex justify-between items-center">
                        <span class="font-bold text-gray-700">Harga Jual (Selling Price):</span>
                        <span class="text-xl font-bold text-slate-700">{{ formatCurrency(form.price || 0) }}</span>
                    </div>
                    <div class="border-t border-green-200 pt-3 flex justify-between items-center">
                        <span class="font-bold text-gray-700">Margin:</span>
                        <div class="text-right">
                            <span 
                                class="text-xl font-bold"
                                :class="{
                                    'text-green-700': marginPercent >= 40,
                                    'text-yellow-600': marginPercent >= 20 && marginPercent < 40,
                                    'text-red-600': marginPercent < 20
                                }"
                            >
                                {{ marginPercent !== null ? marginPercent.toFixed(1) + '%' : '-' }}
                            </span>
                            <span v-if="marginPercent !== null" class="block text-xs mt-0.5"
                                :class="{
                                    'text-green-600': marginPercent >= 40,
                                    'text-yellow-500': marginPercent >= 20 && marginPercent < 40,
                                    'text-red-500': marginPercent < 20
                                }"
                            >
                                {{ marginPercent >= 40 ? 'Margin sehat ✓' : marginPercent >= 20 ? 'Margin cukup ⚠' : 'Margin rendah ✗' }}
                            </span>
                        </div>
                    </div>
                </div>

                 <div class="flex justify-end pt-4">
                     <button type="button" @click="saveRecipe" :disabled="loadingRecipe" class="bg-primary hover:bg-green-800 text-white px-6 py-2 rounded-lg font-bold transition-colors disabled:opacity-50 flex items-center">
                        {{ loadingRecipe ? 'Saving Recipe...' : 'Save Recipe' }}
                     </button>
                </div>
            </div>

            <!-- Modifiers Tab -->
            <div v-show="activeTab === 'modifiers'" class="space-y-6">
                <div class="flex justify-between items-center mb-4">
                    <h3 class="text-lg font-bold text-gray-800">Assign Modifiers</h3>
                    <p class="text-sm text-gray-500">Select modifiers that apply to this product</p>
                </div>

                <div v-if="allModifiers.length === 0" class="text-center py-8 text-gray-400 bg-gray-50 rounded-lg border border-dashed border-gray-200">
                    No modifiers available. <router-link to="/admin/modifiers" class="text-primary hover:underline">Create modifiers first</router-link>.
                </div>

                <div v-else class="space-y-4">
                    <div 
                        v-for="mod in allModifiers" 
                        :key="mod.id" 
                        class="p-4 bg-gray-50 rounded-lg border border-gray-200 transition-colors"
                        :class="{ 'border-primary bg-primary/5': isSelected(mod.id) }"
                    >
                        <div class="flex items-start cursor-pointer" @click="toggleModifier(mod)">
                            <div class="flex items-center h-5">
                                <input 
                                    type="checkbox" 
                                    :checked="isSelected(mod.id)"
                                    class="text-primary focus:ring-primary rounded border-gray-300 pointer-events-none"
                                />
                            </div>
                            <div class="ml-3 flex-1">
                                <div class="flex items-center gap-2">
                                    <span class="font-bold text-slate-800">{{ mod.name }}</span>
                                    <span :class="mod.type === 'radio' ? 'bg-blue-100 text-blue-700' : 'bg-purple-100 text-purple-700'" class="px-2 py-0.5 rounded-full text-xs font-bold">
                                        {{ mod.type === 'radio' ? 'Single' : 'Multi' }}
                                    </span>
                                    <span v-if="mod.is_required" class="bg-green-100 text-green-700 px-2 py-0.5 rounded-full text-xs font-bold">Required</span>
                                </div>
                                <div class="flex flex-wrap gap-1 mt-1">
                                    <span v-for="opt in mod.options" :key="opt.id" class="text-xs text-gray-500 bg-white border px-1 rounded">
                                        {{ opt.name }} 
                                    </span>
                                </div>
                            </div>
                        </div>

                        <!-- Condition Settings -->
                        <div v-if="isSelected(mod.id)" class="mt-3 pt-3 border-t border-gray-200/50 pl-8">
                            <label class="block text-xs font-bold text-gray-500 mb-1">Visibility Condition (Optional)</label>
                            <div class="flex items-center gap-2 flex-wrap">
                                <span class="text-xs text-gray-400">Show only when:</span>
                                <select 
                                    :value="getEntry(mod.id).condition_modifier_id" 
                                    @change="e => updateConditionModifier(mod.id, e.target.value)"
                                    class="text-xs border-gray-300 rounded focus:ring-primary focus:border-primary py-1 bg-white"
                                >
                                    <option :value="null">Always Visible</option>
                                    <option 
                                        v-for="otherMod in getOtherSelectedModifiers(mod.id)" 
                                        :key="otherMod.id" 
                                        :value="otherMod.id"
                                    >
                                        {{ otherMod.name }}
                                    </option>
                                </select>
                                
                                <template v-if="getEntry(mod.id).condition_modifier_id">
                                    <span class="text-xs text-gray-400">is</span>
                                    
                                    <select 
                                        :value="getEntry(mod.id).condition_option_id"
                                        @change="e => updateConditionOption(mod.id, e.target.value)"
                                        class="text-xs border-gray-300 rounded focus:ring-primary focus:border-primary py-1 bg-white"
                                    >
                                        <option :value="null">Select Option</option>
                                        <option 
                                            v-for="opt in getModifierOptions(getEntry(mod.id).condition_modifier_id)" 
                                            :key="opt.id" 
                                            :value="opt.id"
                                        >
                                            {{ opt.name }}
                                        </option>
                                    </select>
                                </template>
                            </div>
                        </div>

                        <!-- Allowed Options Settings -->
                        <div v-if="isSelected(mod.id)" class="mt-3 pt-3 border-t border-gray-200/50 pl-8">
                            <div class="flex items-center justify-between mb-2">
                                <label class="block text-xs font-bold text-gray-500">Allowed Options</label>
                                <button type="button" @click="toggleAllOptions(mod.id)" class="text-[10px] text-primary hover:underline font-medium">
                                    Toggle All
                                </button>
                            </div>
                            <div class="flex flex-wrap gap-3">
                                <label v-for="opt in mod.options" :key="opt.id" class="flex items-center text-xs cursor-pointer bg-white border border-gray-200 rounded px-2 py-1 transition-colors hover:border-gray-300">
                                    <input 
                                        type="checkbox" 
                                        :checked="isOptionAllowed(mod.id, opt.id)"
                                        @change="toggleAllowedOption(mod.id, opt.id)"
                                        class="mr-2 text-primary rounded border-gray-300 focus:ring-primary h-3 w-3"
                                    />
                                    <span :class="{'text-gray-900 font-medium': isOptionAllowed(mod.id, opt.id), 'text-gray-400': !isOptionAllowed(mod.id, opt.id)}">
                                        {{ opt.name }}
                                    </span>
                                </label>
                            </div>
                            <p class="text-[10px] text-gray-400 mt-1">Uncheck options to hide them for this product.</p>
                        </div>
                    </div>
                </div>

                <div class="flex justify-end pt-4 border-t border-gray-100">
                    <button type="button" @click="saveModifiers" :disabled="loadingModifiers" class="bg-primary hover:bg-green-800 text-white px-6 py-2 rounded-lg font-bold transition-colors disabled:opacity-50 flex items-center">
                        {{ loadingModifiers ? 'Saving...' : 'Save Modifiers' }}
                    </button>
                </div>
            </div>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, onMounted, reactive, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import MainLayout from '../../../components/layout/MainLayout.vue';
import api from '../../../api/axios';
import { useToast } from "vue-toastification";
import { PlusIcon, TrashIcon } from 'lucide-vue-next';

const toast = useToast();
const route = useRoute();
const router = useRouter();

const activeTab = ref('general');
const isEditing = ref(false);
const loading = ref(false);
const loadingRecipe = ref(false);
const categories = ref([]);
const ingredients = ref([]);
const recipeList = ref([]);
const allModifiers = ref([]);
const selectedModifiers = ref([]);
const loadingModifiers = ref(false);
const previewImage = ref(null);
const imageFile = ref(null);

const form = reactive({
    name: '',
    sku: '',
    category_id: '',
    price: '',
    description: '',
    is_available: true,
    is_recommended: false,
    is_upsell: false
});

const activeSalesTypes = ref([]);
const salePrices = ref({}); // { sales_type_id: price }

const handleImageUpload = (event) => {
    const file = event.target.files[0];
    if (file) {
        imageFile.value = file;
        previewImage.value = URL.createObjectURL(file);
    }
};

const fetchCategories = async () => {
    try {
        const response = await api.get('/admin/categories');
        const rawData = response.data?.data || response.data || [];
        categories.value = Array.isArray(rawData) ? rawData : [];
    } catch (error) {
        console.error("Failed to load categories");
    }
};

const fetchIngredients = async () => {
    try {
        const response = await api.get('/admin/ingredients');
        const rawData = response.data?.data || response.data || [];
        ingredients.value = Array.isArray(rawData) ? rawData : [];
    } catch (error) {
        console.error("Failed to load ingredients");
    }
};

const fetchActiveSalesTypes = async () => {
    try {
        const response = await api.get('/admin/sales-types');
        activeSalesTypes.value = response.data.data.filter(t => t.is_active);
    } catch (error) {
        console.error("Failed to load sales types");
    }
};

const productSlug = ref(null);

const fetchProduct = async (slug) => {
    try {
        const response = await api.get(`/admin/products/${slug}`);
        const product = response.data?.data || response.data || {};
        form.name = product.name;
        form.sku = product.sku;
        form.category_id = product.category_id;
        form.price = product.price;
        form.description = product.description;
        form.is_available = !!product.is_available;
        form.is_recommended = !!product.is_recommended;
        form.is_upsell = !!product.is_upsell;
        productSlug.value = product.slug;
        
        if (product.image_url) {
            previewImage.value = product.image_url;
        }

        // Populating sale prices
        if (product.sale_prices) {
            product.sale_prices.forEach(sp => {
                salePrices.value[sp.id] = sp.pivot.price;
            });
        }
    } catch (error) {
        console.error("Failed to load product");
        router.push('/admin/products');
    }
};

const fetchRecipe = async (slug) => {
    try {
        const response = await api.get(`/admin/products/${slug}/recipe`);
        const data = response.data?.data || response.data || [];
        // Map pivot data
        recipeList.value = (Array.isArray(data) ? data : []).map(item => ({
            ingredient_id: item.id,
            quantity_needed: item.pivot?.quantity_needed || 0
        }));
    } catch (error) {
        console.error("Failed to load recipe");
    }
};

const fetchModifiers = async () => {
    try {
        const response = await api.get('/admin/modifiers');
        const rawData = response.data?.data || response.data || [];
        allModifiers.value = Array.isArray(rawData) ? rawData : [];
    } catch (error) {
        console.error("Failed to load modifiers");
    }
};

const fetchProductModifiers = async (slug) => {
    try {
        const response = await api.get(`/admin/products/${slug}`);
        const product = response.data?.data || response.data || {};
        if (product.modifiers) {
            selectedModifiers.value = product.modifiers.map(m => {
                let allowed = m.pivot?.allowed_options;
                if (typeof allowed === 'string') {
                    try { allowed = JSON.parse(allowed); } catch(e) { allowed = null; }
                }
                return {
                    id: m.id,
                    condition_modifier_id: m.pivot.condition_modifier_id,
                    condition_option_id: m.pivot.condition_option_id,
                    allowed_options: allowed
                };
            });
        }
    } catch (error) {
        console.error("Failed to load product modifiers");
    }
};

const saveModifiers = async () => {
    loadingModifiers.value = true;
    try {
        await api.post(`/admin/products/${productSlug.value || route.params.slug}/modifiers`, {
            modifiers: selectedModifiers.value
        });
        toast.success('Modifiers updated successfully!');
    } catch (error) {
        toast.error(error.response?.data?.message || 'Failed to save modifiers');
    } finally {
        loadingModifiers.value = false;
    }
};

const deleteImage = async () => {
    if (!confirm('Are you sure you want to delete this image?')) return;
    try {
        await api.delete(`/admin/products/${productSlug.value || route.params.slug}/image`);
        previewImage.value = null;
        imageFile.value = null;
        toast.success('Image deleted successfully!');
    } catch (error) {
        toast.error(error.response?.data?.message || 'Failed to delete image');
    }
};

const submitForm = async () => {
    loading.value = true;
    try {
        const formData = new FormData();
        formData.append('name', form.name);
        formData.append('sku', form.sku);
        formData.append('category_id', form.category_id);
        formData.append('price', form.price);
        formData.append('description', form.description || '');
        formData.append('is_available', form.is_available ? '1' : '0');
        formData.append('is_recommended', form.is_recommended ? '1' : '0');
        formData.append('is_upsell', form.is_upsell ? '1' : '0');

        // Add sale prices
        let index = 0;
        Object.keys(salePrices.value).forEach(salesTypeId => {
            const price = salePrices.value[salesTypeId];
            if (price !== null && price !== '' && price !== undefined) {
                formData.append(`sale_prices[${index}][sales_type_id]`, salesTypeId);
                formData.append(`sale_prices[${index}][price]`, price);
                index++;
            }
        });
        
        if (imageFile.value) {
            formData.append('image', imageFile.value);
        }

        const slug = productSlug.value || route.params.slug;

        if (isEditing.value) {
            formData.append('_method', 'PUT');
            const res = await api.post(`/admin/products/${slug}`, formData, {
                headers: { 'Content-Type': 'multipart/form-data' }
            });
            // Update slug if name changed
            const updatedProduct = res.data;
            if (updatedProduct?.slug && updatedProduct.slug !== slug) {
                productSlug.value = updatedProduct.slug;
                router.replace(`/admin/products/${updatedProduct.slug}/edit`);
            }
            toast.success('Product updated successfully!');
        } else {
            const res = await api.post('/admin/products', formData, {
                 headers: { 'Content-Type': 'multipart/form-data' }
            });
            toast.success('Product created successfully!');
            const newProduct = res.data?.data || res.data;
            if (newProduct?.slug) {
                router.push(`/admin/products/${newProduct.slug}/edit`);
            } else {
                router.push('/admin/products');
            }
            return;
        }
        
    } catch (error) {
        toast.error(error.response?.data?.message || 'Failed to save product');
    } finally {
        loading.value = false;
    }
};

const addIngredientRow = () => {
    recipeList.value.push({ ingredient_id: '', quantity_needed: 0 });
};

const removeIngredientRow = (index) => {
    recipeList.value.splice(index, 1);
};

const getUnit = (ingredientId) => {
    const ing = ingredients.value.find(i => i.id === ingredientId);
    return ing && ing.unit ? ing.unit.abbreviation : '-';
};

const calculateCost = (item) => {
    if (!item.ingredient_id || !item.quantity_needed) return 0;
    const ing = ingredients.value.find(i => i.id === item.ingredient_id);
    return ing ? (ing.cost_per_unit * item.quantity_needed) : 0;
};

const totalHpp = computed(() => {
    return recipeList.value.reduce((total, item) => total + calculateCost(item), 0);
});

const marginPercent = computed(() => {
    const sellingPrice = parseFloat(form.price) || 0;
    if (sellingPrice <= 0 || totalHpp.value <= 0) return null;
    return ((sellingPrice - totalHpp.value) / sellingPrice) * 100;
});

const saveRecipe = async () => {
    loadingRecipe.value = true;
    try {
        await api.post(`/admin/products/${productSlug.value || route.params.slug}/recipe`, {
            ingredients: recipeList.value
        });
        toast.success('Recipe updated successfully!');
    } catch (error) {
         toast.error(error.response?.data?.message || 'Failed to save recipe');
    } finally {
        loadingRecipe.value = false;
    }
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(value);
};

const isSelected = (id) => selectedModifiers.value.some(m => m.id === id);

const getEntry = (id) => selectedModifiers.value.find(m => m.id === id) || {};

const toggleModifier = (mod) => {
    const index = selectedModifiers.value.findIndex(m => m.id === mod.id);
    if (index === -1) {
        selectedModifiers.value.push({ id: mod.id, condition_modifier_id: null, condition_option_id: null, allowed_options: null });
    } else {
        selectedModifiers.value.splice(index, 1);
    }
};

const getOtherSelectedModifiers = (currentId) => {
    return selectedModifiers.value
        .filter(m => m.id !== currentId)
        .map(m => allModifiers.value.find(am => am.id === m.id))
        .filter(Boolean);
};

const getModifierOptions = (modId) => {
    const mod = allModifiers.value.find(m => m.id == modId);
    return mod ? mod.options : [];
};

const updateConditionModifier = (modId, val) => {
    if (val === 'null' || val === '') val = null;
    const entry = selectedModifiers.value.find(m => m.id === modId);
    if (entry) {
        entry.condition_modifier_id = val || null;
        entry.condition_option_id = null;
    }
};

const isOptionAllowed = (modId, optId) => {
    const entry = selectedModifiers.value.find(m => m.id === modId);
    if (!entry) return false;
    if (!entry.allowed_options) return true;
    return entry.allowed_options.includes(optId);
};

const toggleAllowedOption = (modId, optId) => {
    const entry = selectedModifiers.value.find(m => m.id === modId);
    if (!entry) return;
    
    if (!entry.allowed_options) {
        const mod = allModifiers.value.find(m => m.id === modId);
        if (mod) {
            entry.allowed_options = mod.options.map(o => o.id);
        } else {
             entry.allowed_options = [];
        }
    }
    
    const idx = entry.allowed_options.indexOf(optId);
    if (idx > -1) {
        entry.allowed_options.splice(idx, 1);
    } else {
        entry.allowed_options.push(optId);
    }
};

const toggleAllOptions = (modId) => {
    const entry = selectedModifiers.value.find(m => m.id === modId);
    if (!entry) return;
    entry.allowed_options = null;
};


onMounted(async () => {
    await fetchCategories();
    await fetchIngredients();
    await fetchModifiers();
    await fetchActiveSalesTypes();
    if (route.params.slug) {
        isEditing.value = true;
        await fetchProduct(route.params.slug);
        await fetchRecipe(route.params.slug);
        await fetchProductModifiers(route.params.slug);
    }
});
</script>
