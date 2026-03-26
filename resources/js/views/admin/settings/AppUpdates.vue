<template>
    <MainLayout :loading="loading">
        <div class="mb-8 flex justify-between items-end">
            <div>
                <h1 class="text-3xl font-bold text-slate-800 tracking-tight">
                    App Updates (OTA)
                </h1>
                <p class="text-gray-500 mt-2">
                    Upload new Android APK versions for the Mobile POS app.
                </p>
            </div>
            <button
                @click="showModal = true"
                class="bg-primary hover:bg-green-800 text-white px-6 py-3 rounded-xl font-bold transition-all shadow-lg flex items-center"
            >
                <UploadIcon class="w-5 h-5 mr-2" />
                Upload New APK
            </button>
        </div>

        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden min-h-[500px]">
            <div class="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50">
                <h3 class="font-bold text-lg text-slate-800">
                    Version History
                </h3>
            </div>
            
            <div class="overflow-x-auto">
                <table class="w-full text-left">
                    <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider">
                        <tr>
                            <th class="px-6 py-4 font-semibold">Version Name</th>
                            <th class="px-6 py-4 font-semibold">Version Code</th>
                            <th class="px-6 py-4 font-semibold">Release Notes</th>
                            <th class="px-6 py-4 font-semibold">Status</th>
                            <th class="px-6 py-4 font-semibold">Uploaded At</th>
                            <th class="px-6 py-4 font-semibold text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 text-sm">
                        <tr v-if="!versions.length && !loading">
                            <td colspan="6" class="px-6 py-8 text-center text-gray-400">
                                No app versions uploaded yet.
                            </td>
                        </tr>
                        <tr v-for="(v, index) in versions" :key="v.id" class="hover:bg-gray-50 transition-colors">
                            <td class="px-6 py-4 font-bold text-slate-800">
                                {{ v.version_name }}
                                <span v-if="index === 0" class="ml-2 bg-green-100 text-green-700 text-xs px-2 py-1 rounded-full">LATEST</span>
                            </td>
                            <td class="px-6 py-4 font-mono text-gray-600">
                                {{ v.version_code }}
                            </td>
                            <td class="px-6 py-4 text-gray-600 max-w-xs truncate">
                                {{ v.release_notes || '-' }}
                            </td>
                            <td class="px-6 py-4">
                                <span v-if="v.is_mandatory" class="text-red-600 bg-red-50 px-2 py-1 rounded text-xs font-bold">Mandatory</span>
                                <span v-else class="text-gray-500 text-xs">Optional</span>
                            </td>
                            <td class="px-6 py-4 text-gray-500 text-xs">
                                {{ new Date(v.created_at).toLocaleString() }}
                            </td>
                            <td class="px-6 py-4 text-right space-x-2">
                                <button @click="editVersion(v)" class="p-2 text-primary hover:bg-primary/10 rounded-lg transition-colors" title="Edit Metadata">
                                    <PencilIcon class="w-4 h-4" />
                                </button>
                                <button @click="deleteVersion(v)" class="p-2 text-red-500 hover:bg-red-50 rounded-lg transition-colors" title="Delete Version">
                                    <Trash2Icon class="w-4 h-4" />
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Upload/Edit Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div class="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity" @click="closeModal"></div>
            <div class="bg-white rounded-3xl shadow-2xl w-full max-w-lg relative z-10 p-8 transform transition-all animate-in zoom-in-95 duration-200">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-bold text-slate-800">{{ isEditing ? 'Edit Version' : 'Upload New App Version' }}</h2>
                    <button @click="closeModal" class="text-gray-400 hover:text-gray-600 transition-colors bg-gray-100 p-2 rounded-full">
                        <XIcon class="w-6 h-6" />
                    </button>
                </div>
                <form @submit.prevent="saveVersion" class="space-y-5">
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="block text-sm font-bold text-slate-700 mb-2">Version Name *</label>
                            <input v-model="form.version_name" type="text" placeholder="e.g. 1.0.1" required
                                class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium" />
                        </div>
                        <div>
                            <label class="block text-sm font-bold text-slate-700 mb-2">Version Code *</label>
                            <input v-model="form.version_code" type="number" placeholder="e.g. 2" required
                                class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium" />
                        </div>
                    </div>

                    <div>
                        <label class="block text-sm font-bold text-slate-700 mb-2">Release Notes</label>
                        <textarea v-model="form.release_notes" rows="3" placeholder="What's new in this version?"
                            class="w-full border border-gray-300 rounded-2xl bg-gray-50 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all py-3.5 px-5 text-slate-800 font-medium"></textarea>
                    </div>

                    <div class="flex items-center">
                        <input type="checkbox" v-model="form.is_mandatory" id="is_mandatory"
                            class="rounded border-gray-300 text-primary focus:ring-primary" />
                        <label for="is_mandatory" class="ml-2 block text-sm text-gray-700">
                            Mandatory Update (Forces users to update)
                        </label>
                    </div>

                    <div v-if="!isEditing">
                        <label class="block text-sm font-bold text-slate-700 mb-2">APK File *</label>
                        <div 
                            @click="triggerFileInput"
                            @dragenter.prevent="isDragging = true"
                            @dragover.prevent="isDragging = true" 
                            @dragleave.prevent="isDragging = false" 
                            @drop.prevent="handleDrop"
                            :class="[
                                'relative w-full border-2 border-dashed rounded-2xl p-8 flex flex-col items-center justify-center transition-all cursor-pointer',
                                isDragging ? 'border-primary bg-primary/5' : 'border-gray-300 bg-gray-50 hover:border-primary/50'
                            ]"
                        >
                            <input 
                                type="file" 
                                accept=".apk" 
                                @change="handleFileChange" 
                                ref="fileInput"
                                class="hidden"
                            />
                            <div class="pointer-events-none p-3 bg-white shadow-sm rounded-full mb-3 text-primary">
                                <UploadIcon class="w-8 h-8" />
                            </div>
                            <p class="pointer-events-none text-sm font-semibold text-slate-800 mb-1">
                                {{ selectedFile ? selectedFile.name : 'Click to upload or drag and drop' }}
                            </p>
                            <p class="pointer-events-none text-xs text-gray-500">
                                {{ selectedFile ? (selectedFile.size / (1024 * 1024)).toFixed(2) + ' MB' : 'APK files only' }}
                            </p>
                        </div>
                    </div>

                    <div class="flex justify-end space-x-4 mt-8">
                        <button type="button" @click="closeModal" :disabled="saving"
                            class="px-6 py-3 text-slate-600 font-bold hover:bg-gray-100 rounded-2xl transition-colors">
                            Cancel
                        </button>
                        <button type="submit" :disabled="saving || (!isEditing && !selectedFile)"
                            class="px-8 py-3 bg-primary text-white font-bold rounded-2xl hover:bg-green-800 transition-all shadow-md shadow-primary/20 disabled:opacity-50 flex items-center">
                            <LoaderIcon v-if="saving" class="w-5 h-5 mr-2 animate-spin" />
                            {{ saving ? 'Saving...' : (isEditing ? 'Update Info' : 'Save & Publish') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>

    </MainLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import MainLayout from '../../../components/layout/MainLayout.vue';
import { UploadIcon, LoaderIcon, XIcon, PencilIcon, Trash2Icon } from 'lucide-vue-next';
import api from '../../../api/axios';

const loading = ref(true);
const saving = ref(false);
const showModal = ref(false);
const isEditing = ref(false);
const selectedVersionId = ref(null);
const versions = ref([]);

const selectedFile = ref(null);
const fileInput = ref(null);
const isDragging = ref(false);

const form = ref({
    version_name: '',
    version_code: '',
    release_notes: '',
    is_mandatory: false
});

const fetchVersions = async () => {
    loading.value = true;
    try {
        const response = await api.get('/admin/app-versions');
        versions.value = response.data.data;
    } catch (error) {
        console.error('Failed to fetch app versions', error);
    } finally {
        loading.value = false;
    }
};

const handleFileChange = (event) => {
    if (event.target.files.length > 0) {
        selectedFile.value = event.target.files[0];
    }
};

const triggerFileInput = () => {
    if (fileInput.value) {
        fileInput.value.click();
    }
};

const handleDrop = (event) => {
    isDragging.value = false;
    const droppedFiles = event.dataTransfer.files;
    if (droppedFiles.length > 0) {
        const file = droppedFiles[0];
        // Validate it's an APK file
        if (file.name.toLowerCase().endsWith('.apk')) {
            selectedFile.value = file;
            // Also update the file input so 'required' validation is happy if we had any
            if (fileInput.value) {
                fileInput.value.files = event.dataTransfer.files;
            }
        } else {
            alert('Please drop a valid .apk file');
        }
    }
};

const closeModal = () => {
    showModal.value = false;
    isEditing.value = false;
    selectedVersionId.value = null;
    selectedFile.value = null;
    form.value = {
        version_name: '',
        version_code: '',
        release_notes: '',
        is_mandatory: false
    };
};

const editVersion = (v) => {
    isEditing.value = true;
    selectedVersionId.value = v.id;
    form.value = {
        version_name: v.version_name,
        version_code: v.version_code,
        release_notes: v.release_notes || '',
        is_mandatory: !!v.is_mandatory
    };
    showModal.value = true;
};

const deleteVersion = async (v) => {
    if (!confirm(`Are you sure you want to delete version ${v.version_name}? This will remove the APK file from the server.`)) {
        return;
    }

    try {
        await api.delete(`/admin/app-versions/${v.id}`);
        alert('App version deleted successfully!');
        fetchVersions();
    } catch (error) {
        alert(error.response?.data?.message || 'Failed to delete version');
    }
};

const saveVersion = async () => {
    saving.value = true;
    
    try {
        if (isEditing.value) {
            await api.put(`/admin/app-versions/${selectedVersionId.value}`, {
                version_name: form.value.version_name,
                version_code: form.value.version_code,
                release_notes: form.value.release_notes,
                is_mandatory: form.value.is_mandatory ? 1 : 0
            });
            alert('App version updated successfully!');
        } else {
            if (!selectedFile.value) return;
            
            const formData = new FormData();
            formData.append('version_name', form.value.version_name);
            formData.append('version_code', form.value.version_code);
            formData.append('release_notes', form.value.release_notes);
            formData.append('is_mandatory', form.value.is_mandatory ? 1 : 0);
            formData.append('apk_file', selectedFile.value);

            await api.post('/admin/app-versions', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            });
            alert('App version uploaded successfully!');
        }
        
        closeModal();
        fetchVersions();
    } catch (error) {
        alert(error.response?.data?.message || 'Failed to save version');
    } finally {
        saving.value = false;
    }
};

onMounted(() => {
    fetchVersions();
});
</script>
