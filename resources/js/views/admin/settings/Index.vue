<template>
    <MainLayout>
        <div class="mb-6">
            <h1 class="text-2xl font-bold text-slate-800">Store Settings</h1>
            <p class="text-gray-500">Manage your store configuration and preferences.</p>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-8 max-w-4xl">
            <!-- Tabs -->
            <div class="flex border-b border-gray-100 mb-6 overflow-x-auto">
                <button 
                    @click="activeTab = 'general'"
                    class="px-6 py-2 pb-3 font-medium text-sm transition-colors border-b-2 whitespace-nowrap"
                    :class="activeTab === 'general' ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-gray-700'"
                >
                    General
                </button>
                <button 
                    @click="activeTab = 'financial'"
                    class="px-6 py-2 pb-3 font-medium text-sm transition-colors border-b-2 whitespace-nowrap"
                    :class="activeTab === 'financial' ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-gray-700'"
                >
                    Financial
                </button>
                <button 
                    @click="activeTab = 'hardware'"
                    class="px-6 py-2 pb-3 font-medium text-sm transition-colors border-b-2 whitespace-nowrap"
                    :class="activeTab === 'hardware' ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-gray-700'"
                >
                    Hardware & Printers
                </button>

            </div>

            <form @submit.prevent="saveSettings" class="space-y-6">
                <!-- General Settings -->
                <div v-show="activeTab === 'general'">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="md:col-span-2">
                            <label class="block text-sm font-medium text-gray-700 mb-2">Store Logo</label>
                            <div class="flex items-center space-x-4">
                                <div class="h-20 w-20 rounded-lg bg-gray-200 border border-gray-300 flex items-center justify-center overflow-hidden relative">
                                    <img v-if="previewLogo" :src="previewLogo" class="h-full w-full object-cover">
                                    <span v-else class="text-gray-400 text-xs">No Logo</span>
                                </div>
                                <div>
                                    <input 
                                        type="file" 
                                        @change="handleLogoUpload" 
                                        accept="image/*"
                                        class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-primary/10 file:text-primary hover:file:bg-primary/20"
                                    />
                                    <p class="text-xs text-gray-500 mt-1">Recommended size: 200x200px. Max: 2MB</p>
                                </div>
                            </div>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Store Name</label>
                            <input v-model="settings.store_name" type="text" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                        </div>
                        <div>
                             <label class="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                             <input v-model="settings.store_phone" type="text" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                        </div>
                        <div class="md:col-span-2">
                            <label class="block text-sm font-medium text-gray-700 mb-1">Address</label>
                            <textarea v-model="settings.store_address" rows="3" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4"></textarea>
                        </div>
                        <div class="md:col-span-2">
                             <label class="block text-sm font-medium text-gray-700 mb-1">Google Maps Link</label>
                             <input v-model="settings.store_maps_link" type="text" placeholder="https://maps.google.com/..." class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                        </div>
                    </div>
                </div>

                <!-- Financial Settings -->
                <div v-show="activeTab === 'financial'">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                         <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Tax Rate (%)</label>
                            <input v-model="settings.tax_rate" type="number" step="0.1" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                        </div>
                         <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Service Charge (%)</label>
                            <input v-model="settings.service_charge" type="number" step="0.1" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                        </div>
                    </div>
                </div>
                
                 <!-- Hardware Settings -->
                <div v-show="activeTab === 'hardware'">
                    <div class="bg-blue-50 p-4 rounded-lg mb-4 text-sm text-blue-800">
                        <strong>Bluetooth Printers (e.g. RPP02N):</strong> Usually don't require IP configuration here. Connect via your device's Bluetooth settings. The POS page will use the browser's system print dialog or a specific Bluetooth bridge. 
                        <br>For <strong>Network Printers (LAN/WiFi)</strong>, enter the IP address below.
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                             <label class="block text-sm font-medium text-gray-700 mb-1">Printer Connection Type</label>
                             <select v-model="settings.printer_connection_type" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                                 <option value="network">Network (WiFi/LAN)</option>
                                 <option value="bluetooth">Bluetooth (RPP02N / Mobile)</option>
                                 <option value="browser">Browser Default</option>
                             </select>
                        </div>
                         <div v-if="settings.printer_connection_type === 'network'">
                            <label class="block text-sm font-medium text-gray-700 mb-1">Receipt Printer IP</label>
                            <input v-model="settings.printer_ip_address" type="text" placeholder="192.168.1.100" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                        </div>
                         <div>
                             <label class="block text-sm font-medium text-gray-700 mb-1">Footer Message</label>
                             <input v-model="settings.receipt_footer" type="text" class="w-full border border-gray-400 rounded-lg bg-gray-50 focus:ring-primary focus:border-primary transition-colors py-3 px-4">
                        </div>
                    </div>
                </div>



                <div class="flex justify-end pt-4 border-t border-gray-100">
                    <button type="submit" :disabled="loading" class="bg-primary hover:bg-green-800 text-white px-6 py-2 rounded-lg font-bold transition-colors disabled:opacity-50 flex items-center">
                        {{ loading ? 'Saving...' : 'Save Settings' }}
                    </button>
                </div>
            </form>
        </div>
    </MainLayout>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue';
import MainLayout from '../../../components/layout/MainLayout.vue';
import api from '../../../api/axios';
import { useToast } from "vue-toastification";

const toast = useToast();

const loading = ref(false);
const activeTab = ref('general');
const previewLogo = ref(null);
const logoFile = ref(null);

const settings = reactive({
    store_name: '',
    store_address: '',
    store_phone: '',
    store_maps_link: '',
    store_logo: '', // Stores URL
    tax_rate: 0,
    service_charge: 0,
    printer_connection_type: 'network', 
    printer_ip_address: '',
    receipt_footer: ''
});



const handleLogoUpload = (event) => {
    const file = event.target.files[0];
    if (file) {
        logoFile.value = file;
        previewLogo.value = URL.createObjectURL(file);
    }
};

const fetchSettings = async () => {
    try {
        const response = await api.get('/settings'); 
        const data = response.data?.data || response.data || {};
        Object.keys(data).forEach(key => {
            if (Object.prototype.hasOwnProperty.call(settings, key)) {
                settings[key] = data[key];
            }
        });

        // Set preview if existing info is there
        if (settings.store_logo) {
            previewLogo.value = settings.store_logo;
        }
    } catch (error) {
        console.error("Failed to load settings", error);
    }
};

const saveSettings = async () => {
    loading.value = true;
    try {
        const formData = new FormData();
        
        // Append all text settings
        Object.keys(settings).forEach(key => {
            // Don't append empty string if it's null, but allow empty string update
            if (settings[key] !== null) {
                formData.append(key, settings[key]);
            }
        });

        // Append file if changed

        if (logoFile.value) {
            formData.append('store_logo', logoFile.value);
        }

        const response = await api.post('/admin/settings', formData, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });

        // Update local state with returned data (useful if URL changes)
        const savedData = response.data.data;
        if (savedData.store_logo) {
            settings.store_logo = savedData.store_logo;
            previewLogo.value = savedData.store_logo;
            logoFile.value = null;
        }

        toast.success('Settings saved successfully');
    } catch (error) {
        toast.error('Failed to save settings');
        console.error(error);
    } finally {
        loading.value = false;
    }
};

onMounted(() => {
    fetchSettings();
});
</script>
