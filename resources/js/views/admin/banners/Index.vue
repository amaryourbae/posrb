<template>
    <MainLayout>
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
            <div>
                <h1 class="text-2xl font-bold text-slate-800">Banners</h1>
                <p class="text-gray-500">Manage home screen banners.</p>
            </div>
            <button 
                @click="openModal()" 
                class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg flex items-center gap-2 transition-colors"
            >
                <PlusIcon class="w-5 h-5" />
                <span>Add Banner</span>
            </button>
        </div>

        <!-- Banners Table -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-gray-600">
                    <thead class="bg-gray-50 text-gray-700 font-semibold uppercase tracking-wider text-xs border-b border-gray-100">
                        <tr>
                            <th class="px-6 py-4">Image</th>
                            <th class="px-6 py-4">Title / Description</th>
                            <th class="px-6 py-4">Action Link</th>
                            <th class="px-6 py-4 text-center">Order</th>
                            <th class="px-6 py-4 text-center">Status</th>
                            <th class="px-6 py-4 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                        <tr v-if="banners.length === 0">
                            <td colspan="6" class="px-6 py-8 text-center text-gray-400">
                                No banners found.
                            </td>
                        </tr>
                        <tr v-for="banner in banners" :key="banner.id" class="hover:bg-gray-50 transition-colors">
                            <td class="px-6 py-4">
                                <div class="w-24 h-12 rounded-lg bg-gray-100 overflow-hidden border border-gray-200">
                                    <img :src="banner.image_url" class="w-full h-full object-cover">
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <div class="font-bold text-slate-800 mb-0.5">{{ banner.title || '-' }}</div>
                                <div class="text-xs text-gray-500 line-clamp-1">{{ banner.description || '-' }}</div>
                            </td>
                            <td class="px-6 py-4">
                                <div class="flex flex-col">
                                    <span class="text-xs font-mono bg-gray-100 px-2 py-0.5 rounded w-fit">{{ banner.action_link || 'No Link' }}</span>
                                    <span class="text-[10px] text-gray-400 mt-1">Label: {{ banner.action_label || 'Claim' }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-4 text-center font-mono">
                                {{ banner.order }}
                            </td>
                            <td class="px-6 py-4 text-center">
                                <span 
                                    class="px-2 py-1 rounded-full text-xs font-bold"
                                    :class="banner.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'"
                                >
                                    {{ banner.is_active ? 'Active' : 'Inactive' }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-right">
                                <div class="flex items-center justify-end gap-2">
                                    <button @click="openModal(banner)" class="p-2 text-blue-600 hover:bg-blue-50 rounded-full transition-colors">
                                        <EditIcon class="w-4 h-4" />
                                    </button>
                                    <button @click="confirmDelete(banner)" class="p-2 text-red-600 hover:bg-red-50 rounded-full transition-colors">
                                        <TrashIcon class="w-4 h-4" />
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Create/Edit Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div class="absolute inset-0 bg-black/50 backdrop-blur-sm" @click="closeModal"></div>
            <div class="relative bg-white rounded-xl shadow-xl w-full max-w-lg p-6 max-h-[90vh] overflow-y-auto">
                <h3 class="text-xl font-bold text-slate-800 mb-6">
                    {{ isEditing ? 'Edit Banner' : 'Add New Banner' }}
                </h3>

                <form @submit.prevent="saveBanner" class="space-y-4">
                    <!-- Image Upload -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Banner Image <span class="text-red-500">*</span></label>
                        <div 
                            class="border-2 border-dashed border-gray-300 rounded-xl p-4 text-center cursor-pointer hover:bg-gray-50 transition-colors relative"
                            @click="$refs.fileInput.click()"
                        >
                            <input 
                                type="file" 
                                ref="fileInput" 
                                class="hidden" 
                                accept="image/*"
                                @change="handleFileUpload"
                            >
                            <div v-if="previewImage" class="relative group">
                                <img :src="previewImage" class="max-h-40 mx-auto rounded-lg shadow-sm">
                                <div class="absolute inset-0 bg-black/40 hidden group-hover:flex items-center justify-center rounded-lg">
                                    <span class="text-white text-sm font-bold">Change Image</span>
                                </div>
                            </div>
                            <div v-else class="py-8">
                                <ImageIcon class="w-10 h-10 text-gray-300 mx-auto mb-2" />
                                <p class="text-sm text-gray-500">Click to upload image</p>
                                <p class="text-xs text-gray-400 mt-1">Recommended: 16:9 or 2:1 aspect ratio</p>
                            </div>
                        </div>
                    </div>

                    <!-- Title & Desc -->
                    <div class="grid grid-cols-1 gap-4">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Title (Optional)</label>
                            <input v-model="form.title" type="text" class="w-full border border-gray-300 rounded-lg px-3 py-2 bg-gray-50 focus:bg-white focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Description (Optional)</label>
                            <input v-model="form.description" type="text" class="w-full border border-gray-300 rounded-lg px-3 py-2 bg-gray-50 focus:bg-white focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all">
                        </div>
                    </div>

                    <!-- Action Link -->
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                             <label class="block text-sm font-medium text-gray-700 mb-1">Action Label</label>
                             <input v-model="form.action_label" placeholder="e.g. Claim" type="text" class="w-full border border-gray-300 rounded-lg px-3 py-2 bg-gray-50 focus:bg-white focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all">
                        </div>
                         <div>
                             <label class="block text-sm font-medium text-gray-700 mb-1">Action Link</label>
                             <input v-model="form.action_link" placeholder="e.g. /app/promo" type="text" class="w-full border border-gray-300 rounded-lg px-3 py-2 bg-gray-50 focus:bg-white focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all">
                        </div>
                    </div>

                    <!-- Order & Status -->
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Order Priority</label>
                            <input v-model="form.order" type="number" class="w-full border border-gray-300 rounded-lg px-3 py-2 bg-gray-50 focus:bg-white focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all">
                        </div>
                         <div class="flex items-center pt-6">
                            <label class="flex items-center gap-2 cursor-pointer">
                                <input v-model="form.is_active" type="checkbox" class="w-5 h-5 text-primary rounded border-gray-300 focus:ring-primary">
                                <span class="text-sm font-medium text-gray-700">Active</span>
                            </label>
                        </div>
                    </div>

                    <div class="flex gap-3 pt-4">
                        <button 
                            type="button" 
                            @click="closeModal" 
                            class="flex-1 py-2.5 rounded-lg border border-gray-200 text-gray-600 font-bold hover:bg-gray-50 transition-colors"
                        >
                            Cancel
                        </button>
                        <button 
                            type="submit" 
                            :disabled="uploading"
                            class="flex-1 py-2.5 rounded-lg bg-primary text-white font-bold hover:bg-green-800 transition-colors disabled:opacity-70 flex justify-center items-center gap-2"
                        >
                            <span v-if="uploading" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                            {{ isEditing ? 'Update Banner' : 'Create Banner' }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import MainLayout from '../../../components/layout/MainLayout.vue';
import { PlusIcon, EditIcon, TrashIcon, ImageIcon } from 'lucide-vue-next';
import api from '../../../api/axios';
import { useToast } from 'vue-toastification';
import Swal from 'sweetalert2';

const toast = useToast();
const banners = ref([]);
const showModal = ref(false);
const isEditing = ref(false);
const uploading = ref(false);
const previewImage = ref(null);
const fileData = ref(null);

const form = reactive({
    id: null,
    title: '',
    description: '',
    action_label: 'Claim',
    action_link: '',
    order: 0,
    is_active: true
});

const fetchBanners = async () => {
    try {
        const response = await api.get('/admin/banners');
        const rawData = response.data?.data || response.data || [];
        banners.value = Array.isArray(rawData) ? rawData : [];
    } catch (e) {
        console.error(e);
        toast.error("Failed to load banners");
    }
};

const openModal = (banner = null) => {
    isEditing.value = !!banner;
    showModal.value = true;
    fileData.value = null;
    
    if (banner) {
        form.id = banner.id;
        form.title = banner.title;
        form.description = banner.description;
        form.action_label = banner.action_label;
        form.action_link = banner.action_link;
        form.order = banner.order;
        form.is_active = !!banner.is_active;
        previewImage.value = banner.image_url;
    } else {
        resetForm();
    }
};

const closeModal = () => {
    showModal.value = false;
    resetForm();
};

const resetForm = () => {
    form.id = null;
    form.title = '';
    form.description = '';
    form.action_label = 'Claim';
    form.action_link = '';
    form.order = 0;
    form.is_active = true;
    previewImage.value = null;
    fileData.value = null;
};

const handleFileUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
        fileData.value = file;
        previewImage.value = URL.createObjectURL(file);
    }
};

const saveBanner = async () => {
    if (!isEditing.value && !fileData.value) {
        toast.error("Please upload an image");
        return;
    }

    uploading.value = true;
    try {
        const formData = new FormData();
        if (fileData.value) formData.append('image', fileData.value);
        formData.append('title', form.title || '');
        formData.append('description', form.description || '');
        formData.append('action_label', form.action_label || '');
        formData.append('action_link', form.action_link || '');
        formData.append('order', form.order || 0);
        formData.append('is_active', form.is_active ? 1 : 0);
        if (isEditing.value) formData.append('_method', 'PUT'); // Laravel FormData PUT trick

        const url = isEditing.value ? `/admin/banners/${form.id}` : '/admin/banners';
        
        await api.post(url, formData, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });

        toast.success(isEditing.value ? "Banner updated" : "Banner created");
        closeModal();
        fetchBanners();
    } catch (e) {
        console.error(e);
        toast.error("Failed to save banner");
    } finally {
        uploading.value = false;
    }
};

const confirmDelete = async (banner) => {
    const result = await Swal.fire({
        title: 'Delete Banner?',
        text: "This cannot be undone",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#DC2626',
        confirmButtonText: 'Yes, delete it'
    });

    if (result.isConfirmed) {
        try {
            await api.delete(`/admin/banners/${banner.id}`);
            toast.success("Banner deleted");
            fetchBanners();
        } catch (e) {
            toast.error("Failed to delete banner");
        }
    }
};

onMounted(() => {
    fetchBanners();
});
</script>
