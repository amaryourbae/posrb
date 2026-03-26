<template>
    <MainLayout :loading="pageLoading">
        <div class="flex justify-between items-center mb-6">
            <div>
                <h1 class="text-2xl font-bold text-slate-800">
                    Inventory Management
                </h1>
                <p class="text-gray-500">
                    Manage ingredients, stock levels, and costs.
                </p>
            </div>
            <div class="flex space-x-3">
                <button
                    @click="openImportModal"
                    class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-sm"
                >
                    <UploadIcon class="w-5 h-5 mr-2" />
                    Import CSV
                </button>
                <button
                    @click="openStockInModal()"
                    class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-sm"
                >
                    <PlusIcon class="w-5 h-5 mr-2" />
                    Stock In
                </button>
                <button
                    @click="openModal()"
                    class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-sm"
                >
                    <PlusIcon class="w-5 h-5 mr-2" />
                    Add Ingredient
                </button>
            </div>
        </div>

        <!-- Ingredient List -->
        <div
            class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden"
        >
            <!-- Filters -->
            <div
                class="p-6 border-b border-gray-100 flex flex-wrap justify-between gap-4 items-center bg-gray-50/50"
            >
                <div class="relative">
                    <span
                        class="absolute inset-y-0 left-0 flex items-center pl-3"
                    >
                        <SearchIcon class="w-5 h-5 text-gray-400" />
                    </span>
                    <input
                        v-model="search"
                        @input="debouncedSearch"
                        type="text"
                        placeholder="Search ingredients..."
                        class="pl-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary w-full md:w-80 py-2.5 shadow-sm"
                    />
                </div>

                <div
                    v-if="selectedIds.length > 0"
                    class="flex items-center space-x-4 animate-in fade-in duration-300"
                >
                    <span
                        class="text-sm font-medium text-slate-600 bg-slate-100 px-3 py-1 rounded-full border border-slate-200"
                    >
                        {{ selectedIds.length }} items selected
                    </span>
                    <button
                        @click="handleBulkDelete"
                        class="bg-red-50 text-red-600 hover:bg-red-100 px-4 py-2 rounded-lg font-bold flex items-center transition-all border border-red-200"
                    >
                        <TrashIcon class="w-4 h-4 mr-2" />
                        Bulk Delete
                    </button>
                </div>
            </div>

            <table class="w-full text-left font-sans">
                <thead
                    class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100"
                >
                    <tr>
                        <th class="px-6 py-4 font-semibold w-10">
                            <input
                                type="checkbox"
                                class="rounded border-gray-300 text-primary focus:ring-primary h-4 w-4 transition-all"
                                :checked="isAllSelected"
                                @change="toggleSelectAll"
                            />
                        </th>
                        <th class="px-6 py-4 font-semibold">Name</th>
                        <th class="px-6 py-4 font-semibold">Stock</th>
                        <th class="px-6 py-4 font-semibold text-center w-24">
                            Unit
                        </th>
                        <th class="px-6 py-4 font-semibold">Avg Cost</th>
                        <th class="px-6 py-4 font-semibold">Status</th>
                        <th class="px-6 py-4 font-semibold text-right">
                            Actions
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    <tr
                        v-for="item in (ingredients || []).filter(
                            (i) => i != null,
                        )"
                        :key="item.id"
                        class="hover:bg-blue-50/30 transition-colors group"
                    >
                        <td class="px-6 py-5">
                            <input
                                type="checkbox"
                                class="rounded border-gray-300 text-primary focus:ring-primary h-4 w-4 transition-all"
                                :value="item.id"
                                v-model="selectedIds"
                            />
                        </td>
                        <td
                            class="px-6 py-5 font-bold text-slate-800 text-base"
                        >
                            {{ item.name }}
                        </td>
                        <td
                            class="px-6 py-5 font-bold"
                            :class="
                                item.current_stock <= item.minimum_stock_alert
                                    ? 'text-red-600'
                                    : 'text-slate-700'
                            "
                        >
                            {{ parseFloat(item.current_stock) }}
                        </td>
                        <td class="px-6 py-5">
                            <div class="flex justify-center">
                                <span
                                    class="bg-gray-100 text-gray-600 text-[10px] px-2 py-0.5 rounded font-bold uppercase tracking-widest border border-gray-200"
                                    :title="item.unit ? item.unit.name : 'Unknown Unit'"
                                >
                                    {{ item.unit ? item.unit.abbreviation : '-' }}
                                </span>
                            </div>
                        </td>
                        <td class="px-6 py-5 text-slate-700 font-mono">
                            {{ formatCurrency(item.cost_per_unit) }}
                        </td>
                        <td class="px-6 py-5">
                            <span
                                v-if="
                                    item.current_stock <=
                                    item.minimum_stock_alert
                                "
                                class="bg-red-100 text-red-700 ring-1 ring-red-600/20 px-2.5 py-1 rounded-full text-xs font-bold inline-flex items-center"
                            >
                                <span
                                    class="w-1.5 h-1.5 rounded-full bg-red-600 mr-1.5 animate-pulse"
                                ></span>
                                Low Stock
                            </span>
                            <span
                                v-else
                                class="bg-green-100 text-green-700 ring-1 ring-green-600/20 px-2.5 py-1 rounded-full text-xs font-bold inline-flex items-center"
                            >
                                <span
                                    class="w-1.5 h-1.5 rounded-full bg-green-600 mr-1.5"
                                ></span>
                                OK
                            </span>
                        </td>
                        <td class="px-6 py-5 text-right space-x-2">
                            <div
                                class="flex items-center justify-end space-x-3"
                            >
                                <button
                                    @click="openModal(item)"
                                    class="text-blue-400 hover:text-blue-600 transition-colors p-1.5 rounded-lg hover:bg-blue-100"
                                    title="Edit"
                                >
                                    <PencilIcon class="w-5 h-5" />
                                </button>
                                <button
                                    @click="deleteIngredient(item.id)"
                                    class="text-red-400 hover:text-red-600 transition-colors p-1.5 rounded-lg hover:bg-red-100"
                                    title="Delete"
                                >
                                    <TrashIcon class="w-5 h-5" />
                                </button>
                            </div>
                        </td>
                    </tr>
                    <tr v-if="ingredients.length === 0">
                        <td
                            colspan="7"
                            class="px-6 py-12 text-center text-gray-400 bg-gray-50/50"
                        >
                            <div
                                class="flex flex-col items-center justify-center"
                            >
                                <p class="text-lg font-medium text-gray-500">
                                    No ingredients found
                                </p>
                                <p class="text-sm">
                                    Start by adding raw materials.
                                </p>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Add/Edit Ingredient Modal -->
        <div
            v-if="showModal"
            class="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
            <div
                class="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity"
                @click="closeModal"
            ></div>
            <div
                class="bg-white rounded-3xl shadow-2xl w-full max-w-lg relative z-10 p-8 transform transition-all animate-in zoom-in-95 duration-200"
            >
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-bold text-slate-800">
                        {{ isEditing ? "Edit Ingredient" : "New Ingredient" }}
                    </h2>
                    <button
                        @click="closeModal"
                        class="text-gray-400 hover:text-gray-600 transition-colors bg-gray-100 p-2 rounded-full"
                    >
                        <XIcon class="w-6 h-6" />
                    </button>
                </div>
                <form @submit.prevent="saveIngredient" class="space-y-6">
                    <div>
                        <label
                            class="block text-sm font-bold text-slate-700 mb-2"
                            >Ingredient Name</label
                        >
                        <input
                            v-model="form.name"
                            type="text"
                            required
                            placeholder="e.g. Arabica Beans"
                            class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium"
                        />
                    </div>
                    <div class="grid grid-cols-2 gap-6">
                        <div>
                            <label
                                class="block text-sm font-bold text-slate-700 mb-2"
                                >Unit</label
                            >
                            <select
                                v-model="form.unit_id"
                                required
                                class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium appearance-none"
                            >
                                <option value="" disabled>Select a unit</option>
                                <option v-for="unit in availableUnits" :key="unit.id" :value="unit.id">
                                    {{ unit.name }} ({{ unit.abbreviation }})
                                </option>
                            </select>
                        </div>
                        <div>
                            <label
                                class="block text-sm font-bold text-slate-700 mb-2"
                                >Min. Stock Alert</label
                            >
                            <input
                                v-model="form.minimum_stock_alert"
                                type="number"
                                step="0.01"
                                min="0"
                                required
                                class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium"
                            />
                        </div>
                    </div>
                    <div class="flex justify-end space-x-4 mt-8">
                        <button
                            type="button"
                            @click="closeModal"
                            class="px-6 py-3 text-slate-600 font-bold hover:bg-gray-100 rounded-2xl transition-colors"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            class="px-8 py-3 bg-primary text-white font-bold rounded-2xl hover:bg-green-800 transition-all shadow-md shadow-primary/20 disabled:opacity-50"
                            :disabled="loading"
                        >
                            {{ loading ? "Saving..." : "Save Changes" }}
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Stock In Modal -->
        <div
            v-if="showStockInModal"
            class="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
            <div
                class="absolute inset-0 bg-black/60 backdrop-blur-sm"
                @click="closeStockInModal"
            ></div>
            <div
                class="bg-white rounded-3xl shadow-2xl w-full max-w-lg relative z-10 p-8 animate-in zoom-in-95 duration-200"
            >
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-bold text-slate-800">
                        Stock In (Purchase)
                    </h2>
                    <button
                        @click="closeStockInModal"
                        class="text-gray-400 hover:text-gray-600 transition-colors bg-gray-100 p-2 rounded-full"
                    >
                        <XIcon class="w-6 h-6" />
                    </button>
                </div>
                <form @submit.prevent="submitStockIn" class="space-y-6">
                    <div>
                        <label
                            class="block text-sm font-bold text-slate-700 mb-2"
                            >Ingredient</label
                        >
                        <select
                            v-model="stockInForm.ingredient_id"
                            required
                            class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium appearance-none"
                        >
                            <option value="" disabled>Select Ingredient</option>
                            <option
                                v-for="item in ingredients"
                                :key="item.id"
                                :value="item.id"
                            >
                                {{ item.name }} (Current:
                                {{ parseFloat(item.current_stock) }}
                                {{ item.unit ? item.unit.abbreviation : '-' }})
                            </option>
                        </select>
                    </div>
                    <div class="grid grid-cols-2 gap-6">
                        <div>
                            <label
                                class="block text-sm font-bold text-slate-700 mb-2"
                                >Quantity Added</label
                            >
                            <input
                                v-model="stockInForm.quantity"
                                type="number"
                                step="0.01"
                                min="0"
                                required
                                class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium tracking-tight"
                            />
                        </div>
                        <div>
                            <label
                                class="block text-sm font-bold text-slate-700 mb-2"
                                >Cost Per Unit (IDR)</label
                            >
                            <input
                                v-model="stockInForm.unit_cost"
                                type="number"
                                step="0.01"
                                min="0"
                                required
                                class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium tracking-tight"
                            />
                        </div>
                    </div>
                    <div>
                        <label
                            class="block text-sm font-bold text-slate-700 mb-2"
                            >Notes (Optional)</label
                        >
                        <textarea
                            v-model="stockInForm.notes"
                            rows="2"
                            placeholder="Supplier info, invoice number..."
                            class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium"
                        ></textarea>
                    </div>
                    <div
                        class="bg-blue-50/80 p-5 rounded-2xl text-blue-800 flex justify-between items-center border border-blue-100"
                    >
                        <span
                            class="text-sm font-bold uppercase tracking-wider opacity-70"
                            >Total Value</span
                        >
                        <strong class="text-lg font-mono">{{
                            formatCurrency(
                                stockInForm.quantity * stockInForm.unit_cost,
                            )
                        }}</strong>
                    </div>

                    <div class="flex justify-end space-x-4 mt-8">
                        <button
                            type="button"
                            @click="closeStockInModal"
                            class="px-6 py-3 text-slate-600 font-bold hover:bg-gray-100 rounded-2xl transition-colors"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            class="px-8 py-3 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 transition-all shadow-md shadow-blue-600/20 disabled:opacity-50"
                            :disabled="loading"
                        >
                            {{ loading ? "Processing..." : "Confirm Stock In" }}
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Import CSV Modal -->
        <div
            v-if="showImportModal"
            class="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
            <div
                class="absolute inset-0 bg-black/60 backdrop-blur-sm"
                @click="closeImportModal"
            ></div>
            <div
                class="bg-white rounded-3xl shadow-2xl w-full max-w-lg relative z-10 animate-in zoom-in-95 duration-200"
            >
                <div class="p-8">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-2xl font-bold text-slate-800">
                            Import Ingredients
                        </h2>
                        <button
                            @click="closeImportModal"
                            class="text-gray-400 hover:text-gray-600 transition-colors bg-gray-100 p-2 rounded-full"
                        >
                            <XIcon class="w-6 h-6" />
                        </button>
                    </div>

                    <div class="space-y-6">
                        <div
                            class="bg-slate-50 border-2 border-dashed border-slate-200 p-8 rounded-3xl text-center group hover:border-indigo-300 transition-colors"
                        >
                            <UploadIcon
                                class="w-12 h-12 text-slate-400 mx-auto mb-4 group-hover:text-indigo-500 transition-colors"
                            />
                            <p class="text-slate-600 font-medium mb-1">
                                Select CSV file to upload
                            </p>
                            <p class="text-xs text-slate-400 mb-6">
                                Only .csv files are supported
                            </p>
                            <input
                                type="file"
                                id="csv-upload"
                                class="hidden"
                                accept=".csv"
                                @change="handleFileChange"
                            />
                            <label
                                for="csv-upload"
                                class="inline-block px-6 py-2.5 bg-white border border-slate-200 text-slate-800 font-bold rounded-xl cursor-pointer hover:bg-slate-50 transition-colors shadow-sm"
                            >
                                {{
                                    selectedFile
                                        ? selectedFile.name
                                        : "Choose File"
                                }}
                            </label>
                        </div>

                        <div
                            class="bg-indigo-50 p-6 rounded-2xl border border-indigo-100"
                        >
                            <h3
                                class="text-indigo-900 font-bold text-sm mb-2 flex items-center"
                            >
                                <FileTextIcon class="w-4 h-4 mr-2" />
                                Instructions
                            </h3>
                            <ul
                                class="text-xs text-indigo-700 space-y-2 list-disc pl-4 font-medium leading-relaxed"
                            >
                                <li>
                                    The first row must be the header (Name,
                                    Unit, Minimum Stock Alert).
                                </li>
                                <li>
                                    The <strong>Unit</strong> column should contain the abbreviation (e.g., <strong>kg, ml, pcs</strong>). It will automatically create missing units.
                                </li>
                                <li>
                                    Duplicate ingredient names will be updated with new
                                    values.
                                </li>
                            </ul>
                            <a
                                href="/api/admin/ingredients/template"
                                download
                                class="mt-4 inline-flex items-center text-xs font-bold text-indigo-600 hover:text-indigo-800 underline decoration-2 underline-offset-4"
                            >
                                <DownloadIcon class="w-3.5 h-3.5 mr-1" />
                                Download CSV Template
                            </a>
                        </div>
                    </div>

                    <div
                        v-if="importErrors.length > 0"
                        class="mt-6 p-4 bg-red-50 rounded-2xl border border-red-100 overflow-y-auto max-h-40"
                    >
                        <p
                            class="text-xs font-bold text-red-700 mb-2 uppercase tracking-wider"
                        >
                            Errors in CSV:
                        </p>
                        <ul
                            class="text-[11px] text-red-600 space-y-1 font-medium"
                        >
                            <li
                                v-for="(err, idx) in importErrors"
                                :key="idx"
                                class="flex items-start"
                            >
                                <span class="mr-1.5">•</span> {{ err }}
                            </li>
                        </ul>
                    </div>
                </div>

                <div
                    class="px-8 py-6 bg-slate-50 rounded-b-3xl border-t border-slate-100 flex justify-end space-x-4"
                >
                    <button
                        type="button"
                        @click="closeImportModal"
                        class="px-6 py-3 text-slate-600 font-bold hover:bg-gray-200 rounded-2xl transition-colors"
                    >
                        Cancel
                    </button>
                    <button
                        @click="handleImport"
                        class="px-8 py-3 bg-indigo-600 text-white font-bold rounded-2xl hover:bg-indigo-700 transition-all shadow-md shadow-indigo-600/20 disabled:opacity-50"
                        :disabled="loading || !selectedFile"
                    >
                        {{ loading ? "Importing..." : "Start Import" }}
                    </button>
                </div>
            </div>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, onMounted, reactive, computed } from "vue";
import MainLayout from "../../../components/layout/MainLayout.vue";
import { PlusIcon, PencilIcon, TrashIcon, SearchIcon, UploadIcon, XIcon, FileTextIcon, DownloadIcon } from "lucide-vue-next";
import api from "../../../api/axios";
import { useToast } from "vue-toastification";

const toast = useToast();
const ingredients = ref([]);
const search = ref("");
const showModal = ref(false);
const showStockInModal = ref(false);
const isEditing = ref(false);
const loading = ref(false);
const pageLoading = ref(true);
const editId = ref(null);

// Bulk Selection
const selectedIds = ref([]);
const isAllSelected = computed(() => {
    return ingredients.value.length > 0 && selectedIds.value.length === ingredients.value.length;
});

const availableUnits = ref([]);
const fetchUnits = async () => {
    try {
        const response = await api.get("/admin/units");
        const rawData = response.data?.data || response.data || [];
        availableUnits.value = Array.isArray(rawData) ? rawData : [];
    } catch (error) {
        console.error("Failed to fetch units:", error);
    }
};

// Import CSV
const showImportModal = ref(false);
const selectedFile = ref(null);
const importErrors = ref([]);

const form = reactive({
    name: "",
    unit_id: "",
    minimum_stock_alert: 100,
});

const stockInForm = reactive({
    ingredient_id: "",
    quantity: 0,
    unit_cost: 0,
    notes: "",
});

const fetchIngredients = async () => {
    if (ingredients.value.length === 0) pageLoading.value = true;
    try {
        const response = await api.get("/admin/ingredients", {
            params: { search: search.value },
        });
        const rawData = response.data?.data || response.data || [];
        ingredients.value = Array.isArray(rawData) ? rawData : [];
    } catch (error) {
        toast.error("Failed to load ingredients");
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
        form.unit_id = item.unit_id;
        form.minimum_stock_alert = item.minimum_stock_alert;
    } else {
        isEditing.value = false;
        editId.value = null;
        form.name = "";
        form.unit_id = availableUnits.value.length > 0 ? availableUnits.value[0].id : "";
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
            toast.success("Ingredient updated successfully");
        } else {
            await api.post("/admin/ingredients", form);
            toast.success("Ingredient created successfully");
        }
        await fetchIngredients();
        closeModal();
    } catch (error) {
        toast.error(
            error.response?.data?.message || "Failed to save ingredient",
        );
    } finally {
        loading.value = false;
    }
};

const deleteIngredient = async (id) => {
    if (!confirm("Delete this ingredient?")) return;
    try {
        await api.delete(`/admin/ingredients/${id}`);
        toast.success("Ingredient deleted");
        selectedIds.value = selectedIds.value.filter(sid => sid !== id);
        await fetchIngredients();
    } catch (error) {
        toast.error("Failed to delete ingredient");
    }
};

const toggleSelectAll = () => {
    if (isAllSelected.value) {
        selectedIds.value = [];
    } else {
        selectedIds.value = ingredients.value.map(i => i.id);
    }
};

const handleBulkDelete = async () => {
    if (!confirm(`Delete ${selectedIds.value.length} selected ingredients?`)) return;
    
    loading.value = true;
    try {
        await api.post('/admin/ingredients/bulk-delete', { ids: selectedIds.value });
        toast.success(`${selectedIds.value.length} ingredients deleted`);
        selectedIds.value = [];
        await fetchIngredients();
    } catch (error) {
        toast.error(error.response?.data?.message || "Failed to delete ingredients");
    } finally {
        loading.value = false;
    }
};

// Import Logic
const openImportModal = () => {
    selectedFile.value = null;
    importErrors.value = [];
    showImportModal.value = true;
};

const closeImportModal = () => {
    showImportModal.value = false;
};

const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
        selectedFile.value = file;
    }
};

const handleImport = async () => {
    if (!selectedFile.value) return;
    
    loading.value = true;
    importErrors.value = [];
    
    const formData = new FormData();
    formData.append('file', selectedFile.value);
    
    try {
        const response = await api.post('/admin/ingredients/import', formData, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });
        
        const data = response.data?.data || response.data;
        if (data.errors && data.errors.length > 0) {
            importErrors.value = data.errors;
            if (data.count > 0) {
                toast.warning(`Imported ${data.count} items, but encountered some errors.`);
            } else {
                toast.error("Import failed with errors.");
            }
        } else {
            toast.success(`Successfully imported ${data.count} ingredients.`);
            closeImportModal();
        }
        await fetchIngredients();
    } catch (error) {
        if (error.response?.data?.errors) {
            importErrors.value = Array.isArray(error.response.data.errors) 
                ? error.response.data.errors 
                : Object.values(error.response.data.errors).flat();
        }
        toast.error(error.response?.data?.message || "Failed to import CSV");
    } finally {
        loading.value = false;
    }
};

// Stock In Logic
const openStockInModal = () => {
    stockInForm.ingredient_id = "";
    stockInForm.quantity = 0;
    stockInForm.unit_cost = 0;
    stockInForm.notes = "";
    showStockInModal.value = true;
};

const closeStockInModal = () => {
    showStockInModal.value = false;
};

const submitStockIn = async () => {
    loading.value = true;
    try {
        await api.post("/admin/inventory/stock-in", stockInForm);
        toast.success("Stock added successfully");
        await fetchIngredients();
        closeStockInModal();
    } catch (error) {
        toast.error(error.response?.data?.message || "Failed to stock in");
    } finally {
        loading.value = false;
    }
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat("id-ID", {
        style: "currency",
        currency: "IDR",
    }).format(value);
};

onMounted(() => {
    fetchIngredients();
    fetchUnits();
});
</script>
