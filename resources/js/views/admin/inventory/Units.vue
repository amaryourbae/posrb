<template>
    <MainLayout>
        <div class="flex justify-between items-center mb-6">
            <div>
                <h1 class="text-2xl font-bold text-slate-800">
                    Unit Management
                </h1>
                <p class="text-gray-500">
                    Manage measure units for ingredients.
                </p>
            </div>
            <button
                @click="openModal()"
                class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-sm"
            >
                <PlusIcon class="w-5 h-5 mr-2" />
                Add Unit
            </button>
        </div>

        <!-- Units List -->
        <div
            class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden"
        >
            <table class="w-full text-left font-sans">
                <thead
                    class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100"
                >
                    <tr>
                        <th class="px-6 py-4 font-semibold">Unit Name</th>
                        <th class="px-6 py-4 font-semibold text-center w-32">
                            Abbreviation
                        </th>
                        <th class="px-6 py-4 font-semibold text-right">
                            Actions
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    <tr
                        v-for="unit in units"
                        :key="unit.id"
                        class="hover:bg-blue-50/30 transition-colors group"
                    >
                        <td
                            class="px-6 py-5 font-bold text-slate-800 text-base"
                        >
                            {{ unit.name }}
                        </td>
                        <td class="px-6 py-5">
                            <div class="flex justify-center">
                                <span
                                    class="bg-gray-100 text-gray-600 text-[10px] px-3 py-1 rounded font-bold uppercase tracking-widest border border-gray-200"
                                >
                                    {{ unit.abbreviation }}
                                </span>
                            </div>
                        </td>
                        <td class="px-6 py-5 text-right space-x-2">
                            <div
                                class="flex items-center justify-end space-x-3"
                            >
                                <button
                                    @click="openModal(unit)"
                                    class="text-blue-400 hover:text-blue-600 transition-colors p-1.5 rounded-lg hover:bg-blue-100"
                                    title="Edit"
                                >
                                    <PencilIcon class="w-5 h-5" />
                                </button>
                                <button
                                    @click="deleteUnit(unit.id)"
                                    class="text-red-400 hover:text-red-600 transition-colors p-1.5 rounded-lg hover:bg-red-100"
                                    title="Delete"
                                >
                                    <TrashIcon class="w-5 h-5" />
                                </button>
                            </div>
                        </td>
                    </tr>
                    <tr v-if="units.length === 0">
                        <td
                            colspan="3"
                            class="px-6 py-12 text-center text-gray-400 bg-gray-50/50"
                        >
                            <div
                                class="flex flex-col items-center justify-center"
                            >
                                <p class="text-lg font-medium text-gray-500">
                                    No units found
                                </p>
                                <p class="text-sm">
                                    Start by adding a measurement unit.
                                </p>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Add/Edit Unit Modal -->
        <div
            v-if="showModal"
            class="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
            <div
                class="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity"
                @click="closeModal"
            ></div>
            <div
                class="bg-white rounded-3xl shadow-2xl w-full max-w-md relative z-10 p-8 transform transition-all animate-in zoom-in-95 duration-200"
            >
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-bold text-slate-800">
                        {{ isEditing ? "Edit Unit" : "New Unit" }}
                    </h2>
                    <button
                        @click="closeModal"
                        class="text-gray-400 hover:text-gray-600 transition-colors bg-gray-100 p-2 rounded-full"
                    >
                        <XIcon class="w-6 h-6" />
                    </button>
                </div>
                <form @submit.prevent="saveUnit" class="space-y-6">
                    <div>
                        <label
                            class="block text-sm font-bold text-slate-700 mb-2"
                            >Unit Name</label
                        >
                        <input
                            v-model="form.name"
                            type="text"
                            required
                            placeholder="e.g. Kilogram"
                            class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium"
                        />
                    </div>
                    <div>
                        <label
                            class="block text-sm font-bold text-slate-700 mb-2"
                            >Abbreviation</label
                        >
                        <input
                            v-model="form.abbreviation"
                            type="text"
                            required
                            placeholder="e.g. kg"
                            class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium"
                        />
                        <p class="text-xs text-gray-500 mt-2">
                            Max 10 characters.
                        </p>
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
                            {{ loading ? "Saving..." : "Save Unit" }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, onMounted, reactive } from "vue";
import MainLayout from "../../../components/layout/MainLayout.vue";
import { PlusIcon, PencilIcon, TrashIcon, XIcon } from "lucide-vue-next";
import api from "../../../api/axios";
import { useToast } from "vue-toastification";

const toast = useToast();
const units = ref([]);
const showModal = ref(false);
const isEditing = ref(false);
const loading = ref(false);
const editId = ref(null);

const form = reactive({
    name: "",
    abbreviation: "",
});

const fetchUnits = async () => {
    try {
        const response = await api.get("/admin/units");
        // Handle varying response structures depending on ApiResponse trait
        const rawData = response.data?.data || response.data || [];
        units.value = Array.isArray(rawData) ? rawData : [];
    } catch (error) {
        toast.error("Failed to load units");
    }
};

const openModal = (item = null) => {
    if (item) {
        isEditing.value = true;
        editId.value = item.id;
        form.name = item.name;
        form.abbreviation = item.abbreviation;
    } else {
        isEditing.value = false;
        editId.value = null;
        form.name = "";
        form.abbreviation = "";
    }
    showModal.value = true;
};

const closeModal = () => {
    showModal.value = false;
};

const saveUnit = async () => {
    loading.value = true;
    try {
        if (isEditing.value) {
            await api.put(`/admin/units/${editId.value}`, form);
            toast.success("Unit updated successfully");
        } else {
            await api.post("/admin/units", form);
            toast.success("Unit created successfully");
        }
        await fetchUnits();
        closeModal();
    } catch (error) {
        toast.error(error.response?.data?.message || "Failed to save unit");
    } finally {
        loading.value = false;
    }
};

const deleteUnit = async (id) => {
    if (
        !confirm(
            "Are you sure you want to delete this unit? It might affect assigned ingredients.",
        )
    )
        return;
    try {
        await api.delete(`/admin/units/${id}`);
        toast.success("Unit deleted successfully");
        await fetchUnits();
    } catch (error) {
        toast.error(error.response?.data?.message || "Failed to delete unit");
    }
};

onMounted(() => {
    fetchUnits();
});
</script>
